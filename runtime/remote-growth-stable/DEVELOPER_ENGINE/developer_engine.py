from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sqlite3
import subprocess
import tempfile
import time
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit, urlunsplit

RUNTIME_ROOT = Path(os.environ.get("REMOTE_GROWTH_ROOT", str(Path(__file__).resolve().parents[1])))
FAST_INDEX_DB = Path(os.environ.get("REMOTE_GROWTH_FAST_INDEX_DB", str(RUNTIME_ROOT / "FAST_LOCAL_ENGINE" / "data" / "local-index.sqlite3")))
CHECKPOINT_PREFIX = "refs/heads/checkpoint/remote-growth-"
MAX_OUTPUT = 30000
TASKS = {"lint", "typecheck", "test", "build", "verify", "format-check"}

class EngineError(Exception):
    pass

def emit(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, ensure_ascii=True, default=str))

def run(
    argv: list[str],
    cwd: Path | None = None,
    timeout: int = 30,
    env: dict[str, str] | None = None,
    check: bool = False,
) -> dict[str, Any]:
    merged = os.environ.copy()
    merged.update({
        "GIT_TERMINAL_PROMPT": "0",
        "CI": "1",
        "NO_COLOR": "1",
        "FORCE_COLOR": "0",
        "npm_config_color": "false",
        "npm_config_progress": "false",
        "npm_config_update_notifier": "false",
    })
    if env:
        merged.update(env)
    started = time.perf_counter()
    try:
        cp = subprocess.run(
            argv,
            cwd=str(cwd) if cwd else None,
            env=merged,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
        )
    except subprocess.TimeoutExpired as exc:
        return {
            "argv": argv,
            "exit_code": None,
            "timed_out": True,
            "elapsed_seconds": round(time.perf_counter() - started, 3),
            "stdout": (exc.stdout or "")[-MAX_OUTPUT:] if isinstance(exc.stdout, str) else "",
            "stderr": (exc.stderr or "")[-MAX_OUTPUT:] if isinstance(exc.stderr, str) else "",
        }
    result = {
        "argv": argv,
        "exit_code": cp.returncode,
        "timed_out": False,
        "elapsed_seconds": round(time.perf_counter() - started, 3),
        "stdout": cp.stdout[-MAX_OUTPUT:],
        "stderr": cp.stderr[-MAX_OUTPUT:],
    }
    if check and cp.returncode != 0:
        raise EngineError(f"Command failed rc={cp.returncode}: {' '.join(argv)}\n{cp.stderr[-2000:]}")
    return result

def git(repo: Path, *args: str, timeout: int = 30, env: dict[str, str] | None = None, check: bool = False) -> dict[str, Any]:
    return run(["git", "-C", str(repo), *args], timeout=timeout, env=env, check=check)

def repo_root(raw: str) -> Path:
    p = Path(raw).expanduser().resolve()
    if not p.exists():
        raise EngineError(f"Path not found: {p}")
    probe = run(["git", "-C", str(p), "rev-parse", "--show-toplevel"], timeout=10)
    if probe["exit_code"] != 0:
        raise EngineError(f"Not inside a Git repository: {p}")
    return Path(probe["stdout"].strip()).resolve()

def redact_remote_url(url: str) -> str:
    url = url.strip()
    if not url:
        return url
    try:
        parts = urlsplit(url)
        if parts.scheme and "@" in parts.netloc:
            host = parts.netloc.split("@", 1)[1]
            return urlunsplit((parts.scheme, host, parts.path, parts.query, parts.fragment))
    except Exception:
        pass
    return re.sub(r"(?i)(https?://)[^/@\s]+@", r"\1", url)

def parse_porcelain_v2(text: str) -> dict[str, Any]:
    branch = None
    oid = None
    upstream = None
    ahead = behind = 0
    entries = []
    for line in text.splitlines():
        if line.startswith("# branch.head "):
            branch = line.split(" ", 2)[2]
        elif line.startswith("# branch.oid "):
            oid = line.split(" ", 2)[2]
        elif line.startswith("# branch.upstream "):
            upstream = line.split(" ", 2)[2]
        elif line.startswith("# branch.ab "):
            m = re.search(r"\+(\d+) -(\d+)", line)
            if m:
                ahead, behind = int(m.group(1)), int(m.group(2))
        elif line and not line.startswith("#"):
            entries.append(line)
    return {
        "branch": branch,
        "head": oid,
        "upstream": upstream,
        "ahead": ahead,
        "behind": behind,
        "entries": entries,
        "clean": len(entries) == 0,
    }

