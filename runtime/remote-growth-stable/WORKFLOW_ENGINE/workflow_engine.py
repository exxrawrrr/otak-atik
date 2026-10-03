from __future__ import annotations

import argparse
import copy
import hashlib
import json
import subprocess
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import os
import sys

PROD_ROOT = Path(__file__).resolve().parent
RUNTIME_ROOT = Path(os.environ.get("REMOTE_GROWTH_ROOT", str(PROD_ROOT.parent)))
PLAN_ROOT = PROD_ROOT / "plans"
RECEIPT_ROOT = PROD_ROOT / "receipts"

PYTHON = Path(os.environ.get("REMOTE_GROWTH_PYTHON", sys.executable))
ENGINES = {
    "developer": RUNTIME_ROOT / "DEVELOPER_ENGINE" / "developer_engine.py",
    "fileops": RUNTIME_ROOT / "FILEOPS_ENGINE" / "fileops_engine.py",
    "systemops": RUNTIME_ROOT / "SYSTEMOPS_ENGINE" / "systemops_engine.py",
    "local": RUNTIME_ROOT / "FAST_LOCAL_ENGINE" / "local_engine.py",
}

IRREVERSIBLE_SYSTEM_ACTIONS = {"terminate_process", "restart_service", "run_task", "flush_dns"}

class WorkflowError(Exception):
    pass

def now_iso() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")

def emit(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, ensure_ascii=True, default=str))

def stable_hash(obj: Any) -> str:
    raw = json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()

def ensure_roots() -> None:
    PLAN_ROOT.mkdir(parents=True, exist_ok=True)
    RECEIPT_ROOT.mkdir(parents=True, exist_ok=True)

