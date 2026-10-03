from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import os
import shutil
import stat
import sys
import time
import uuid
import zipfile
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

PROD_ROOT = Path(__file__).resolve().parent
RUNTIME_ROOT = Path(os.environ.get("REMOTE_GROWTH_ROOT", str(PROD_ROOT.parent)))
PLAN_ROOT = PROD_ROOT / "plans"
RECEIPT_ROOT = PROD_ROOT / "receipts"
BACKUP_ROOT = Path(os.environ.get("REMOTE_GROWTH_BACKUP_ROOT", str(RUNTIME_ROOT / "backups")))
QUARANTINE_ROOT = Path(os.environ.get("REMOTE_GROWTH_QUARANTINE_ROOT", str(RUNTIME_ROOT / "quarantine")))
AUTH_FILE = Path(os.environ.get("REMOTE_GROWTH_AUTH_FILE", str(RUNTIME_ROOT / "auth.key")))

def _json_paths(name: str, defaults: list[Path]) -> list[Path]:
    raw = os.environ.get(name, "")
    if not raw:
        return defaults
    try:
        values = json.loads(raw)
        if isinstance(values, list) and all(isinstance(v, str) for v in values):
            return [Path(v).expanduser() for v in values if v.strip()]
    except Exception:
        pass
    return defaults

ALLOWED_ROOTS = _json_paths("REMOTE_GROWTH_ALLOWED_ROOTS_JSON", [Path.home()])
PROTECTED_MUTATION_ROOTS = _json_paths(
    "REMOTE_GROWTH_PROTECTED_ROOTS_JSON",
    [
        Path(os.environ.get("WINDIR", r"C:\Windows")),
        Path(os.environ.get("ProgramFiles", r"C:\Program Files")),
        Path(os.environ.get("ProgramData", r"C:\ProgramData")),
        RUNTIME_ROOT,
    ],
)
PROTECTED_EXACT = {AUTH_FILE}
MAX_PLAN_OPS = 500
MAX_ANALYZE_ENTRIES = 250000
MAX_DUPLICATE_ENTRIES = 250000
MAX_MANIFEST_ENTRIES = 100000

class EngineError(Exception):
    pass

def now_iso() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")

def emit(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, ensure_ascii=True, default=str))

def canonical(path: str | Path) -> Path:
    return Path(path).expanduser().resolve(strict=False)

def is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False

def assert_allowed(path: Path, mutation: bool = False) -> None:
    p = canonical(path)
    if not any(is_relative_to(p, canonical(root)) or p == canonical(root) for root in ALLOWED_ROOTS):
        raise EngineError(f"Path outside allowed roots: {p}")
    if mutation:
        for exact in PROTECTED_EXACT:
            if p == canonical(exact):
                raise EngineError(f"Protected path cannot be mutated: {p}")
        for root in PROTECTED_MUTATION_ROOTS:
            rr = canonical(root)
            if p == rr or is_relative_to(p, rr):
                raise EngineError(f"Protected runtime/system path cannot be mutated: {p}")

def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def quick_stat(path: Path) -> dict[str, Any]:
    st = path.stat()
    return {
        "exists": True,
        "is_file": path.is_file(),
        "is_dir": path.is_dir(),
        "size": st.st_size if path.is_file() else None,
        "mtime_ns": st.st_mtime_ns,
    }

def tree_stats(path: Path, hash_files: bool = False, max_entries: int = MAX_MANIFEST_ENTRIES) -> dict[str, Any]:
    if path.is_file():
        return {
            "kind": "file",
            "files": 1,
            "dirs": 0,
            "bytes": path.stat().st_size,
            "sha256": sha256_file(path) if hash_files else None,
        }
    files = 0
    dirs = 0
    total = 0
    manifest = hashlib.sha256()
    for root, dirnames, filenames in os.walk(path):
        rootp = Path(root)
        dirs += len(dirnames)
        for name in filenames:
            files += 1
            if files > max_entries:
                raise EngineError(f"Tree exceeds max_entries={max_entries}: {path}")
            fp = rootp / name
            try:
                st = fp.stat()
            except OSError:
                continue
            total += st.st_size
            rel = fp.relative_to(path).as_posix()
            manifest.update(rel.encode("utf-8", errors="surrogatepass"))
            manifest.update(str(st.st_size).encode())
            if hash_files:
                manifest.update(sha256_file(fp).encode())
    return {
        "kind": "directory",
        "files": files,
        "dirs": dirs,
        "bytes": total,
        "manifest_sha256": manifest.hexdigest(),
    }