def repo_find(query: str, limit: int) -> dict[str, Any]:
    if not FAST_INDEX_DB.exists():
        raise EngineError(f"Fast Local Engine database missing: {FAST_INDEX_DB}")
    con = sqlite3.connect(str(FAST_INDEX_DB))
    con.row_factory = sqlite3.Row
    limit = max(1, min(limit, 50))
    terms = [x for x in re.findall(r"[\w.-]+", query, flags=re.UNICODE) if x]
    rows = []
    if terms:
        fts = " AND ".join(f'"{t.replace(chr(34), chr(34)*2)}"*' for t in terms)
        try:
            rows = con.execute(
                """SELECT w.path,w.name,w.markers,bm25(workspaces_fts,1.5,5.0,1.0) AS score
                   FROM workspaces_fts
                   JOIN workspaces w ON w.rowid=workspaces_fts.rowid
                   WHERE workspaces_fts MATCH ? AND instr(w.markers,'.git') > 0
                   ORDER BY score ASC LIMIT ?""",
                (fts, limit),
            ).fetchall()
        except sqlite3.OperationalError:
            rows = []
    if not rows:
        like = f"%{query}%"
        rows = con.execute(
            """SELECT path,name,markers,0.0 AS score FROM workspaces
               WHERE instr(markers,'.git') > 0
                 AND (name LIKE ? COLLATE NOCASE OR path LIKE ? COLLATE NOCASE)
               ORDER BY path LIMIT ?""",
            (like, like, limit),
        ).fetchall()
    results = []
    for row in rows:
        p = Path(row["path"])
        if (p / ".git").exists():
            results.append({
                "path": str(p),
                "name": row["name"],
                "markers": row["markers"].split(",") if row["markers"] else [],
                "score": round(float(row["score"]), 4),
            })
    return {"ok": True, "command": "repo_find", "query": query, "count": len(results), "results": results}

def repo_status(raw: str) -> dict[str, Any]:
    root = repo_root(raw)
    status = git(root, "status", "--porcelain=v2", "--branch", "--untracked-files=all", timeout=20, check=True)
    parsed = parse_porcelain_v2(status["stdout"])
    staged = git(root, "diff", "--cached", "--name-only", timeout=20, check=True)["stdout"].splitlines()
    unstaged = git(root, "diff", "--name-only", timeout=20, check=True)["stdout"].splitlines()
    untracked = git(root, "ls-files", "--others", "--exclude-standard", timeout=20, check=True)["stdout"].splitlines()
    return {
        "ok": True,
        "command": "repo_status",
        "repo": str(root),
        **{k: parsed[k] for k in ("branch", "head", "upstream", "ahead", "behind", "clean")},
        "counts": {"staged": len(staged), "unstaged": len(unstaged), "untracked": len(untracked)},
        "staged": staged[:200],
        "unstaged": unstaged[:200],
        "untracked": untracked[:200],
    }

def load_package_json(root: Path) -> dict[str, Any] | None:
    p = root / "package.json"
    if not p.exists():
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8-sig"))
    except Exception:
        return None

def detect_manager(root: Path, pkg: dict[str, Any] | None) -> dict[str, Any]:
    requested = None
    if pkg and pkg.get("packageManager"):
        requested = str(pkg["packageManager"]).split("@", 1)[0]
    if (root / "pnpm-lock.yaml").exists():
        requested = requested or "pnpm"
    elif (root / "yarn.lock").exists():
        requested = requested or "yarn"
    elif (root / "bun.lock").exists() or (root / "bun.lockb").exists():
        requested = requested or "bun"
    elif (root / "package-lock.json").exists() or pkg:
        requested = requested or "npm"

    available = {}
    for name in ("npm", "pnpm", "yarn", "bun"):
        probe = run(["where.exe", name], timeout=5)
        available[name] = probe["exit_code"] == 0
    return {"requested": requested, "available": available}