def run_engine(engine: str, args: list[str], timeout: int = 300, allow_failure: bool = False) -> dict[str, Any]:
    script = ENGINES[engine]
    cp = subprocess.run(
        [str(PYTHON), str(script), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
    )
    stdout = cp.stdout.strip()
    payload: dict[str, Any] | None = None
    if stdout:
        try:
            payload = json.loads(stdout.splitlines()[-1])
        except json.JSONDecodeError:
            payload = None
    if cp.returncode != 0:
        if allow_failure and isinstance(payload, dict):
            return payload
        raise WorkflowError(
            f"{engine} engine failed rc={cp.returncode}: "
            f"{payload if payload is not None else (cp.stderr.strip() or stdout)[-2000:]}"
        )
    if not isinstance(payload, dict):
        raise WorkflowError(f"{engine} engine returned invalid JSON")
    if not payload.get("ok", False) and not allow_failure:
        raise WorkflowError(f"{engine} engine returned ok=false: {payload}")
    return payload

def ref(path: str) -> dict[str, str]:
    return {"$ref": path}

ACTION_CATALOG: dict[str, dict[str, Any]] = {
    "developer.repo_status": {"engine": "developer", "mutating": False},
    "developer.repo_diff": {"engine": "developer", "mutating": False},
    "developer.code_quality": {"engine": "developer", "mutating": "dynamic"},
    "developer.repo_checkpoint": {"engine": "developer", "mutating": True, "additive": True},
    "fileops.workspace_backup": {"engine": "fileops", "mutating": True, "additive": True},
    "fileops.storage_analyze": {"engine": "fileops", "mutating": False},
    "fileops.duplicates": {"engine": "fileops", "mutating": False},
    "fileops.batch_plan": {"engine": "fileops", "mutating": False},
    "fileops.batch_execute": {"engine": "fileops", "mutating": True, "rollback": "fileops.rollback"},
    "fileops.rollback": {"engine": "fileops", "mutating": True},
    "systemops.system_health": {"engine": "systemops", "mutating": False},
    "systemops.network_inspect": {"engine": "systemops", "mutating": False},
    "systemops.tailscale_inspect": {"engine": "systemops", "mutating": False},
    "systemops.startup_inspect": {"engine": "systemops", "mutating": False},
    "systemops.action_plan": {"engine": "systemops", "mutating": False},
    "systemops.action_execute": {"engine": "systemops", "mutating": True, "rollback": "systemops.action_rollback"},
    "systemops.action_rollback": {"engine": "systemops", "mutating": True},
}

TEMPLATES = {
    "repo_health": {
        "description": "Inspect repo status/diff and optionally run the repo-declared quality suite.",
        "required": ["repo_path"],
    },
    "repo_backup_quality_checkpoint": {
        "description": "Create a verified workspace backup, inspect repo, run quality, then create a local Git checkpoint.",
        "required": ["repo_path"],
    },
    "safe_file_batch": {
        "description": "Validate a FileOps batch plan and optionally execute it with a reversible receipt.",
        "required": ["operations"],
    },
    "storage_cleanup_assessment": {
        "description": "Read-only storage size and exact-duplicate assessment.",
        "required": ["path"],
    },
    "system_health_report": {
        "description": "Read-only Windows + network + Tailscale + startup health bundle.",
        "required": [],
    },
    "safe_system_action": {
        "description": "Plan a bounded SystemOps action and optionally execute it with irreversible guard/rollback metadata.",
        "required": ["action", "target"],
    },
}

def normalize_params(template: str, params: dict[str, Any]) -> dict[str, Any]:
    if template not in TEMPLATES:
        raise WorkflowError(f"Unknown workflow template: {template}")
    if not isinstance(params, dict):
        raise WorkflowError("params must be an object")
    for key in TEMPLATES[template]["required"]:
        if key not in params:
            raise WorkflowError(f"Missing required param '{key}' for template '{template}'")
    return copy.deepcopy(params)

def step(step_id: str, action: str, args: dict[str, Any], depends_on: list[str] | None = None, condition: str | None = None) -> dict[str, Any]:
    if action not in ACTION_CATALOG:
        raise WorkflowError(f"Action not in catalog: {action}")
    return {
        "id": step_id,
        "action": action,
        "args": args,
        "depends_on": depends_on or [],
        "condition": condition,
    }

def build_steps(template: str, p: dict[str, Any]) -> list[dict[str, Any]]:
    if template == "repo_health":
        repo = str(p["repo_path"])
        execute_quality = bool(p.get("execute_quality", False))
        return [
            step("repo_status", "developer.repo_status", {"path": repo}),
            step("repo_diff", "developer.repo_diff", {"path": repo, "mode": str(p.get("diff_mode", "all")), "max_chars": int(p.get("max_diff_chars", 30000))}),
            step("quality", "developer.code_quality", {"path": repo, "execute": execute_quality, "timeout_per_task": int(p.get("timeout_per_task", 180))}),
        ]

    if template == "repo_backup_quality_checkpoint":
        repo = str(p["repo_path"])
        label = str(p.get("label", "workflow"))
        return [
            step("backup", "fileops.workspace_backup", {"path": repo, "label": label}),
            step("repo_status", "developer.repo_status", {"path": repo}, ["backup"]),
            step("quality", "developer.code_quality", {"path": repo, "execute": True, "timeout_per_task": int(p.get("timeout_per_task", 180))}, ["repo_status"]),
            step("checkpoint", "developer.repo_checkpoint", {"path": repo, "label": str(p.get("checkpoint_label", label)), "include_untracked": bool(p.get("include_untracked", True))}, ["quality"], "quality_passed"),
        ]

    if template == "safe_file_batch":
        ops = p["operations"]
        if not isinstance(ops, list) or not ops:
            raise WorkflowError("operations must be a non-empty list")
        steps = [
            step("file_plan", "fileops.batch_plan", {"operations": ops, "label": str(p.get("label", "workflow"))}),
        ]
        if bool(p.get("execute", False)):
            steps.append(step("file_execute", "fileops.batch_execute", {"plan_id": ref("file_plan.plan_id")}, ["file_plan"]))
        return steps

    if template == "storage_cleanup_assessment":
        raw = str(p["path"])
        return [
            step("storage", "fileops.storage_analyze", {"path": raw, "depth": int(p.get("depth", 2)), "top_n": int(p.get("top_n", 30))}),
            step("duplicates", "fileops.duplicates", {"path": raw, "min_size": int(p.get("min_size", 1048576)), "limit_groups": int(p.get("limit_groups", 50))}),
        ]

    if template == "system_health_report":
        return [
            step("system", "systemops.system_health", {}),
            step("network", "systemops.network_inspect", {}),
            step("tailscale", "systemops.tailscale_inspect", {}),
            step("startup", "systemops.startup_inspect", {}),
        ]

    if template == "safe_system_action":
        action = str(p["action"])
        target = p["target"]
        if not isinstance(target, dict):
            raise WorkflowError("target must be an object")
        steps = [
            step("system_plan", "systemops.action_plan", {"action": action, "target": target, "label": str(p.get("label", "workflow"))}),
        ]
        if bool(p.get("execute", False)):
            steps.append(step("system_execute", "systemops.action_execute", {
                "plan_id": ref("system_plan.plan_id"),
                "allow_irreversible": bool(p.get("allow_irreversible", False)),
            }, ["system_plan"]))
        return steps

    raise WorkflowError(f"Template not implemented: {template}")

def action_is_mutating(action: str, args: dict[str, Any]) -> bool:
    meta = ACTION_CATALOG[action]
    marker = meta.get("mutating", False)
    if marker == "dynamic":
        return bool(args.get("execute", False))
    return bool(marker)

def action_may_be_irreversible(action: str, args: dict[str, Any], context: dict[str, Any] | None = None) -> bool:
    if action == "systemops.action_execute":
        if context:
            plan_result = context.get("system_plan", {})
            return bool(plan_result.get("irreversible", False))
        return bool(args.get("allow_irreversible", False))
    return False

def workflow_plan(template: str, params: dict[str, Any], label: str) -> dict[str, Any]:
    ensure_roots()
    normalized = normalize_params(template, params)
    steps = build_steps(template, normalized)
    plan_id = datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:8]
    contains_mutations = any(action_is_mutating(s["action"], s["args"]) for s in steps)
    plan = {
        "version": 1,
        "plan_id": plan_id,
        "template": template,
        "label": label[:120],
        "created_at": now_iso(),
        "params": normalized,
        "steps": steps,
        "contains_mutations": contains_mutations,
    }
    plan["plan_hash"] = stable_hash(plan)
    path = PLAN_ROOT / f"{plan_id}.json"
    path.write_text(json.dumps(plan, indent=2, ensure_ascii=True), encoding="utf-8")
    return {
        "ok": True,
        "command": "workflow_plan",
        "plan_id": plan_id,
        "template": template,
        "label": plan["label"],
        "contains_mutations": contains_mutations,
        "step_count": len(steps),
        "steps": [{"id": s["id"], "action": s["action"], "depends_on": s["depends_on"], "condition": s["condition"]} for s in steps],
        "plan_hash": plan["plan_hash"],
        "plan_file": str(path),
    }