def verify_equivalent(a: Path, b: Path) -> dict[str, Any]:
    if not a.exists() or not b.exists():
        return {"equivalent": False, "reason": "missing_path"}
    if a.is_file() != b.is_file() or a.is_dir() != b.is_dir():
        return {"equivalent": False, "reason": "type_mismatch"}
    if a.is_file():
        sa, sb = a.stat().st_size, b.stat().st_size
        if sa != sb:
            return {"equivalent": False, "reason": "size_mismatch", "size_a": sa, "size_b": sb}
        ha, hb = sha256_file(a), sha256_file(b)
        return {"equivalent": ha == hb, "sha256_a": ha, "sha256_b": hb, "bytes": sa}
    ta = tree_stats(a, hash_files=True)
    tb = tree_stats(b, hash_files=True)
    return {"equivalent": ta == tb, "tree_a": ta, "tree_b": tb}

def quarantine_root_for(path: Path) -> Path:
    drive_label = path.drive.replace(":", "").upper() if path.drive else "ROOT"
    return QUARANTINE_ROOT / (drive_label or "ROOT")

def unique_quarantine_path(source: Path, receipt_id: str) -> Path:
    root = quarantine_root_for(source) / receipt_id
    root.mkdir(parents=True, exist_ok=True)
    drive_label = source.drive.replace(":", "")
    rel_parts = source.parts[1:] if source.drive else source.parts
    dest = root / drive_label
    for part in rel_parts:
        dest = dest / part
    if dest.exists():
        dest = dest.with_name(dest.name + "-" + uuid.uuid4().hex[:8])
    return dest