def repo_summary(raw: str) -> dict[str, Any]:
    root = repo_root(raw)
    status = repo_status(str(root))
    pkg = load_package_json(root)
    manager = detect_manager(root, pkg)

    remotes = {}
    names = git(root, "remote", timeout=10, check=True)["stdout"].splitlines()
    for name in names[:20]:
        url = git(root, "remote", "get-url", name, timeout=10)["stdout"].strip()
        remotes[name] = redact_remote_url(url)

    files = git(root, "ls-files", "-z", timeout=30, check=True)["stdout"].split("\x00")
    files = [f for f in files if f]
    ext_counts: dict[str, int] = {}
    for f in files:
        ext = Path(f).suffix.lower() or "<none>"
        ext_counts[ext] = ext_counts.get(ext, 0) + 1

    log = git(root, "log", "-5", "--date=iso-strict", "--pretty=format:%h%x09%ad%x09%s", timeout=20)
    recent = []
    for line in log["stdout"].splitlines():
        parts = line.split("\t", 2)
        if len(parts) == 3:
            recent.append({"sha": parts[0], "date": parts[1], "subject": parts[2]})

    scripts = {}
    if pkg and isinstance(pkg.get("scripts"), dict):
        scripts = {str(k): str(v) for k, v in pkg["scripts"].items()}

    return {
        "ok": True,
        "command": "repo_summary",
        "repo": str(root),
        "name": pkg.get("name") if pkg else root.name,
        "status": {k: status[k] for k in ("branch", "head", "upstream", "ahead", "behind", "clean", "counts")},
        "remotes": remotes,
        "tracked_files": len(files),
        "top_extensions": sorted(ext_counts.items(), key=lambda x: (-x[1], x[0]))[:15],
        "package_manager": manager,
        "scripts": scripts,
        "recent_commits": recent,
        "markers": [x for x in ("package.json", "pyproject.toml", "requirements.txt", "tsconfig.json", "Cargo.toml", "go.mod") if (root / x).exists()],
    }

def repo_search(raw: str, query: str, limit: int, regex: bool) -> dict[str, Any]:
    root = repo_root(raw)
    limit = max(1, min(limit, 200))
    args = ["grep", "-n", "-I"]
    if not regex:
        args.append("-F")
    args += ["-e", query, "--"]
    result = git(root, *args, timeout=30)
    if result["exit_code"] not in (0, 1):
        raise EngineError(f"git grep failed rc={result['exit_code']}: {result['stderr'][-2000:]}")
    lines = result["stdout"].splitlines()[:limit]
    matches = []
    for line in lines:
        parts = line.split(":", 2)
        if len(parts) == 3:
            matches.append({"path": parts[0], "line": int(parts[1]) if parts[1].isdigit() else parts[1], "text": parts[2][:1500]})
        else:
            matches.append({"raw": line[:1500]})
    return {"ok": True, "command": "repo_search", "repo": str(root), "query": query, "regex": regex, "count": len(matches), "results": matches}

def repo_diff(raw: str, mode: str, max_chars: int) -> dict[str, Any]:
    root = repo_root(raw)
    max_chars = max(2000, min(max_chars, 100000))
    modes = []
    if mode in ("all", "unstaged"):
        modes.append(("unstaged", []))
    if mode in ("all", "staged"):
        modes.append(("staged", ["--cached"]))
    if not modes:
        raise EngineError("mode must be all, unstaged, or staged")

    sections = []
    for name, prefix in modes:
        stat = git(root, "diff", *prefix, "--stat", timeout=30, check=True)["stdout"]
        patch = git(root, "diff", *prefix, "--no-ext-diff", "--unified=3", timeout=45, check=True)["stdout"]
        sections.append({
            "kind": name,
            "stat": stat[:10000],
            "patch": patch[:max_chars],
            "patch_truncated": len(patch) > max_chars,
        })
    untracked = git(root, "ls-files", "--others", "--exclude-standard", timeout=20, check=True)["stdout"].splitlines()
    return {"ok": True, "command": "repo_diff", "repo": str(root), "mode": mode, "sections": sections, "untracked": untracked[:200]}