def load_plan(plan_id: str) -> dict[str, Any]:
    path = PLAN_ROOT / f"{plan_id}.json"
    if not path.exists():
        raise WorkflowError(f"Plan not found: {plan_id}")
    plan = json.loads(path.read_text(encoding="utf-8"))
    expected = plan.get("plan_hash")
    check = dict(plan)
    check.pop("plan_hash", None)
    if stable_hash(check) != expected:
        raise WorkflowError("Plan hash mismatch; plan file was modified")
    return plan

def get_path(obj: dict[str, Any], path: str) -> Any:
    cur: Any = obj
    for part in path.split("."):
        if not isinstance(cur, dict) or part not in cur:
            raise WorkflowError(f"Reference not found: {path}")
        cur = cur[part]
    return cur

def resolve_refs(value: Any, results: dict[str, Any]) -> Any:
    if isinstance(value, dict):
        if set(value) == {"$ref"}:
            raw = str(value["$ref"])
            first, _, rest = raw.partition(".")
            if first not in results:
                raise WorkflowError(f"Referenced step not completed: {first}")
            return get_path(results[first], rest) if rest else results[first]
        return {k: resolve_refs(v, results) for k, v in value.items()}
    if isinstance(value, list):
        return [resolve_refs(v, results) for v in value]
    return value