def canonical_json_hash(obj: Any) -> str:
    raw = json.dumps(obj, ensure_ascii=True, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()

def health() -> dict[str, Any]:
    for p in (PLAN_ROOT, RECEIPT_ROOT, BACKUP_ROOT, D_QUARANTINE):
        p.mkdir(parents=True, exist_ok=True)
    return {
        "ok": True,
        "command": "health",
        "allowed_roots": [str(canonical(x)) for x in ALLOWED_ROOTS],
        "protected_mutation_roots": [str(canonical(x)) for x in PROTECTED_MUTATION_ROOTS],
        "plan_root": str(PLAN_ROOT),
        "receipt_root": str(RECEIPT_ROOT),
        "backup_root": str(BACKUP_ROOT),
        "quarantine": {"C": str(C_QUARANTINE), "D": str(D_QUARANTINE)},
        "batch_semantics": "plan -> validate preconditions -> execute -> verify -> receipt",
        "delete_semantics": "quarantine, not permanent delete",
        "rollback_supported": ["copy", "move", "rename", "delete", "mkdir"],
    }

def storage_analyze(raw: str, depth: int, top_n: int) -> dict[str, Any]:
    root = canonical(raw)
    assert_allowed(root)
    if not root.exists() or not root.is_dir():
        raise EngineError(f"Directory not found: {root}")
    depth = max(1, min(depth, 4))
    top_n = max(1, min(top_n, 200))
    base_depth = len(root.parts)
    stats: dict[str, list[int]] = defaultdict(lambda: [0, 0, 0])
    scanned = 0
    errors = 0
    started = time.perf_counter()

    for current, dirnames, filenames in os.walk(root):
        current_p = Path(current)
        rel_depth = len(current_p.parts) - base_depth
        if rel_depth >= depth:
            dirnames[:] = []
        key = str(current_p)
        stats[key][1] += len(dirnames)
        for name in filenames:
            scanned += 1
            if scanned > MAX_ANALYZE_ENTRIES:
                raise EngineError(f"storage_analyze exceeded entry limit {MAX_ANALYZE_ENTRIES}")
            fp = current_p / name
            try:
                size = fp.stat().st_size
            except OSError:
                errors += 1
                continue
            p = current_p
            while p == root or is_relative_to(p, root):
                if len(p.parts) - base_depth <= depth:
                    stats[str(p)][0] += size
                    stats[str(p)][2] += 1
                if p == root:
                    break
                p = p.parent

    rows = [
        {"path": p, "bytes": vals[0], "files": vals[2], "dirs_seen": vals[1]}
        for p, vals in stats.items()
    ]
    rows.sort(key=lambda x: x["bytes"], reverse=True)
    return {
        "ok": True,
        "command": "storage_analyze",
        "root": str(root),
        "depth": depth,
        "scanned_files": scanned,
        "errors": errors,
        "elapsed_seconds": round(time.perf_counter() - started, 3),
        "top": rows[:top_n],
    }

def duplicate_find(raw: str, min_size: int, limit_groups: int) -> dict[str, Any]:
    root = canonical(raw)
    assert_allowed(root)
    if not root.exists() or not root.is_dir():
        raise EngineError(f"Directory not found: {root}")
    min_size = max(1, min_size)
    limit_groups = max(1, min(limit_groups, 200))
    by_size: dict[int, list[Path]] = defaultdict(list)
    scanned = 0
    errors = 0
    for current, _, files in os.walk(root):
        for name in files:
            scanned += 1
            if scanned > MAX_DUPLICATE_ENTRIES:
                raise EngineError(f"duplicate_find exceeded entry limit {MAX_DUPLICATE_ENTRIES}")
            fp = Path(current) / name
            try:
                size = fp.stat().st_size
            except OSError:
                errors += 1
                continue
            if size >= min_size:
                by_size[size].append(fp)
    groups = []
    reclaimable = 0
    for size, paths in sorted(by_size.items(), reverse=True):
        if len(paths) < 2:
            continue
        by_hash: dict[str, list[str]] = defaultdict(list)
        for fp in paths:
            try:
                by_hash[sha256_file(fp)].append(str(fp))
            except OSError:
                errors += 1
        for digest, same in by_hash.items():
            if len(same) > 1:
                groups.append({"sha256": digest, "size": size, "count": len(same), "paths": same})
                reclaimable += size * (len(same) - 1)
                if len(groups) >= limit_groups:
                    break
        if len(groups) >= limit_groups:
            break
    return {
        "ok": True,
        "command": "duplicate_find",
        "root": str(root),
        "scanned_files": scanned,
        "errors": errors,
        "groups": groups,
        "group_count": len(groups),
        "reclaimable_bytes_if_keep_one": reclaimable,
    }

def hash_manifest(raw: str, include_sha256: bool, max_entries: int) -> dict[str, Any]:
    path = canonical(raw)
    assert_allowed(path)
    if not path.exists():
        raise EngineError(f"Path not found: {path}")
    max_entries = max(1, min(max_entries, MAX_MANIFEST_ENTRIES))
    if path.is_file():
        st = path.stat()
        return {
            "ok": True,
            "command": "hash_manifest",
            "root": str(path),
            "count": 1,
            "entries": [{
                "path": str(path),
                "relative": path.name,
                "bytes": st.st_size,
                "mtime_ns": st.st_mtime_ns,
                "sha256": sha256_file(path) if include_sha256 else None,
            }],
        }
    entries = []
    for current, _, files in os.walk(path):
        for name in files:
            if len(entries) >= max_entries:
                raise EngineError(f"Manifest exceeds max_entries={max_entries}")
            fp = Path(current) / name
            try:
                st = fp.stat()
            except OSError:
                continue
            entries.append({
                "path": str(fp),
                "relative": fp.relative_to(path).as_posix(),
                "bytes": st.st_size,
                "mtime_ns": st.st_mtime_ns,
                "sha256": sha256_file(fp) if include_sha256 else None,
            })
    return {
        "ok": True,
        "command": "hash_manifest",
        "root": str(path),
        "count": len(entries),
        "total_bytes": sum(x["bytes"] for x in entries),
        "entries": entries,
    }

def archive_create(paths: list[str], output_raw: str) -> dict[str, Any]:
    if not paths:
        raise EngineError("At least one source path is required")
    output = canonical(output_raw)
    assert_allowed(output, mutation=True)
    if output.suffix.lower() != ".zip":
        raise EngineError("Output archive must end with .zip")
    if output.exists():
        raise EngineError(f"Archive destination already exists: {output}")
    sources = []
    for raw in paths:
        p = canonical(raw)
        assert_allowed(p)
        if not p.exists():
            raise EngineError(f"Source not found: {p}")
        sources.append(p)
    for src in sources:
        if src.is_dir() and (output == src or is_relative_to(output, src)):
            raise EngineError(f"Archive output cannot be inside source directory: {output}")
    ensure_parent(output)
    temp = output.with_name(output.name + ".partial")
    if temp.exists():
        temp.unlink()
    members = 0
    total_bytes = 0
    try:
        with zipfile.ZipFile(temp, "w", compression=zipfile.ZIP_DEFLATED, allowZip64=True) as zf:
            used = set()
            for src in sources:
                base_name = src.name
                if base_name in used:
                    base_name = f"{base_name}-{uuid.uuid4().hex[:6]}"
                used.add(base_name)
                if src.is_file():
                    zf.write(src, arcname=base_name)
                    members += 1
                    total_bytes += src.stat().st_size
                else:
                    for current, _, files in os.walk(src):
                        for name in files:
                            fp = Path(current) / name
                            if fp.is_symlink():
                                continue
                            rel = fp.relative_to(src)
                            zf.write(fp, arcname=(Path(base_name) / rel).as_posix())
                            members += 1
                            total_bytes += fp.stat().st_size
        with zipfile.ZipFile(temp, "r") as zf:
            bad = zf.testzip()
            if bad:
                raise EngineError(f"Archive verification failed at member: {bad}")
        os.replace(temp, output)
        return {
            "ok": True,
            "command": "archive_create",
            "output": str(output),
            "sha256": sha256_file(output),
            "members": members,
            "source_bytes": total_bytes,
            "archive_bytes": output.stat().st_size,
        }
    except Exception:
        temp.unlink(missing_ok=True)
        raise

def archive_extract(archive_raw: str, destination_raw: str) -> dict[str, Any]:
    archive = canonical(archive_raw)
    destination = canonical(destination_raw)
    assert_allowed(archive)
    assert_allowed(destination, mutation=True)
    if not archive.exists() or not archive.is_file():
        raise EngineError(f"Archive not found: {archive}")
    if destination.exists():
        raise EngineError(f"Extraction destination already exists: {destination}")
    ensure_parent(destination)
    temp = destination.with_name(destination.name + ".extracting-" + uuid.uuid4().hex[:8])
    temp.mkdir(parents=True)
    extracted = 0
    try:
        with zipfile.ZipFile(archive, "r") as zf:
            for info in zf.infolist():
                member = Path(info.filename)
                if member.is_absolute() or ".." in member.parts:
                    raise EngineError(f"Unsafe archive member: {info.filename}")
                target = canonical(temp / member)
                if not is_relative_to(target, canonical(temp)) and target != canonical(temp):
                    raise EngineError(f"Archive member escapes destination: {info.filename}")
            zf.extractall(temp)
            extracted = len(zf.infolist())
        os.replace(temp, destination)
        return {
            "ok": True,
            "command": "archive_extract",
            "archive": str(archive),
            "archive_sha256": sha256_file(archive),
            "destination": str(destination),
            "members": extracted,
            "tree": tree_stats(destination, hash_files=False),
        }
    except Exception:
        shutil.rmtree(temp, ignore_errors=True)
        raise

def op_precondition(op: dict[str, Any]) -> dict[str, Any]:
    kind = op["op"]
    source = canonical(op["source"]) if op.get("source") else None
    destination = canonical(op["destination"]) if op.get("destination") else None
    if source is not None:
        assert_allowed(source, mutation=kind in {"move", "rename", "delete"})
    if destination is not None:
        assert_allowed(destination, mutation=True)
    if kind in {"copy", "move", "rename", "delete"}:
        if source is None or not source.exists():
            raise EngineError(f"Source not found for {kind}: {source}")
    if kind in {"copy", "move", "rename"}:
        if destination is None:
            raise EngineError(f"Destination required for {kind}")
        if destination.exists():
            raise EngineError(f"Destination already exists: {destination}")
        if source and source.is_dir() and (destination == source or is_relative_to(destination, source)):
            raise EngineError("Destination cannot be inside source directory")
    if kind == "mkdir":
        if destination is None:
            raise EngineError("Destination required for mkdir")
        if destination.exists():
            raise EngineError(f"Directory destination already exists: {destination}")
    if kind not in {"copy", "move", "rename", "delete", "mkdir"}:
        raise EngineError(f"Unsupported operation: {kind}")
    return {
        "op": kind,
        "source": str(source) if source else None,
        "destination": str(destination) if destination else None,
        "source_stat": quick_stat(source) if source else None,
        "destination_exists": destination.exists() if destination else None,
    }

def batch_plan(operations: list[dict[str, Any]], label: str) -> dict[str, Any]:
    if not operations:
        raise EngineError("operations must not be empty")
    if len(operations) > MAX_PLAN_OPS:
        raise EngineError(f"Too many operations; max={MAX_PLAN_OPS}")
    normalized = []
    for idx, op in enumerate(operations):
        if not isinstance(op, dict) or "op" not in op:
            raise EngineError(f"Operation {idx} must be an object with op")
        normalized.append(op_precondition(op))
    plan_id = datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:8]
    plan = {
        "version": 1,
        "plan_id": plan_id,
        "label": label[:120],
        "created_at": now_iso(),
        "operations": normalized,
    }
    plan["plan_hash"] = canonical_json_hash(plan)
    PLAN_ROOT.mkdir(parents=True, exist_ok=True)
    path = PLAN_ROOT / f"{plan_id}.json"
    path.write_text(json.dumps(plan, indent=2, ensure_ascii=True), encoding="utf-8")
    return {
        "ok": True,
        "command": "batch_plan",
        "plan_id": plan_id,
        "plan_hash": plan["plan_hash"],
        "label": plan["label"],
        "operation_count": len(normalized),
        "operations": normalized,
        "plan_file": str(path),
    }

