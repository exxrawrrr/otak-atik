from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

import uvicorn
from fastmcp import FastMCP
from fastmcp.server.providers.proxy import ProxyClient, ProxyProvider
from windows_mcp.infrastructure.auth import AuthKeyMiddleware

RUNTIME_ROOT = Path(os.environ.get("REMOTE_GROWTH_ROOT", str(Path(__file__).resolve().parents[1])))
AUTH_FILE = Path(os.environ.get("REMOTE_GROWTH_AUTH_FILE", str(RUNTIME_ROOT / "auth.key")))

PYTHON = Path(os.environ.get("REMOTE_GROWTH_PYTHON", sys.executable))
LOCAL_ENGINE_PYTHON = PYTHON
LOCAL_ENGINE_SCRIPT = RUNTIME_ROOT / "FAST_LOCAL_ENGINE" / "local_engine.py"

DOCUMENT_ENGINE_PYTHON = PYTHON
DOCUMENT_ENGINE_SCRIPT = RUNTIME_ROOT / "DOCUMENT_ENGINE" / "document_engine.py"

DEVELOPER_ENGINE_PYTHON = PYTHON
DEVELOPER_ENGINE_SCRIPT = RUNTIME_ROOT / "DEVELOPER_ENGINE" / "developer_engine.py"

FILEOPS_ENGINE_PYTHON = PYTHON
FILEOPS_ENGINE_SCRIPT = RUNTIME_ROOT / "FILEOPS_ENGINE" / "fileops_engine.py"

SYSTEMOPS_ENGINE_PYTHON = PYTHON
SYSTEMOPS_ENGINE_SCRIPT = RUNTIME_ROOT / "SYSTEMOPS_ENGINE" / "systemops_engine.py"

WORKFLOW_ENGINE_PYTHON = PYTHON
WORKFLOW_ENGINE_SCRIPT = RUNTIME_ROOT / "WORKFLOW_ENGINE" / "workflow_engine.py"

ALLOWED_HOSTS = [
    item.strip()
    for item in os.environ.get("REMOTE_GROWTH_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
    if item.strip()
]

def read_auth_key() -> str:
    key = AUTH_FILE.read_text(encoding="utf-8").strip()
    if not key:
        raise RuntimeError("auth.key is empty")
    return key

def run_json_engine(
    python: Path,
    script: Path,
    args: list[str],
    timeout: int,
    label: str,
    allow_structured_failure: bool = False,
) -> dict:
    cmd = [str(python), str(script), *args]
    completed = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
    )
    stdout = completed.stdout.strip()
    result = None
    if stdout:
        try:
            result = json.loads(stdout.splitlines()[-1])
        except json.JSONDecodeError:
            result = None

    if completed.returncode != 0:
        if allow_structured_failure and isinstance(result, dict):
            return result
        if isinstance(result, dict):
            raise RuntimeError(f"{label} failed: {result}")
        raise RuntimeError(
            f"{label} failed rc={completed.returncode}: "
            f"{completed.stderr.strip()[-1000:] or stdout[-1000:]}"
        )

    if not isinstance(result, dict):
        raise RuntimeError(f"{label} returned invalid JSON: {stdout[-1000:]}")
    if not result.get("ok", False):
        if allow_structured_failure:
            return result
        raise RuntimeError(f"{label} returned ok=false: {result}")
    return result

def run_local(args: list[str], timeout: int = 30) -> dict:
    return run_json_engine(LOCAL_ENGINE_PYTHON, LOCAL_ENGINE_SCRIPT, args, timeout, "Fast Local Engine")

def run_document(args: list[str], timeout: int = 60) -> dict:
    return run_json_engine(DOCUMENT_ENGINE_PYTHON, DOCUMENT_ENGINE_SCRIPT, args, timeout, "Document Engine")