def condition_passes(condition: str | None, results: dict[str, Any]) -> bool:
    if condition is None:
        return True
    if condition == "quality_passed":
        q = results.get("quality", {})
        if q.get("passed") is True:
            return True
        if q.get("ok") is True and q.get("execute") is False:
            return True
        return False
    raise WorkflowError(f"Unknown workflow condition: {condition}")

def dispatch(action: str, args: dict[str, Any]) -> dict[str, Any]:
    if action == "developer.repo_status":
        return run_engine("developer", ["repo-status", str(args["path"])], 60)
    if action == "developer.repo_diff":
        return run_engine("developer", ["repo-diff", str(args["path"]), "--mode", str(args.get("mode", "all")), "--max-chars", str(int(args.get("max_chars", 30000)))], 90)
    if action == "developer.code_quality":
        cmd = ["code-quality", str(args["path"]), "--timeout-per-task", str(int(args.get("timeout_per_task", 180)))]
        if bool(args.get("execute", False)):
            cmd.append("--execute")
        return run_engine("developer", cmd, max(60, int(args.get("timeout_per_task", 180)) * 4 + 60))
    if action == "developer.repo_checkpoint":
        cmd = ["repo-checkpoint", str(args["path"]), "--label", str(args.get("label", "workflow"))]
        if not bool(args.get("include_untracked", True)):
            cmd.append("--no-untracked")
        return run_engine("developer", cmd, 180, allow_failure=True)

    if action == "fileops.workspace_backup":
        return run_engine("fileops", ["workspace-backup", str(args["path"]), "--label", str(args.get("label", "workflow"))], 1800)
    if action == "fileops.storage_analyze":
        return run_engine("fileops", ["storage-analyze", str(args["path"]), "--depth", str(int(args.get("depth", 2))), "--top-n", str(int(args.get("top_n", 30)))], 300)
    if action == "fileops.duplicates":
        return run_engine("fileops", ["duplicates", str(args["path"]), "--min-size", str(int(args.get("min_size", 1048576))), "--limit-groups", str(int(args.get("limit_groups", 50)))], 600)
    if action == "fileops.batch_plan":
        return run_engine("fileops", ["batch-plan", json.dumps(args["operations"], ensure_ascii=True), "--label", str(args.get("label", "workflow"))], 90, allow_failure=True)
    if action == "fileops.batch_execute":
        return run_engine("fileops", ["batch-execute", str(args["plan_id"])], 1800, allow_failure=True)
    if action == "fileops.rollback":
        return run_engine("fileops", ["rollback", str(args["receipt_id"])], 1800, allow_failure=True)

    if action == "systemops.system_health":
        return run_engine("systemops", ["system-health"], 60)
    if action == "systemops.network_inspect":
        return run_engine("systemops", ["network-inspect"], 60)
    if action == "systemops.tailscale_inspect":
        return run_engine("systemops", ["tailscale-inspect"], 60)
    if action == "systemops.startup_inspect":
        return run_engine("systemops", ["startup-inspect"], 60)
    if action == "systemops.action_plan":
        return run_engine("systemops", ["action-plan", str(args["action"]), json.dumps(args["target"], ensure_ascii=True), "--label", str(args.get("label", "workflow"))], 120, allow_failure=True)
    if action == "systemops.action_execute":
        cmd = ["action-execute", str(args["plan_id"])]
        if bool(args.get("allow_irreversible", False)):
            cmd.append("--allow-irreversible")
        return run_engine("systemops", cmd, 300, allow_failure=True)
    if action == "systemops.action_rollback":
        return run_engine("systemops", ["action-rollback", str(args["receipt_id"])], 300, allow_failure=True)

    raise WorkflowError(f"Unsupported dispatch action: {action}")