def load_plan(plan_id: str) -> dict[str, Any]:
    path = PLAN_ROOT / f"{plan_id}.json"
    if not path.exists():
        raise EngineError(f"Plan not found: {plan_id}")
    plan = json.loads(path.read_text(encoding="utf-8"))
    expected = plan.get("plan_hash")
    check = dict(plan)
    check.pop("plan_hash", None)
    actual = canonical_json_hash(check)
    if expected != actual:
        raise EngineError("Plan hash mismatch; plan file was modified")
    return plan

def stat_matches(path: Path, expected: dict[str, Any] | None) -> bool:
    if expected is None:
        return True
    if not path.exists():
        return False
    st = quick_stat(path)
    return (
        st["is_file"] == expected["is_file"]
        and st["is_dir"] == expected["is_dir"]
        and st["size"] == expected["size"]
        and st["mtime_ns"] == expected["mtime_ns"]
    )

def copy_item(source: Path, destination: Path) -> None:
    ensure_parent(destination)
    if source.is_dir():
        shutil.copytree(source, destination, copy_function=shutil.copy2)
    else:
        shutil.copy2(source, destination)

def remove_item(path: Path) -> None:
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    else:
        path.unlink()

def batch_execute(plan_id: str) -> dict[str, Any]:
    plan = load_plan(plan_id)
    receipt_id = plan_id + "-exec-" + uuid.uuid4().hex[:6]
    actions = []
    started = time.perf_counter()
    try:
        for idx, op in enumerate(plan["operations"]):
            kind = op["op"]
            source = canonical(op["source"]) if op.get("source") else None
            destination = canonical(op["destination"]) if op.get("destination") else None
            if source is not None and not stat_matches(source, op.get("source_stat")):
                raise EngineError(f"Precondition changed for source before operation {idx}: {source}")
            if destination is not None and destination.exists():
                raise EngineError(f"Destination became occupied before operation {idx}: {destination}")

            action: dict[str, Any] = {"index": idx, "op": kind, "source": str(source) if source else None, "destination": str(destination) if destination else None}
            if kind == "copy":
                copy_item(source, destination)
                verify = verify_equivalent(source, destination)
                if not verify["equivalent"]:
                    remove_item(destination)
                    raise EngineError(f"Copy verification failed at operation {idx}")
                action["verify"] = verify
                action["rollback"] = {"kind": "remove_copy", "path": str(destination), "expected": tree_stats(destination, hash_files=True)}
            elif kind in {"move", "rename"}:
                ensure_parent(destination)
                shutil.move(str(source), str(destination))
                if not destination.exists() or source.exists():
                    raise EngineError(f"Move verification failed at operation {idx}")
                expected_after = tree_stats(destination, hash_files=True)
                action["verify"] = {"source_absent": True, "destination_present": True, "expected_after": expected_after}
                action["rollback"] = {"kind": "move_back", "from": str(destination), "to": str(source), "expected": expected_after}
            elif kind == "delete":
                quarantine = unique_quarantine_path(source, receipt_id)
                ensure_parent(quarantine)
                shutil.move(str(source), str(quarantine))
                if source.exists() or not quarantine.exists():
                    raise EngineError(f"Quarantine verification failed at operation {idx}")
                expected_quarantine = tree_stats(quarantine, hash_files=True)
                action["quarantine"] = str(quarantine)
                action["rollback"] = {"kind": "restore_quarantine", "from": str(quarantine), "to": str(source), "expected": expected_quarantine}
            elif kind == "mkdir":
                destination.mkdir(parents=False, exist_ok=False)
                action["verify"] = {"created": destination.exists() and destination.is_dir()}
                action["rollback"] = {"kind": "remove_empty_dir", "path": str(destination)}
            actions.append(action)
    except Exception as exc:
        receipt = {
            "version": 1,
            "receipt_id": receipt_id,
            "plan_id": plan_id,
            "status": "FAILED_PARTIAL",
            "created_at": now_iso(),
            "error": f"{type(exc).__name__}: {exc}",
            "actions": actions,
        }
        RECEIPT_ROOT.mkdir(parents=True, exist_ok=True)
        receipt_path = RECEIPT_ROOT / f"{receipt_id}.json"
        receipt_path.write_text(json.dumps(receipt, indent=2, ensure_ascii=True), encoding="utf-8")
        raise EngineError(f"Batch execution failed after {len(actions)} operations. Receipt: {receipt_id}. Error: {exc}") from exc

    receipt = {
        "version": 1,
        "receipt_id": receipt_id,
        "plan_id": plan_id,
        "status": "COMPLETE",
        "created_at": now_iso(),
        "elapsed_seconds": round(time.perf_counter() - started, 3),
        "actions": actions,
    }
    receipt["receipt_hash"] = canonical_json_hash(receipt)
    RECEIPT_ROOT.mkdir(parents=True, exist_ok=True)
    receipt_path = RECEIPT_ROOT / f"{receipt_id}.json"
    receipt_path.write_text(json.dumps(receipt, indent=2, ensure_ascii=True), encoding="utf-8")
    return {
        "ok": True,
        "command": "batch_execute",
        "plan_id": plan_id,
        "receipt_id": receipt_id,
        "status": "COMPLETE",
        "operation_count": len(actions),
        "elapsed_seconds": receipt["elapsed_seconds"],
        "receipt_file": str(receipt_path),
        "actions": actions,
    }