SECRET_PATH_RE = re.compile(r"(?i)(^|/)(\.env($|\.)|id_rsa|id_ed25519|credentials?\.json|secrets?\.|auth\.key$)|\.(pem|p12|pfx|key)$")
SECRET_CONTENT_RES = [
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    re.compile(r"(?i)github_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"(?i)ghp_[A-Za-z0-9]{20,}"),
    re.compile(r"(?i)(COMPOSIO_API_KEY|OPENAI_API_KEY|ANTHROPIC_API_KEY|GITHUB_TOKEN)\s*[:=]\s*[^\s'\"]{8,}"),
]

def secret_like_findings(root: Path, files: list[str]) -> list[dict[str, str]]:
    findings = []
    for rel in files[:5000]:
        norm = rel.replace("\\", "/")
        if SECRET_PATH_RE.search(norm):
            findings.append({"path": rel, "reason": "secret-like filename/path"})
            continue
        p = root / rel
        try:
            if not p.is_file() or p.stat().st_size > 2 * 1024 * 1024:
                continue
            data = p.read_bytes()
            if b"\x00" in data[:8192]:
                continue
            text = data.decode("utf-8", errors="ignore")
            for pattern in SECRET_CONTENT_RES:
                if pattern.search(text):
                    findings.append({"path": rel, "reason": "secret-like content"})
                    break
        except OSError:
            continue
    return findings[:100]

def checkpoint(raw: str, label: str, include_untracked: bool) -> dict[str, Any]:
    root = repo_root(raw)
    status_before = repo_status(str(root))
    head = git(root, "rev-parse", "HEAD", timeout=10, check=True)["stdout"].strip()
    current_branch = status_before["branch"]
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    safe_label = re.sub(r"[^A-Za-z0-9._-]+", "-", label.strip()).strip("-")[:40] or "checkpoint"
    branch_name = f"checkpoint/remote-growth-{timestamp}-{safe_label}"
    ref = f"refs/heads/{branch_name}"

    exists = git(root, "show-ref", "--verify", "--quiet", ref, timeout=10)
    if exists["exit_code"] == 0:
        raise EngineError(f"Checkpoint ref already exists: {branch_name}")

    with tempfile.TemporaryDirectory(prefix="remote-growth-git-") as td:
        index_file = str(Path(td) / "index")
        env = {"GIT_INDEX_FILE": index_file}
        git(root, "read-tree", "HEAD", timeout=20, env=env, check=True)

        add_args = ["add", "-A"]
        if not include_untracked:
            add_args = ["add", "-u"]
        git(root, *add_args, timeout=90, env=env, check=True)

        changed = git(root, "diff", "--cached", "--name-only", timeout=30, env=env, check=True)["stdout"].splitlines()
        if not changed:
            return {
                "ok": True,
                "command": "repo_checkpoint",
                "repo": str(root),
                "created": False,
                "reason": "NO_CHANGES",
                "branch": current_branch,
                "head": head,
            }

        findings = secret_like_findings(root, changed)
        if findings:
            return {
                "ok": False,
                "command": "repo_checkpoint",
                "repo": str(root),
                "created": False,
                "reason": "SECRET_LIKE_CONTENT",
                "findings": findings,
            }

        tree = git(root, "write-tree", timeout=30, env=env, check=True)["stdout"].strip()
        message = f"checkpoint: {safe_label} ({timestamp})"
        identity_env = {
            **env,
            "GIT_AUTHOR_NAME": "Remote GROWTH Stable",
            "GIT_AUTHOR_EMAIL": "remote-growth@localhost",
            "GIT_COMMITTER_NAME": "Remote GROWTH Stable",
            "GIT_COMMITTER_EMAIL": "remote-growth@localhost",
        }
        commit = git(root, "commit-tree", tree, "-p", head, "-m", message, timeout=30, env=identity_env, check=True)["stdout"].strip()
        git(root, "update-ref", ref, commit, "", timeout=20, check=True)

    status_after = repo_status(str(root))
    return {
        "ok": True,
        "command": "repo_checkpoint",
        "repo": str(root),
        "created": True,
        "checkpoint_branch": branch_name,
        "checkpoint_commit": commit,
        "parent_head": head,
        "included_file_count": len(changed),
        "included_files": changed[:300],
        "working_branch_unchanged": status_after["branch"] == current_branch,
        "working_status_counts_before": status_before["counts"],
        "working_status_counts_after": status_after["counts"],
        "note": "Local checkpoint ref only; nothing was pushed.",
    }

def task_command(root: Path, task: str) -> dict[str, Any]:
    if task not in TASKS:
        raise EngineError(f"Unsupported task: {task}")
    pkg = load_package_json(root)
    scripts = pkg.get("scripts", {}) if pkg and isinstance(pkg.get("scripts"), dict) else {}
    script_name = "format:check" if task == "format-check" else task
    if script_name in scripts:
        manager = detect_manager(root, pkg)
        requested = manager["requested"] or "npm"
        if not manager["available"].get(requested, False):
            return {"available": False, "reason": f"package manager '{requested}' is not installed", "task": task}
        executable = shutil.which(requested)
        if not executable:
            return {"available": False, "reason": f"package manager '{requested}' executable cannot be resolved", "task": task}
        if requested == "npm":
            argv = [executable, "run", script_name]
        elif requested == "yarn":
            argv = [executable, script_name]
        elif requested == "pnpm":
            argv = [executable, "run", script_name]
        else:
            argv = [executable, "run", script_name]
        return {"available": True, "task": task, "source": "package.json", "script": scripts[script_name], "argv": argv, "manager": requested}

    return {"available": False, "task": task, "reason": f"No declared '{script_name}' project script"}

def code_run_check(raw: str, task: str, timeout: int) -> dict[str, Any]:
    root = repo_root(raw)
    plan = task_command(root, task)
    if not plan["available"]:
        return {"ok": True, "command": "code_run_check", "repo": str(root), "executed": False, **plan}
    timeout = max(10, min(timeout, 900))
    result = run(plan["argv"], cwd=root, timeout=timeout)
    return {
        "ok": True,
        "command": "code_run_check",
        "repo": str(root),
        "executed": True,
        "task": task,
        "source": plan["source"],
        "script": plan.get("script"),
        "argv": plan["argv"],
        "passed": result["exit_code"] == 0 and not result["timed_out"],
        **result,
    }

def code_quality(raw: str, execute: bool, timeout_per_task: int) -> dict[str, Any]:
    root = repo_root(raw)
    preferred = ["lint", "typecheck", "test", "build"]
    plans = [task_command(root, task) for task in preferred]
    available = [p for p in plans if p["available"]]
    if not execute:
        return {
            "ok": True,
            "command": "code_quality",
            "repo": str(root),
            "executed": False,
            "available_tasks": available,
            "unavailable_tasks": [p for p in plans if not p["available"]],
        }

    results = []
    for plan in available:
        result = code_run_check(str(root), plan["task"], timeout_per_task)
        results.append(result)
        if result.get("executed") and not result.get("passed"):
            break

    passed = bool(results) and all((not r.get("executed")) or r.get("passed") for r in results)
    return {
        "ok": True,
        "command": "code_quality",
        "repo": str(root),
        "executed": True,
        "passed": passed,
        "results": results,
        "stopped_after_failure": bool(results) and not results[-1].get("passed", True),
    }

def health() -> dict[str, Any]:
    binaries = {}
    for cmd in ("git", "node", "npm", "python", "pnpm", "yarn", "bun"):
        probe = run(["where.exe", cmd], timeout=5)
        binaries[cmd] = probe["stdout"].splitlines()[0] if probe["exit_code"] == 0 and probe["stdout"].splitlines() else None
    return {
        "ok": True,
        "command": "health",
        "fast_index_db": str(FAST_INDEX_DB),
        "fast_index_available": FAST_INDEX_DB.exists(),
        "binaries": binaries,
        "tasks": sorted(TASKS),
        "checkpoint_semantics": "alternate-index commit-tree + local checkpoint ref; working tree/index/current branch unchanged",
        "checkpoint_pushes_remote": False,
    }

def main() -> int:
    parser = argparse.ArgumentParser(prog="developer-engine")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("health")

    p = sub.add_parser("repo-find")
    p.add_argument("query")
    p.add_argument("--limit", type=int, default=20)

    p = sub.add_parser("repo-status")
    p.add_argument("path")

    p = sub.add_parser("repo-summary")
    p.add_argument("path")

    p = sub.add_parser("repo-search")
    p.add_argument("path")
    p.add_argument("query")
    p.add_argument("--limit", type=int, default=50)
    p.add_argument("--regex", action="store_true")

    p = sub.add_parser("repo-diff")
    p.add_argument("path")
    p.add_argument("--mode", choices=("all", "unstaged", "staged"), default="all")
    p.add_argument("--max-chars", type=int, default=30000)

    p = sub.add_parser("repo-checkpoint")
    p.add_argument("path")
    p.add_argument("--label", default="manual")
    p.add_argument("--no-untracked", action="store_true")

    p = sub.add_parser("code-run-check")
    p.add_argument("path")
    p.add_argument("task", choices=sorted(TASKS))
    p.add_argument("--timeout", type=int, default=180)

    p = sub.add_parser("code-quality")
    p.add_argument("path")
    p.add_argument("--execute", action="store_true")
    p.add_argument("--timeout-per-task", type=int, default=180)

    args = parser.parse_args()
    try:
        if args.command == "health":
            result = health()
        elif args.command == "repo-find":
            result = repo_find(args.query, args.limit)
        elif args.command == "repo-status":
            result = repo_status(args.path)
        elif args.command == "repo-summary":
            result = repo_summary(args.path)
        elif args.command == "repo-search":
            result = repo_search(args.path, args.query, args.limit, args.regex)
        elif args.command == "repo-diff":
            result = repo_diff(args.path, args.mode, args.max_chars)
        elif args.command == "repo-checkpoint":
            result = checkpoint(args.path, args.label, not args.no_untracked)
        elif args.command == "code-run-check":
            result = code_run_check(args.path, args.task, args.timeout)
        elif args.command == "code-quality":
            result = code_quality(args.path, args.execute, args.timeout_per_task)
        else:
            raise EngineError("Unknown command")
        emit(result)
        return 0 if result.get("ok", False) else 2
    except Exception as exc:
        emit({"ok": False, "command": args.command, "error": type(exc).__name__, "message": str(exc)})
        return 1

if __name__ == "__main__":
    raise SystemExit(main())