def result_summary(result: dict[str, Any]) -> dict[str, Any]:
    keys = (
        "ok", "command", "status", "passed", "executed", "plan_id", "receipt_id",
        "checkpoint_branch", "checkpoint_commit", "operation_count", "group_count",
        "reclaimable_bytes_if_keep_one", "backup", "error", "message",
    )
    out = {k: result[k] for k in keys if k in result}
    if "data" in result and isinstance(result["data"], dict):
        data = result["data"]
        out["data_summary"] = {k: data[k] for k in ("computer", "uptime_seconds", "cpu_load_percent", "process_count", "backend_state", "self_dns_name") if k in data}
    return out

def find_plan_receipts(plan_id: str) -> list[Path]:
    ensure_roots()
    return sorted(RECEIPT_ROOT.glob(f"{plan_id}-*.json"))

def rollback_from_steps(step_records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rolled: list[dict[str, Any]] = []
    for record in reversed(step_records):
        if record.get("status") != "COMPLETE":
            continue
        action = record["action"]
        result = record.get("result") or {}
        try:
            if action == "fileops.batch_execute" and result.get("receipt_id"):
                rb = dispatch("fileops.rollback", {"receipt_id": result["receipt_id"]})
                rolled.append({"step_id": record["id"], "action": action, "rollback": "fileops.rollback", "ok": bool(rb.get("ok")), "result": result_summary(rb)})
            elif action == "systemops.action_execute" and result.get("receipt_id"):
                rb = dispatch("systemops.action_rollback", {"receipt_id": result["receipt_id"]})
                rolled.append({"step_id": record["id"], "action": action, "rollback": "systemops.action_rollback", "ok": bool(rb.get("ok")), "result": result_summary(rb)})
        except Exception as exc:
            rolled.append({"step_id": record["id"], "action": action, "ok": False, "error": f"{type(exc).__name__}: {exc}"})
    return rolled

def workflow_execute(
    plan_id: str,
    allow_mutations: bool,
    allow_irreversible: bool,
    rollback_on_failure: bool,
    allow_reexecute: bool,
) -> dict[str, Any]:
    ensure_roots()
    plan = load_plan(plan_id)
    previous = find_plan_receipts(plan_id)
    if previous and not allow_reexecute:
        raise WorkflowError(f"Plan already has {len(previous)} execution receipt(s); allow_reexecute=true is required")

    if plan.get("contains_mutations") and not allow_mutations:
        raise WorkflowError("Workflow contains mutations; allow_mutations=true is required")

    execution_id = plan_id + "-run-" + uuid.uuid4().hex[:8]
    results: dict[str, Any] = {}
    records: list[dict[str, Any]] = []
    started = time.perf_counter()
    status = "COMPLETE"
    error: str | None = None
    rollback_records: list[dict[str, Any]] = []

    try:
        for s in plan["steps"]:
            for dep in s.get("depends_on", []):
                dep_record = next((r for r in records if r["id"] == dep), None)
                if dep_record is None or dep_record["status"] not in {"COMPLETE", "SKIPPED"}:
                    raise WorkflowError(f"Dependency not satisfied for step {s['id']}: {dep}")

            if not condition_passes(s.get("condition"), results):
                records.append({"id": s["id"], "action": s["action"], "status": "SKIPPED", "reason": f"condition:{s.get('condition')}"})
                continue

            resolved = resolve_refs(s["args"], results)
            mutating = action_is_mutating(s["action"], resolved)
            if mutating and not allow_mutations:
                raise WorkflowError(f"Mutation permission missing for step: {s['id']}")

            if s["action"] == "systemops.action_execute":
                system_plan = results.get("system_plan", {})
                irreversible = bool(system_plan.get("irreversible", False))
                if irreversible and not allow_irreversible:
                    raise WorkflowError("Workflow contains an irreversible SystemOps action; allow_irreversible=true is required")
                if irreversible:
                    resolved["allow_irreversible"] = True

            step_started = time.perf_counter()
            result = dispatch(s["action"], resolved)
            if not result.get("ok", False):
                raise WorkflowError(f"Step {s['id']} returned ok=false: {result}")
            results[s["id"]] = result
            records.append({
                "id": s["id"],
                "action": s["action"],
                "status": "COMPLETE",
                "elapsed_seconds": round(time.perf_counter() - step_started, 3),
                "result": result,
            })
    except Exception as exc:
        status = "FAILED"
        error = f"{type(exc).__name__}: {exc}"
        if rollback_on_failure:
            rollback_records = rollback_from_steps(records)
            if rollback_records:
                status = "FAILED_ROLLBACK_ATTEMPTED"

    receipt = {
        "version": 1,
        "execution_id": execution_id,
        "plan_id": plan_id,
        "template": plan["template"],
        "created_at": now_iso(),
        "status": status,
        "elapsed_seconds": round(time.perf_counter() - started, 3),
        "allow_mutations": allow_mutations,
        "allow_irreversible": allow_irreversible,
        "rollback_on_failure": rollback_on_failure,
        "error": error,
        "steps": records,
        "rollback": rollback_records,
    }
    receipt["receipt_hash"] = stable_hash(receipt)
    receipt_path = RECEIPT_ROOT / f"{execution_id}.json"
    receipt_path.write_text(json.dumps(receipt, indent=2, ensure_ascii=True), encoding="utf-8")

    summaries = [
        {"id": r["id"], "action": r["action"], "status": r["status"], "elapsed_seconds": r.get("elapsed_seconds"), "result": result_summary(r.get("result", {})) if r.get("result") else None}
        for r in records
    ]
    return {
        "ok": status == "COMPLETE",
        "command": "workflow_execute",
        "execution_id": execution_id,
        "plan_id": plan_id,
        "template": plan["template"],
        "status": status,
        "elapsed_seconds": receipt["elapsed_seconds"],
        "error": error,
        "steps": summaries,
        "rollback": rollback_records,
        "receipt_file": str(receipt_path),
    }

def load_receipt(execution_id: str) -> tuple[Path, dict[str, Any]]:
    path = RECEIPT_ROOT / f"{execution_id}.json"
    if not path.exists():
        raise WorkflowError(f"Workflow receipt not found: {execution_id}")
    receipt = json.loads(path.read_text(encoding="utf-8"))
    expected = receipt.get("receipt_hash")
    check = dict(receipt)
    check.pop("receipt_hash", None)
    if stable_hash(check) != expected:
        raise WorkflowError("Workflow receipt hash mismatch; receipt was modified")
    return path, receipt

def workflow_status(execution_id: str, include_results: bool) -> dict[str, Any]:
    _, receipt = load_receipt(execution_id)
    steps = []
    for r in receipt["steps"]:
        item = {
            "id": r["id"],
            "action": r["action"],
            "status": r["status"],
            "elapsed_seconds": r.get("elapsed_seconds"),
        }
        if include_results and r.get("result") is not None:
            item["result"] = r["result"]
        elif r.get("result") is not None:
            item["result"] = result_summary(r["result"])
        steps.append(item)
    return {
        "ok": True,
        "command": "workflow_status",
        "execution_id": execution_id,
        "plan_id": receipt["plan_id"],
        "template": receipt["template"],
        "status": receipt["status"],
        "elapsed_seconds": receipt["elapsed_seconds"],
        "error": receipt.get("error"),
        "steps": steps,
        "rollback": receipt.get("rollback", []),
    }

def workflow_rollback(execution_id: str) -> dict[str, Any]:
    path, receipt = load_receipt(execution_id)
    if receipt.get("manual_rollback"):
        raise WorkflowError("Workflow receipt already manually rolled back")
    rollbacks = rollback_from_steps(receipt["steps"])
    if not rollbacks:
        raise WorkflowError("Workflow has no reversible completed steps")
    receipt["manual_rollback"] = {
        "created_at": now_iso(),
        "steps": rollbacks,
    }
    check = dict(receipt)
    check.pop("receipt_hash", None)
    receipt["receipt_hash"] = stable_hash(check)
    path.write_text(json.dumps(receipt, indent=2, ensure_ascii=True), encoding="utf-8")
    return {
        "ok": all(x.get("ok", False) for x in rollbacks),
        "command": "workflow_rollback",
        "execution_id": execution_id,
        "rollback_count": len(rollbacks),
        "steps": rollbacks,
    }

def catalog() -> dict[str, Any]:
    return {
        "ok": True,
        "command": "workflow_catalog",
        "templates": [
            {"name": name, "description": spec["description"], "required": spec["required"]}
            for name, spec in TEMPLATES.items()
        ],
        "action_count": len(ACTION_CATALOG),
        "safety": {
            "arbitrary_shell": False,
            "plan_hash": True,
            "receipt_hash": True,
            "mutation_gate": "allow_mutations=true",
            "irreversible_gate": "allow_irreversible=true",
            "auto_rollback_on_failure": True,
            "duplicate_execution_guard": True,
        },
    }

def health() -> dict[str, Any]:
    ensure_roots()
    engines = {name: {"path": str(path), "exists": path.exists()} for name, path in ENGINES.items()}
    return {
        "ok": all(x["exists"] for x in engines.values()),
        "command": "workflow_engine_health",
        "version": "0.1.0-core",
        "plan_root": str(PLAN_ROOT),
        "receipt_root": str(RECEIPT_ROOT),
        "templates": sorted(TEMPLATES),
        "engines": engines,
        "arbitrary_shell": False,
        "mutation_gate": True,
        "irreversible_gate": True,
        "duplicate_execution_guard": True,
    }

def main() -> int:
    parser = argparse.ArgumentParser(prog="workflow-engine")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("health")
    sub.add_parser("catalog")

    p = sub.add_parser("plan")
    p.add_argument("template")
    p.add_argument("params_json")
    p.add_argument("--label", default="manual")

    p = sub.add_parser("execute")
    p.add_argument("plan_id")
    p.add_argument("--allow-mutations", action="store_true")
    p.add_argument("--allow-irreversible", action="store_true")
    p.add_argument("--no-rollback-on-failure", action="store_true")
    p.add_argument("--allow-reexecute", action="store_true")

    p = sub.add_parser("status")
    p.add_argument("execution_id")
    p.add_argument("--include-results", action="store_true")

    p = sub.add_parser("rollback")
    p.add_argument("execution_id")

    args = parser.parse_args()
    try:
        if args.command == "health":
            result = health()
        elif args.command == "catalog":
            result = catalog()
        elif args.command == "plan":
            params = json.loads(args.params_json)
            result = workflow_plan(args.template, params, args.label)
        elif args.command == "execute":
            result = workflow_execute(
                args.plan_id,
                args.allow_mutations,
                args.allow_irreversible,
                not args.no_rollback_on_failure,
                args.allow_reexecute,
            )
        elif args.command == "status":
            result = workflow_status(args.execution_id, args.include_results)
        elif args.command == "rollback":
            result = workflow_rollback(args.execution_id)
        else:
            raise WorkflowError("Unknown command")
        emit(result)
        return 0 if result.get("ok", False) else 2
    except Exception as exc:
        emit({"ok": False, "command": args.command, "error": type(exc).__name__, "message": str(exc)})
        return 1

if __name__ == "__main__":
    raise SystemExit(main())