def rollback(receipt_id: str) -> dict[str, Any]:
    path = RECEIPT_ROOT / f"{receipt_id}.json"
    if not path.exists():
        raise EngineError(f"Receipt not found: {receipt_id}")
    receipt = json.loads(path.read_text(encoding="utf-8"))
    if receipt.get("rollback_status") == "COMPLETE":
        raise EngineError("Receipt already rolled back")
    rolled = []
    for action in reversed(receipt.get("actions", [])):
        rb = action.get("rollback")
        if not rb:
            continue
        kind = rb["kind"]
        if kind == "remove_copy":
            p = canonical(rb["path"])
            if p.exists():
                expected = rb.get("expected")
                current = tree_stats(p, hash_files=True)
                if expected != current:
                    raise EngineError(f"Refusing rollback: copied destination changed since execution: {p}")
                remove_item(p)
        elif kind == "move_back":
            src = canonical(rb["from"])
            dst = canonical(rb["to"])
            if not src.exists():
                raise EngineError(f"Refusing rollback: moved destination missing: {src}")
            expected = rb.get("expected")
            if expected is not None and tree_stats(src, hash_files=True) != expected:
                raise EngineError(f"Refusing rollback: moved destination changed since execution: {src}")
            if dst.exists():
                raise EngineError(f"Refusing rollback: original location occupied: {dst}")
            ensure_parent(dst)
            shutil.move(str(src), str(dst))
        elif kind == "restore_quarantine":
            src = canonical(rb["from"])
            dst = canonical(rb["to"])
            if not src.exists():
                raise EngineError(f"Refusing rollback: quarantine item missing: {src}")
            expected = rb.get("expected")
            if expected is not None and tree_stats(src, hash_files=True) != expected:
                raise EngineError(f"Refusing rollback: quarantine item changed since execution: {src}")
            if dst.exists():
                raise EngineError(f"Refusing rollback: original location occupied: {dst}")
            ensure_parent(dst)
            shutil.move(str(src), str(dst))
        elif kind == "remove_empty_dir":
            p = canonical(rb["path"])
            if p.exists():
                try:
                    p.rmdir()
                except OSError as exc:
                    raise EngineError(f"Refusing rollback: created directory is not empty: {p}") from exc
        rolled.append({"action_index": action.get("index"), "rollback_kind": kind})
    receipt["rollback_status"] = "COMPLETE"
    receipt["rolled_back_at"] = now_iso()
    receipt["rollback_actions"] = rolled
    path.write_text(json.dumps(receipt, indent=2, ensure_ascii=True), encoding="utf-8")
    return {
        "ok": True,
        "command": "rollback",
        "receipt_id": receipt_id,
        "rollback_status": "COMPLETE",
        "rollback_action_count": len(rolled),
        "actions": rolled,
    }