def run_developer(args: list[str], timeout: int = 60, allow_structured_failure: bool = False) -> dict:
    return run_json_engine(
        DEVELOPER_ENGINE_PYTHON,
        DEVELOPER_ENGINE_SCRIPT,
        args,
        timeout,
        "Developer Engine",
        allow_structured_failure=allow_structured_failure,
    )

def run_fileops(args: list[str], timeout: int = 120, allow_structured_failure: bool = False) -> dict:
    return run_json_engine(
        FILEOPS_ENGINE_PYTHON,
        FILEOPS_ENGINE_SCRIPT,
        args,
        timeout,
        "FileOps Engine",
        allow_structured_failure=allow_structured_failure,
    )

def run_systemops(args: list[str], timeout: int = 120, allow_structured_failure: bool = False) -> dict:
    return run_json_engine(
        SYSTEMOPS_ENGINE_PYTHON,
        SYSTEMOPS_ENGINE_SCRIPT,
        args,
        timeout,
        "SystemOps Engine",
        allow_structured_failure=allow_structured_failure,
    )

def run_workflow(args: list[str], timeout: int = 300, allow_structured_failure: bool = False) -> dict:
    return run_json_engine(
        WORKFLOW_ENGINE_PYTHON,
        WORKFLOW_ENGINE_SCRIPT,
        args,
        timeout,
        "Workflow Engine",
        allow_structured_failure=allow_structured_failure,
    )