def workspace_backup(raw: str, label: str) -> dict[str, Any]:
    source = canonical(raw)
    assert_allowed(source)
    if not source.exists():
        raise EngineError(f"Workspace not found: {source}")
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    safe_label = "".join(c if c.isalnum() or c in "._-" else "-" for c in label.strip())[:50] or "backup"
    backup_dir = BACKUP_ROOT / timestamp
    backup_dir.mkdir(parents=True, exist_ok=True)
    output = backup_dir / f"{source.name}-{safe_label}.zip"
    result = archive_create([str(source)], str(output))
    manifest = hash_manifest(str(source), include_sha256=True, max_entries=MAX_MANIFEST_ENTRIES)
    manifest_file = backup_dir / f"{source.name}-{safe_label}.manifest.json"
    manifest_file.write_text(json.dumps(manifest, indent=2, ensure_ascii=True), encoding="utf-8")
    return {
        "ok": True,
        "command": "workspace_backup",
        "source": str(source),
        "backup": result,
        "manifest_file": str(manifest_file),
        "manifest_count": manifest["count"],
        "manifest_total_bytes": manifest.get("total_bytes", 0),
    }

def main() -> int:
    parser = argparse.ArgumentParser(prog="fileops-engine")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("health")

    p = sub.add_parser("storage-analyze")
    p.add_argument("path")
    p.add_argument("--depth", type=int, default=2)
    p.add_argument("--top-n", type=int, default=30)

    p = sub.add_parser("duplicates")
    p.add_argument("path")
    p.add_argument("--min-size", type=int, default=1048576)
    p.add_argument("--limit-groups", type=int, default=50)

    p = sub.add_parser("hash-manifest")
    p.add_argument("path")
    p.add_argument("--no-sha256", action="store_true")
    p.add_argument("--max-entries", type=int, default=10000)

    p = sub.add_parser("archive-create")
    p.add_argument("output")
    p.add_argument("paths_json")

    p = sub.add_parser("archive-extract")
    p.add_argument("archive")
    p.add_argument("destination")

    p = sub.add_parser("batch-plan")
    p.add_argument("operations_json")
    p.add_argument("--label", default="manual")

    p = sub.add_parser("batch-execute")
    p.add_argument("plan_id")

    p = sub.add_parser("rollback")
    p.add_argument("receipt_id")

    p = sub.add_parser("workspace-backup")
    p.add_argument("path")
    p.add_argument("--label", default="manual")

    args = parser.parse_args()
    try:
        if args.command == "health":
            result = health()
        elif args.command == "storage-analyze":
            result = storage_analyze(args.path, args.depth, args.top_n)
        elif args.command == "duplicates":
            result = duplicate_find(args.path, args.min_size, args.limit_groups)
        elif args.command == "hash-manifest":
            result = hash_manifest(args.path, not args.no_sha256, args.max_entries)
        elif args.command == "archive-create":
            paths = json.loads(args.paths_json)
            if not isinstance(paths, list):
                raise EngineError("paths_json must decode to a list")
            result = archive_create([str(x) for x in paths], args.output)
        elif args.command == "archive-extract":
            result = archive_extract(args.archive, args.destination)
        elif args.command == "batch-plan":
            operations = json.loads(args.operations_json)
            if not isinstance(operations, list):
                raise EngineError("operations_json must decode to a list")
            result = batch_plan(operations, args.label)
        elif args.command == "batch-execute":
            result = batch_execute(args.plan_id)
        elif args.command == "rollback":
            result = rollback(args.receipt_id)
        elif args.command == "workspace-backup":
            result = workspace_backup(args.path, args.label)
        else:
            raise EngineError("Unknown command")
        emit(result)
        return 0 if result.get("ok", False) else 2
    except Exception as exc:
        emit({"ok": False, "command": args.command, "error": type(exc).__name__, "message": str(exc)})
        return 1

if __name__ == "__main__":
    raise SystemExit(main())