def build_server(upstream_url: str, auth_key: str) -> FastMCP:
    mcp = FastMCP(
        "Remote GROWTH Stable",
        instructions=(
            "Remote Windows operator with existing windows-mcp primitives, "
            "fast local file/workspace search, safe local document tools, "
            "bounded Developer/Git tools, safe transactional file/workspace operations, protected Windows system/process/network operations, and high-level safe workflow orchestration."
        ),
        version="0.7.0",
    )

    proxy = ProxyProvider(
        lambda: ProxyClient(upstream_url, auth=auth_key),
        cache_ttl=30,
    )
    mcp.add_provider(proxy)

    @mcp.tool
    def local_search(query: str, limit: int = 20) -> dict:
        """Fast indexed search across hot local roots using filename, path, and indexed text."""
        limit = max(1, min(int(limit), 50))
        return run_local(["search", query, "--limit", str(limit)], timeout=20)

    @mcp.tool
    def file_find(query: str, limit: int = 20) -> dict:
        """Find likely local files quickly, prioritizing filename/path relevance."""
        limit = max(1, min(int(limit), 50))
        return run_local(["file-find", query, "--limit", str(limit)], timeout=20)

    @mcp.tool
    def workspace_find(query: str, limit: int = 20) -> dict:
        """Find indexed code/project workspaces by name, path, and project markers."""
        limit = max(1, min(int(limit), 50))
        return run_local(["workspace-find", query, "--limit", str(limit)], timeout=20)

    @mcp.tool
    def workspace_summary(path: str) -> dict:
        """Return a bounded indexed summary of a local workspace/project path."""
        return run_local(["workspace-summary", path], timeout=20)

    @mcp.tool
    def local_index_health() -> dict:
        """Return Fast Local Engine database, index, workspace, and refresh state."""
        return run_local(["health"], timeout=20)

    @mcp.tool
    def local_index_refresh() -> dict:
        """Incrementally refresh the Fast Local Engine hot index. No files are modified."""
        return run_local(["index"], timeout=180)

    @mcp.tool
    def document_engine_health() -> dict:
        """Return supported document formats, safe edit rules, dependency versions, and backup location."""
        return run_document(["health"], timeout=20)

    @mcp.tool
    def document_inspect(path: str) -> dict:
        """Inspect a local document: type, hash, size, sheets/pages/slides/tables, text counts, and editability."""
        return run_document(["inspect", path], timeout=60)

    @mcp.tool
    def document_extract(
        path: str,
        max_chars: int = 30000,
        page: int | None = None,
        sheet: str | None = None,
        slide: int | None = None,
    ) -> dict:
        """Extract bounded text from a local document, optionally scoped to one PDF page, Excel sheet, or PowerPoint slide."""
        max_chars = max(1000, min(int(max_chars), 200000))
        args = ["extract", path, "--max-chars", str(max_chars)]
        if page is not None:
            args += ["--page", str(int(page))]
        if sheet:
            args += ["--sheet", sheet]
        if slide is not None:
            args += ["--slide", str(int(slide))]
        return run_document(args, timeout=90)

    @mcp.tool
    def document_search(path: str, query: str, limit: int = 20, context_chars: int = 120) -> dict:
        """Search inside one local document and return bounded contextual matches with page/sheet/slide/row metadata."""
        limit = max(1, min(int(limit), 100))
        context_chars = max(20, min(int(context_chars), 1000))
        return run_document(
            ["search", path, query, "--limit", str(limit), "--context-chars", str(context_chars)],
            timeout=90,
        )

    @mcp.tool
    def document_compare(path_a: str, path_b: str, max_diff_lines: int = 80) -> dict:
        """Compare two supported local documents by extracted text and hashes, returning a bounded unified diff."""
        max_diff_lines = max(10, min(int(max_diff_lines), 500))
        return run_document(
            ["compare", path_a, path_b, "--max-diff-lines", str(max_diff_lines)],
            timeout=120,
        )

    @mcp.tool
    def document_replace(
        path: str,
        replacements: list[dict[str, str]],
        output_path: str | None = None,
        include_formulas: bool = False,
    ) -> dict:
        """Safely replace exact text in supported editable documents. In-place edits create a backup first. PDF/XLS edits are rejected."""
        if not replacements:
            raise ValueError("replacements must not be empty")
        payload = json.dumps(replacements, ensure_ascii=True)
        args = ["replace", path, payload]
        if output_path:
            args += ["--output", output_path]
        if include_formulas:
            args += ["--include-formulas"]
        return run_document(args, timeout=180)

    @mcp.tool
    def developer_engine_health() -> dict:
        """Return local Git/developer binary availability and safe checkpoint semantics."""
        return run_developer(["health"], timeout=20)

    @mcp.tool
    def repo_find(query: str, limit: int = 20) -> dict:
        """Find local Git repositories quickly from the persistent workspace index without recursively scanning drives."""
        limit = max(1, min(int(limit), 50))
        return run_developer(["repo-find", query, "--limit", str(limit)], timeout=20)

    @mcp.tool
    def repo_status(path: str) -> dict:
        """Return branch, upstream, ahead/behind, cleanliness, staged, unstaged, and untracked state for a local Git repository."""
        return run_developer(["repo-status", path], timeout=30)

    @mcp.tool
    def repo_summary(path: str) -> dict:
        """Summarize a local Git repository: status, redacted remotes, tracked files, stack markers, scripts, and recent commits."""
        return run_developer(["repo-summary", path], timeout=45)

    @mcp.tool
    def repo_search(path: str, query: str, limit: int = 50, regex: bool = False) -> dict:
        """Search tracked repository content with bounded git-grep results. Literal search is the default."""
        limit = max(1, min(int(limit), 200))
        args = ["repo-search", path, query, "--limit", str(limit)]
        if regex:
            args.append("--regex")
        return run_developer(args, timeout=45)

    @mcp.tool
    def repo_diff(path: str, mode: str = "all", max_chars: int = 30000) -> dict:
        """Return bounded staged/unstaged Git diff plus untracked-file names. mode: all, staged, or unstaged."""
        if mode not in {"all", "staged", "unstaged"}:
            raise ValueError("mode must be all, staged, or unstaged")
        max_chars = max(2000, min(int(max_chars), 100000))
        return run_developer(["repo-diff", path, "--mode", mode, "--max-chars", str(max_chars)], timeout=60)

    @mcp.tool
    def repo_checkpoint(path: str, label: str = "manual", include_untracked: bool = True) -> dict:
        """Create a local Git checkpoint branch without switching branches or changing the user's working tree/index. Secret-like files fail closed. Nothing is pushed."""
        args = ["repo-checkpoint", path, "--label", label]
        if not include_untracked:
            args.append("--no-untracked")
        return run_developer(args, timeout=120, allow_structured_failure=True)

    @mcp.tool
    def code_run_check(path: str, task: str, timeout: int = 180) -> dict:
        """Run one repository-declared quality task: lint, typecheck, test, build, verify, or format-check."""
        if task not in {"lint", "typecheck", "test", "build", "verify", "format-check"}:
            raise ValueError("unsupported task")
        timeout = max(10, min(int(timeout), 900))
        return run_developer(["code-run-check", path, task, "--timeout", str(timeout)], timeout=timeout + 15)

    @mcp.tool
    def code_quality(path: str, execute: bool = False, timeout_per_task: int = 180) -> dict:
        """Plan or execute the conservative repository quality suite: lint, typecheck, test, build. Stops after the first failing executed task."""
        timeout_per_task = max(10, min(int(timeout_per_task), 900))
        args = ["code-quality", path, "--timeout-per-task", str(timeout_per_task)]
        if execute:
            args.append("--execute")
        total_timeout = 30 if not execute else min(3700, timeout_per_task * 4 + 30)
        return run_developer(args, timeout=total_timeout)


    @mcp.tool
    def fileops_health() -> dict:
        """Return FileOps allowed/protected roots, quarantine locations, and transaction semantics."""
        return run_fileops(["health"], timeout=20)

    @mcp.tool
    def storage_analyze(path: str, depth: int = 2, top_n: int = 30) -> dict:
        """Analyze local storage usage under an allowed root with bounded depth and result count."""
        depth = max(1, min(int(depth), 4))
        top_n = max(1, min(int(top_n), 200))
        return run_fileops(["storage-analyze", path, "--depth", str(depth), "--top-n", str(top_n)], timeout=180)

    @mcp.tool
    def duplicate_find(path: str, min_size: int = 1048576, limit_groups: int = 50) -> dict:
        """Find exact duplicate files by size then SHA-256; read-only and bounded."""
        min_size = max(1, int(min_size))
        limit_groups = max(1, min(int(limit_groups), 200))
        return run_fileops(["duplicates", path, "--min-size", str(min_size), "--limit-groups", str(limit_groups)], timeout=300)

    @mcp.tool
    def hash_manifest(path: str, include_sha256: bool = True, max_entries: int = 10000) -> dict:
        """Build a bounded file manifest with sizes/mtimes and optional SHA-256 hashes."""
        max_entries = max(1, min(int(max_entries), 100000))
        args = ["hash-manifest", path, "--max-entries", str(max_entries)]
        if not include_sha256:
            args.append("--no-sha256")
        return run_fileops(args, timeout=300)

    @mcp.tool
    def archive_create(paths: list[str], output_path: str) -> dict:
        """Create and verify a ZIP archive from allowed local files/directories. Existing output is never overwritten."""
        if not paths:
            raise ValueError("paths must not be empty")
        return run_fileops(
            ["archive-create", output_path, json.dumps(paths, ensure_ascii=True)],
            timeout=600,
        )

    @mcp.tool
    def archive_extract(archive_path: str, destination_path: str) -> dict:
        """Safely extract a ZIP to a new destination with zip-slip/path-traversal protection."""
        return run_fileops(["archive-extract", archive_path, destination_path], timeout=600)

    @mcp.tool
    def file_batch_plan(operations: list[dict[str, str]], label: str = "manual") -> dict:
        """Validate and persist a safe batch plan. Supported ops: copy, move, rename, delete-to-quarantine, mkdir."""
        if not operations:
            raise ValueError("operations must not be empty")
        return run_fileops(
            ["batch-plan", json.dumps(operations, ensure_ascii=True), "--label", label],
            timeout=60,
            allow_structured_failure=True,
        )

    @mcp.tool
    def file_batch_execute(plan_id: str) -> dict:
        """Execute a previously validated batch plan, verify each operation, and write a rollback receipt."""
        return run_fileops(["batch-execute", plan_id], timeout=1800, allow_structured_failure=True)

    @mcp.tool
    def file_operation_rollback(receipt_id: str) -> dict:
        """Rollback a FileOps receipt in reverse order. Refuses rollback if executed results changed afterward."""
        return run_fileops(["rollback", receipt_id], timeout=1800, allow_structured_failure=True)

    @mcp.tool
    def workspace_backup(path: str, label: str = "manual") -> dict:
        """Create a verified ZIP workspace backup plus SHA-256 manifest under the dedicated D-drive backup root."""
        return run_fileops(["workspace-backup", path, "--label", label], timeout=1800)


    @mcp.tool
    def systemops_health() -> dict:
        """Return SystemOps protection rules, supported planned actions, and receipt locations."""
        return run_systemops(["health"], timeout=20)

    @mcp.tool
    def system_health() -> dict:
        """Return Windows health summary: uptime, CPU load, memory, disks, process/service/listener counts, and top memory processes."""
        return run_systemops(["system-health"], timeout=45)

    @mcp.tool
    def process_inspect(query: str | None = None, pid: int | None = None, limit: int = 30) -> dict:
        """Inspect Windows processes by exact PID or name/path/command-line query, including Remote GROWTH protection status."""
        limit = max(1, min(int(limit), 100))
        args = ["process-inspect", "--limit", str(limit)]
        if pid is not None:
            args += ["--pid", str(int(pid))]
        elif query:
            args += ["--query", query]
        return run_systemops(args, timeout=60)

    @mcp.tool
    def port_inspect(port: int | None = None, pid: int | None = None, limit: int = 50) -> dict:
        """Inspect TCP connections/listeners by local port or owning PID with process ownership context."""
        limit = max(1, min(int(limit), 200))
        args = ["port-inspect", "--limit", str(limit)]
        if port is not None:
            args += ["--port", str(int(port))]
        if pid is not None:
            args += ["--pid", str(int(pid))]
        return run_systemops(args, timeout=60)

    @mcp.tool
    def service_inspect(query: str | None = None, limit: int = 50) -> dict:
        """Inspect Windows services, start modes, process IDs, and protected-service status."""
        limit = max(1, min(int(limit), 200))
        args = ["service-inspect", "--limit", str(limit)]
        if query:
            args += ["--query", query]
        return run_systemops(args, timeout=60)

    @mcp.tool
    def network_inspect() -> dict:
        """Inspect network adapters, IP configuration, DNS servers, and default IPv4 routes without changing configuration."""
        return run_systemops(["network-inspect"], timeout=60)

    @mcp.tool
    def tailscale_inspect() -> dict:
        """Inspect Tailscale service/backend state, local Tailscale addresses, DNS name, and Funnel configuration."""
        return run_systemops(["tailscale-inspect"], timeout=45)

    @mcp.tool
    def scheduled_task_inspect(query: str | None = None, limit: int = 50) -> dict:
        """Inspect scheduled tasks, run status, actions, and whether a task is protected from mutation."""
        limit = max(1, min(int(limit), 200))
        args = ["scheduled-task-inspect", "--limit", str(limit)]
        if query:
            args += ["--query", query]
        return run_systemops(args, timeout=90)

    @mcp.tool
    def startup_inspect() -> dict:
        """Inspect user/common Startup folders and Windows Run registry entries without changing them."""
        return run_systemops(["startup-inspect"], timeout=45)

    @mcp.tool
    def system_action_plan(action: str, target: dict, label: str = "manual") -> dict:
        """Create an integrity-hashed system action plan. Supported actions are bounded; protected Remote GROWTH/Tailscale targets fail closed."""
        payload = json.dumps(target, ensure_ascii=True)
        return run_systemops(
            ["action-plan", action, payload, "--label", label],
            timeout=90,
            allow_structured_failure=True,
        )

    @mcp.tool
    def system_action_execute(plan_id: str, allow_irreversible: bool = False) -> dict:
        """Execute a saved system action plan after rechecking preconditions. Irreversible actions require explicit allow_irreversible=true."""
        args = ["action-execute", plan_id]
        if allow_irreversible:
            args.append("--allow-irreversible")
        return run_systemops(args, timeout=180, allow_structured_failure=True)

    @mcp.tool
    def system_action_rollback(receipt_id: str) -> dict:
        """Rollback a reversible SystemOps receipt using a new verified action plan. Irreversible actions have no rollback."""
        return run_systemops(["action-rollback", receipt_id], timeout=180, allow_structured_failure=True)


    @mcp.tool
    def workflow_engine_health() -> dict:
        """Return workflow engine health, trusted engine paths, safety gates, and available templates."""
        return run_workflow(["health"], timeout=30)

    @mcp.tool
    def workflow_catalog() -> dict:
        """List high-level workflow templates and orchestration safety semantics."""
        return run_workflow(["catalog"], timeout=30)

    @mcp.tool
    def workflow_plan(template: str, params: dict, label: str = "manual") -> dict:
        """Create an integrity-hashed high-level workflow plan from a safe built-in template. Arbitrary shell steps are not accepted."""
        return run_workflow(
            ["plan", template, json.dumps(params, ensure_ascii=True), "--label", label],
            timeout=60,
            allow_structured_failure=True,
        )

    @mcp.tool
    def workflow_execute(
        plan_id: str,
        allow_mutations: bool = False,
        allow_irreversible: bool = False,
        rollback_on_failure: bool = True,
        allow_reexecute: bool = False,
    ) -> dict:
        """Execute a saved workflow plan with dependency checks, mutation/irreversible gates, receipts, and optional automatic rollback on failure."""
        args = ["execute", plan_id]
        if allow_mutations:
            args.append("--allow-mutations")
        if allow_irreversible:
            args.append("--allow-irreversible")
        if not rollback_on_failure:
            args.append("--no-rollback-on-failure")
        if allow_reexecute:
            args.append("--allow-reexecute")
        return run_workflow(args, timeout=3600, allow_structured_failure=True)

    @mcp.tool
    def workflow_status(execution_id: str, include_results: bool = False) -> dict:
        """Read a workflow execution receipt with per-step status and bounded result summaries."""
        args = ["status", execution_id]
        if include_results:
            args.append("--include-results")
        return run_workflow(args, timeout=60, allow_structured_failure=True)

    @mcp.tool
    def workflow_rollback(execution_id: str) -> dict:
        """Rollback completed reversible workflow steps in reverse order using underlying FileOps/SystemOps receipts."""
        return run_workflow(["rollback", execution_id], timeout=1800, allow_structured_failure=True)

    return mcp

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--upstream-port", type=int, required=True)
    parser.add_argument("--no-auth", action="store_true")
    args = parser.parse_args()

    auth_key = read_auth_key()
    upstream_url = f"http://127.0.0.1:{args.upstream_port}/mcp"
    mcp = build_server(upstream_url, auth_key)

    app = mcp.http_app(
        path="/mcp",
        stateless_http=True,
        allowed_hosts=ALLOWED_HOSTS,
    )
    if not args.no_auth:
        app = AuthKeyMiddleware(app, auth_key=auth_key)

    uvicorn.run(
        app,
        host=args.host,
        port=args.port,
        log_level="warning",
        access_log=False,
    )

if __name__ == "__main__":
    main()