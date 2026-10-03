from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

PROD_ROOT = Path(__file__).resolve().parent
PLAN_ROOT = PROD_ROOT / "plans"
RECEIPT_ROOT = PROD_ROOT / "receipts"
TAILSCALE_EXE = Path(os.environ.get("REMOTE_GROWTH_TAILSCALE_EXE", r"C:\Program Files\Tailscale\tailscale.exe"))

PROTECTED_SERVICES = {
    "tailscale", "rpcss", "dcomlaunch", "eventlog", "winmgmt",
    "dhcp", "dnscache", "nlasvc", "wlanSvc".lower(), "lanmanworkstation",
}
PROTECTED_PROCESS_NAMES = {
    "system", "registry", "smss.exe", "csrss.exe", "wininit.exe", "services.exe",
    "lsass.exe", "winlogon.exe", "dwm.exe", "svchost.exe", "tailscaled.exe",
    "tailscale-ipn.exe",
}
PROTECTED_CMD_PATTERNS = [
    re.compile(r"(?i)remote-growth-stable.*supervisor\.ps1"),
    re.compile(r"(?i)RafdiRemoteMCP\\supervisor\.ps1"),
    re.compile(r"(?i)MCP_GATEWAY\\gateway\.py"),
    re.compile(r"(?i)windows-mcp.*--port\s+18766"),
    re.compile(r"(?i)NATIVE_CHATGPT\\native_facade\.py"),
    re.compile(r"(?i)TUNNEL_CLIENT\\tunnel-client\.exe"),
    re.compile(r"(?i)TUNNEL_CLIENT\\run-native-tunnel\.ps1"),
]
REMOTE_PORTS = {18765, 18766, 18768, 18769}
IRREVERSIBLE_ACTIONS = {"terminate_process", "restart_service", "run_task", "flush_dns"}
SUPPORTED_ACTIONS = {
    "terminate_process",
    "start_service",
    "stop_service",
    "restart_service",
    "enable_task",
    "disable_task",
    "run_task",
    "flush_dns",
}

class EngineError(Exception):
    pass

def emit(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, ensure_ascii=True, default=str))

def now_iso() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")

def canonical_hash(obj: Any) -> str:
    raw = json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()

def ps(script: str, timeout: int = 30) -> dict[str, Any]:
    started = time.perf_counter()
    cp = subprocess.run(
        ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command", script],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
        env={**os.environ, "NO_COLOR": "1"},
    )
    return {
        "exit_code": cp.returncode,
        "stdout": cp.stdout.strip(),
        "stderr": cp.stderr.strip(),
        "elapsed_seconds": round(time.perf_counter() - started, 3),
    }

def ps_json(script: str, timeout: int = 30) -> Any:
    wrapped = (
        "$ErrorActionPreference='Stop';"
        "[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false);"
        + script
    )
    result = ps(wrapped, timeout=timeout)
    if result["exit_code"] != 0:
        raise EngineError(result["stderr"] or result["stdout"] or f"PowerShell rc={result['exit_code']}")
    text = result["stdout"].strip()
    if not text:
        return None
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        raise EngineError(f"Invalid PowerShell JSON: {text[-2000:]}") from exc

def q(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"

def process_record(pid: int) -> dict[str, Any] | None:
    script = f"""
$p=Get-CimInstance Win32_Process -Filter "ProcessId={int(pid)}" -ErrorAction SilentlyContinue
if(-not $p){{ @{{exists=$false}} | ConvertTo-Json -Compress; exit 0 }}
@{{
 exists=$true
 pid=[int]$p.ProcessId
 ppid=[int]$p.ParentProcessId
 name=[string]$p.Name
 executable=[string]$p.ExecutablePath
 command_line=[string]$p.CommandLine
 creation_date=if($p.CreationDate){{$p.CreationDate.ToString('o')}}else{{$null}}
}} | ConvertTo-Json -Compress
"""
    obj = ps_json(script, timeout=15)
    return obj if obj and obj.get("exists") else None

def protected_pids() -> set[int]:
    pids: set[int] = set()
    script = r"""
$ports=@(18765,18766,18768,18769)
$result=@()
foreach($port in $ports){
  Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
    $result += [int]$_.OwningProcess
  }
}
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
  ([string]$_.CommandLine) -like '*RafdiRemoteMCP\supervisor.ps1*' -or
  ([string]$_.CommandLine) -like '*MCP_GATEWAY\gateway.py*' -or
  (([string]$_.CommandLine) -like '*windows-mcp*' -and ([string]$_.CommandLine) -like '*--port 18766*') -or
  ([string]$_.CommandLine) -like '*NATIVE_CHATGPT\native_facade.py*' -or
  ([string]$_.CommandLine) -like '*TUNNEL_CLIENT\tunnel-client.exe*' -or
  ([string]$_.CommandLine) -like '*TUNNEL_CLIENT\run-native-tunnel.ps1*'
} | ForEach-Object { $result += [int]$_.ProcessId }
$result | Sort-Object -Unique | ConvertTo-Json -Compress
"""
    obj = ps_json(script, timeout=20)
    if obj is None:
        return pids
    if isinstance(obj, int):
        return {obj}
    return {int(x) for x in obj}

def is_process_protected(rec: dict[str, Any], protected_set: set[int] | None = None) -> tuple[bool, str | None]:
    if protected_set is None:
        protected_set = protected_pids()
    if int(rec["pid"]) in protected_set:
        return True, "Remote GROWTH Stable runtime/port owner"
    name = str(rec.get("name") or "").lower()
    if name in PROTECTED_PROCESS_NAMES:
        return True, "protected Windows/Tailscale process name"
    cmd = str(rec.get("command_line") or "")
    for pattern in PROTECTED_CMD_PATTERNS:
        if pattern.search(cmd):
            return True, "protected Remote GROWTH Stable command line"
    return False, None

def system_health() -> dict[str, Any]:
    script = """
$os=Get-CimInstance Win32_OperatingSystem
$cs=Get-CimInstance Win32_ComputerSystem
$cpu=Get-CimInstance Win32_Processor | Select-Object -First 1
$disks=Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
  [pscustomobject]@{
    drive=$_.DeviceID
    size_bytes=[int64]$_.Size
    free_bytes=[int64]$_.FreeSpace
    free_percent=if($_.Size){[math]::Round(100*$_.FreeSpace/$_.Size,2)}else{$null}
  }
}
$top=Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 | ForEach-Object {
 [pscustomobject]@{pid=$_.Id;name=$_.ProcessName;working_set_bytes=[int64]$_.WorkingSet64;cpu_seconds=$_.CPU}
}
[pscustomobject]@{
 computer=$env:COMPUTERNAME
 os=$os.Caption
 version=$os.Version
 build=$os.BuildNumber
 last_boot=$os.LastBootUpTime.ToString('o')
 uptime_seconds=[int]((Get-Date)-$os.LastBootUpTime).TotalSeconds
 total_memory_bytes=[int64]$cs.TotalPhysicalMemory
 free_memory_bytes=[int64]($os.FreePhysicalMemory*1KB)
 cpu_name=$cpu.Name
 cpu_load_percent=$cpu.LoadPercentage
 disks=@($disks)
 process_count=@(Get-Process).Count
 service_running=@(Get-Service | Where-Object Status -eq Running).Count
 service_total=@(Get-Service).Count
 listeners=@(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue).Count
 top_memory=@($top)
} | ConvertTo-Json -Depth 5 -Compress
"""
    return {"ok": True, "command": "system_health", "data": ps_json(script, timeout=25)}

def process_inspect(query: str | None, pid: int | None, limit: int) -> dict[str, Any]:
    limit = max(1, min(limit, 100))
    if pid is not None:
        rec = process_record(pid)
        if not rec:
            return {"ok": True, "command": "process_inspect", "count": 0, "results": []}
        protected, reason = is_process_protected(rec)
        rec["protected"] = protected
        rec["protected_reason"] = reason
        return {"ok": True, "command": "process_inspect", "count": 1, "results": [rec]}

    needle = (query or "").lower()
    script = f"""
$items=Get-CimInstance Win32_Process | ForEach-Object {{
  [pscustomobject]@{{
    pid=[int]$_.ProcessId
    ppid=[int]$_.ParentProcessId
    name=[string]$_.Name
    executable=[string]$_.ExecutablePath
    command_line=[string]$_.CommandLine
    creation_date=if($_.CreationDate){{$_.CreationDate.ToString('o')}}else{{$null}}
  }}
}}
$items | Where-Object {{
  {q(needle)} -eq '' -or
  ([string]$_.name).ToLower().Contains({q(needle)}) -or
  ([string]$_.executable).ToLower().Contains({q(needle)}) -or
  ([string]$_.command_line).ToLower().Contains({q(needle)})
}} | Select-Object -First {limit} | ConvertTo-Json -Depth 4 -Compress
"""
    obj = ps_json(script, timeout=20)
    rows = [] if obj is None else ([obj] if isinstance(obj, dict) else obj)
    protected_set = protected_pids()
    for rec in rows:
        protected, reason = is_process_protected(rec, protected_set)
        rec["protected"] = protected
        rec["protected_reason"] = reason
    return {"ok": True, "command": "process_inspect", "query": query, "count": len(rows), "results": rows}

def port_inspect(port: int | None, pid: int | None, limit: int) -> dict[str, Any]:
    limit = max(1, min(limit, 200))
    clauses = []
    if port is not None:
        clauses.append(f"$_.LocalPort -eq {int(port)}")
    if pid is not None:
        clauses.append(f"$_.OwningProcess -eq {int(pid)}")
    where = " -and ".join(clauses) if clauses else "$true"
    script = f"""
$items=Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object {{ {where} }} | Sort-Object State,LocalPort | Select-Object -First {limit}
$out=@()
foreach($x in $items){{
 $p=Get-CimInstance Win32_Process -Filter "ProcessId=$($x.OwningProcess)" -ErrorAction SilentlyContinue
 $out += [pscustomobject]@{{
  local_address=$x.LocalAddress
  local_port=[int]$x.LocalPort
  remote_address=$x.RemoteAddress
  remote_port=[int]$x.RemotePort
  state=[string]$x.State
  pid=[int]$x.OwningProcess
  process_name=if($p){{$p.Name}}else{{$null}}
  command_line=if($p){{$p.CommandLine}}else{{$null}}
 }}
}}
$out | ConvertTo-Json -Depth 4 -Compress
"""
    obj = ps_json(script, timeout=25)
    rows = [] if obj is None else ([obj] if isinstance(obj, dict) else obj)
    for rec in rows:
        rec["remote_growth_port"] = int(rec["local_port"]) in REMOTE_PORTS
    return {"ok": True, "command": "port_inspect", "port": port, "pid": pid, "count": len(rows), "results": rows}

def service_inspect(query: str | None, limit: int) -> dict[str, Any]:
    limit = max(1, min(limit, 200))
    needle = (query or "").lower()
    script = f"""
$items=Get-CimInstance Win32_Service | Where-Object {{
 {q(needle)} -eq '' -or
 ([string]$_.Name).ToLower().Contains({q(needle)}) -or
 ([string]$_.DisplayName).ToLower().Contains({q(needle)})
}} | Select-Object -First {limit} | ForEach-Object {{
 [pscustomobject]@{{
  name=$_.Name
  display_name=$_.DisplayName
  state=$_.State
  start_mode=$_.StartMode
  process_id=[int]$_.ProcessId
  path_name=$_.PathName
 }}
}}
$items | ConvertTo-Json -Depth 4 -Compress
"""
    obj = ps_json(script, timeout=20)
    rows = [] if obj is None else ([obj] if isinstance(obj, dict) else obj)
    for rec in rows:
        protected = str(rec["name"]).lower() in PROTECTED_SERVICES
        rec["protected"] = protected
        rec["protected_reason"] = "protected connectivity/system service" if protected else None
    return {"ok": True, "command": "service_inspect", "query": query, "count": len(rows), "results": rows}

def network_inspect() -> dict[str, Any]:
    script = """
$adapters=Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {
 [pscustomobject]@{
  name=$_.Name;interface_description=$_.InterfaceDescription;status=$_.Status
  link_speed=$_.LinkSpeed;mac_address=$_.MacAddress;if_index=$_.ifIndex
 }}
$ips=Get-NetIPConfiguration -ErrorAction SilentlyContinue | ForEach-Object {
 [pscustomobject]@{
  interface_alias=$_.InterfaceAlias
  ipv4=@($_.IPv4Address | ForEach-Object {$_.IPAddress})
  ipv6=@($_.IPv6Address | ForEach-Object {$_.IPAddress})
  gateway=@($_.IPv4DefaultGateway | ForEach-Object {$_.NextHop})
  dns=@($_.DNSServer.ServerAddresses)
 }}
$routes=Get-NetRoute -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {$_.DestinationPrefix -eq '0.0.0.0/0'} | ForEach-Object {
 [pscustomobject]@{interface_alias=$_.InterfaceAlias;next_hop=$_.NextHop;route_metric=$_.RouteMetric;if_metric=$_.InterfaceMetric}
}
[pscustomobject]@{adapters=@($adapters);ip_config=@($ips);default_routes=@($routes)} | ConvertTo-Json -Depth 6 -Compress
"""
    return {"ok": True, "command": "network_inspect", "data": ps_json(script, timeout=25)}

def tailscale_inspect() -> dict[str, Any]:
    script = f"""
$svc=Get-CimInstance Win32_Service -Filter "Name='Tailscale'"
$status=$null
$funnel=$null
if(Test-Path {q(str(TAILSCALE_EXE))}){{
  $raw=& {q(str(TAILSCALE_EXE))} status --json 2>$null
  try{{$status=($raw -join [Environment]::NewLine)|ConvertFrom-Json}}catch{{}}
  $funnel=(& {q(str(TAILSCALE_EXE))} funnel status 2>&1 | Out-String).Trim()
}}
[pscustomobject]@{{
 service=[pscustomobject]@{{state=$svc.State;start_mode=$svc.StartMode;process_id=[int]$svc.ProcessId}}
 backend_state=if($status){{$status.BackendState}}else{{$null}}
 self_dns_name=if($status -and $status.Self){{$status.Self.DNSName}}else{{$null}}
 self_tailscale_ips=if($status -and $status.Self){{@($status.Self.TailscaleIPs)}}else{{@()}}
 funnel=$funnel
}} | ConvertTo-Json -Depth 6 -Compress
"""
    return {"ok": True, "command": "tailscale_inspect", "data": ps_json(script, timeout=25)}

def scheduled_task_inspect(query: str | None, limit: int) -> dict[str, Any]:
    limit = max(1, min(limit, 200))
    needle = (query or "").lower()
    script = f"""
$tasks=Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {{
 {q(needle)} -eq '' -or
 ([string]$_.TaskName).ToLower().Contains({q(needle)}) -or
 ([string]$_.TaskPath).ToLower().Contains({q(needle)})
}} | Select-Object -First {limit}
$out=@()
foreach($t in $tasks){{
 $info=Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue
 $out += [pscustomobject]@{{
  task_name=$t.TaskName
  task_path=$t.TaskPath
  state=[string]$t.State
  enabled=[bool]$t.Settings.Enabled
  last_run=if($info -and $info.LastRunTime -gt [datetime]'1901-01-01'){{$info.LastRunTime.ToString('o')}}else{{$null}}
  next_run=if($info -and $info.NextRunTime -gt [datetime]'1901-01-01'){{$info.NextRunTime.ToString('o')}}else{{$null}}
  last_result=if($info){{$info.LastTaskResult}}else{{$null}}
  actions=@($t.Actions | ForEach-Object {{[pscustomobject]@{{execute=$_.Execute;arguments=$_.Arguments;working_directory=$_.WorkingDirectory}}}})
 }}
}}
$out | ConvertTo-Json -Depth 6 -Compress
"""
    obj = ps_json(script, timeout=30)
    rows = [] if obj is None else ([obj] if isinstance(obj, dict) else obj)
    for rec in rows:
        microsoft = str(rec["task_path"]).lower().startswith("\\microsoft\\windows\\")
        action_text = " ".join(str(x) for x in rec.get("actions", []))
        remote = bool(re.search(r"(?i)RafdiRemoteMCP|MCP_GATEWAY|windows-mcp|tailscale|Remote GROWTH", action_text + " " + str(rec.get("task_name", ""))))
        rec["protected"] = microsoft or remote
        rec["protected_reason"] = "Microsoft Windows task" if microsoft else ("Remote GROWTH/Tailscale task" if remote else None)
    return {"ok": True, "command": "scheduled_task_inspect", "query": query, "count": len(rows), "results": rows}

def startup_inspect() -> dict[str, Any]:
    script = r"""
$startup=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
$common=[Environment]::GetFolderPath('CommonStartup')
$files=@()
foreach($dir in @($startup,$common)){
 if($dir -and (Test-Path $dir)){
  $files += Get-ChildItem $dir -Force -ErrorAction SilentlyContinue | ForEach-Object {
   [pscustomobject]@{scope=if($dir -eq $startup){'user'}else{'common'};name=$_.Name;path=$_.FullName;length=if($_.PSIsContainer){$null}else{$_.Length}}
  }
 }
}
$runKeys=@()
foreach($spec in @(
 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'
)){
 if(Test-Path $spec){
  $props=Get-ItemProperty $spec
  foreach($p in $props.PSObject.Properties | Where-Object {$_.Name -notmatch '^PS'}){
   $runKeys += [pscustomobject]@{registry_path=$spec;name=$p.Name;command=[string]$p.Value}
  }
 }
}
[pscustomobject]@{startup_files=@($files);run_keys=@($runKeys)} | ConvertTo-Json -Depth 5 -Compress
"""
    return {"ok": True, "command": "startup_inspect", "data": ps_json(script, timeout=20)}

def exact_service(name: str) -> dict[str, Any] | None:
    safe_name = name.replace("'", "''")
    script = f"""
 $s=Get-CimInstance Win32_Service -Filter "Name='{safe_name}'" -ErrorAction SilentlyContinue
if(-not $s){{ $null | ConvertTo-Json -Compress; exit 0 }}
[pscustomobject]@{{
 name=$s.Name
 display_name=$s.DisplayName
 state=$s.State
 start_mode=$s.StartMode
 process_id=[int]$s.ProcessId
 path_name=$s.PathName
}} | ConvertTo-Json -Compress
"""
    obj = ps_json(script, timeout=15)
    if not obj:
        return None
    obj["protected"] = str(obj["name"]).lower() in PROTECTED_SERVICES
    obj["protected_reason"] = "protected connectivity/system service" if obj["protected"] else None
    return obj

def exact_task(task_path: str, task_name: str) -> dict[str, Any] | None:
    script = f"""
$t=Get-ScheduledTask -TaskName {q(task_name)} -TaskPath {q(task_path)} -ErrorAction SilentlyContinue
if(-not $t){{ $null | ConvertTo-Json -Compress; exit 0 }}
$info=Get-ScheduledTaskInfo -TaskName {q(task_name)} -TaskPath {q(task_path)} -ErrorAction SilentlyContinue
[pscustomobject]@{{
 task_name=$t.TaskName
 task_path=$t.TaskPath
 state=[string]$t.State
 enabled=[bool]$t.Settings.Enabled
 last_run=if($info -and $info.LastRunTime -gt [datetime]'1901-01-01'){{$info.LastRunTime.ToString('o')}}else{{$null}}
 next_run=if($info -and $info.NextRunTime -gt [datetime]'1901-01-01'){{$info.NextRunTime.ToString('o')}}else{{$null}}
 last_result=if($info){{$info.LastTaskResult}}else{{$null}}
 actions=@($t.Actions | ForEach-Object {{[pscustomobject]@{{execute=$_.Execute;arguments=$_.Arguments;working_directory=$_.WorkingDirectory}}}})
}} | ConvertTo-Json -Depth 6 -Compress
"""
    obj = ps_json(script, timeout=15)
    if not obj:
        return None
    microsoft = str(obj["task_path"]).lower().startswith("\\microsoft\\windows\\")
    action_text = " ".join(str(x) for x in obj.get("actions", []))
    remote = bool(re.search(r"(?i)RafdiRemoteMCP|MCP_GATEWAY|windows-mcp|tailscale|Remote GROWTH", action_text + " " + str(obj.get("task_name", ""))))
    obj["protected"] = microsoft or remote
    obj["protected_reason"] = "Microsoft Windows task" if microsoft else ("Remote GROWTH/Tailscale task" if remote else None)
    return obj

def action_plan(action: str, target: dict[str, Any], label: str) -> dict[str, Any]:
    if action not in SUPPORTED_ACTIONS:
        raise EngineError(f"Unsupported action: {action}")
    pre: dict[str, Any] = {}
    rollback: dict[str, Any] | None = None
    irreversible = action in IRREVERSIBLE_ACTIONS

    if action == "terminate_process":
        pid = int(target.get("pid", 0))
        if pid <= 0:
            raise EngineError("terminate_process requires target.pid")
        rec = process_record(pid)
        if not rec:
            raise EngineError(f"Process not found: PID {pid}")
        protected, reason = is_process_protected(rec)
        if protected:
            raise EngineError(f"Refusing protected process termination: {reason}")
        pre = rec

    elif action in {"start_service", "stop_service", "restart_service"}:
        name = str(target.get("name") or "")
        if not name:
            raise EngineError(f"{action} requires target.name")
        svc = exact_service(name)
        if not svc:
            raise EngineError(f"Service not found: {name}")
        if str(svc["name"]).lower() in PROTECTED_SERVICES:
            raise EngineError(f"Refusing mutation of protected service: {name}")
        pre = svc
        if action == "start_service" and str(svc["state"]).lower() != "running":
            rollback = {"action": "stop_service", "target": {"name": svc["name"]}}
        elif action == "stop_service" and str(svc["state"]).lower() == "running":
            rollback = {"action": "start_service", "target": {"name": svc["name"]}}

    elif action in {"enable_task", "disable_task", "run_task"}:
        path = str(target.get("task_path") or "\\")
        name = str(target.get("task_name") or "")
        if not name:
            raise EngineError(f"{action} requires target.task_name")
        task = exact_task(path, name)
        if not task:
            raise EngineError(f"Scheduled task not found: {path}{name}")
        if str(task["task_path"]).lower().startswith("\\microsoft\\windows\\"):
            raise EngineError("Refusing mutation of Microsoft Windows scheduled task")
        action_text = " ".join(str(x) for x in task.get("actions", []))
        if re.search(r"(?i)RafdiRemoteMCP|MCP_GATEWAY|windows-mcp|tailscale", action_text + " " + name):
            raise EngineError("Refusing mutation of Remote GROWTH/Tailscale scheduled task")
        pre = task
        if action == "enable_task" and not bool(task["enabled"]):
            rollback = {"action": "disable_task", "target": {"task_path": path, "task_name": name}}
        elif action == "disable_task" and bool(task["enabled"]):
            rollback = {"action": "enable_task", "target": {"task_path": path, "task_name": name}}

    elif action == "flush_dns":
        pre = {"timestamp": now_iso()}

    plan_id = datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:8]
    plan = {
        "version": 1,
        "plan_id": plan_id,
        "created_at": now_iso(),
        "label": label[:120],
        "action": action,
        "target": target,
        "precondition": pre,
        "irreversible": irreversible,
        "rollback": rollback,
    }
    plan["plan_hash"] = canonical_hash(plan)
    PLAN_ROOT.mkdir(parents=True, exist_ok=True)
    path = PLAN_ROOT / f"{plan_id}.json"
    path.write_text(json.dumps(plan, indent=2, ensure_ascii=True), encoding="utf-8")
    return {"ok": True, "command": "action_plan", **plan, "plan_file": str(path)}

def load_plan(plan_id: str) -> dict[str, Any]:
    path = PLAN_ROOT / f"{plan_id}.json"
    if not path.exists():
        raise EngineError(f"Plan not found: {plan_id}")
    plan = json.loads(path.read_text(encoding="utf-8"))
    expected = plan.get("plan_hash")
    chk = dict(plan)
    chk.pop("plan_hash", None)
    if canonical_hash(chk) != expected:
        raise EngineError("Plan hash mismatch; plan file was modified")
    return plan

def verify_precondition(plan: dict[str, Any]) -> None:
    action = plan["action"]
    target = plan["target"]
    pre = plan["precondition"]
    if action == "terminate_process":
        rec = process_record(int(target["pid"]))
        if not rec:
            raise EngineError("Process disappeared before execute")
        for key in ("pid", "name", "executable", "creation_date"):
            if rec.get(key) != pre.get(key):
                raise EngineError("Process identity changed before execute")
        protected, reason = is_process_protected(rec)
        if protected:
            raise EngineError(f"Process became protected: {reason}")
    elif action in {"start_service", "stop_service", "restart_service"}:
        svc = exact_service(str(target["name"]))
        if not svc:
            raise EngineError("Service disappeared before execute")
        if str(svc["name"]).lower() in PROTECTED_SERVICES:
            raise EngineError("Service is protected")
        if svc.get("state") != pre.get("state") or svc.get("start_mode") != pre.get("start_mode"):
            raise EngineError("Service state/start mode changed before execute")
    elif action in {"enable_task", "disable_task", "run_task"}:
        task = exact_task(str(target.get("task_path") or "\\"), str(target["task_name"]))
        if not task:
            raise EngineError("Scheduled task disappeared before execute")
        if task.get("enabled") != pre.get("enabled") or task.get("state") != pre.get("state"):
            raise EngineError("Scheduled task state changed before execute")

def execute_action(plan_id: str, allow_irreversible: bool) -> dict[str, Any]:
    plan = load_plan(plan_id)
    if plan.get("irreversible") and not allow_irreversible:
        raise EngineError("Plan contains an irreversible action; allow_irreversible=true is required")
    verify_precondition(plan)
    action = plan["action"]
    target = plan["target"]

    if action == "terminate_process":
        pid = int(target["pid"])
        script = f"Stop-Process -Id {pid} -ErrorAction Stop; Start-Sleep -Milliseconds 300; [pscustomobject]@{{alive=[bool](Get-Process -Id {pid} -ErrorAction SilentlyContinue)}} | ConvertTo-Json -Compress"
        result = ps_json(script, timeout=15)
        verified = not bool(result["alive"])
    elif action in {"start_service", "stop_service", "restart_service"}:
        name = str(target["name"])
        verb = {"start_service": "Start-Service", "stop_service": "Stop-Service", "restart_service": "Restart-Service"}[action]
        expected = {"start_service": "Running", "stop_service": "Stopped", "restart_service": "Running"}[action]
        script = f"{verb} -Name {q(name)} -ErrorAction Stop; $s=Get-Service -Name {q(name)}; $s.WaitForStatus('{expected}',[TimeSpan]::FromSeconds(20)); [pscustomobject]@{{state=[string]$s.Status}} | ConvertTo-Json -Compress"
        result = ps_json(script, timeout=30)
        verified = str(result["state"]).lower() == expected.lower()
    elif action in {"enable_task", "disable_task", "run_task"}:
        path = str(target.get("task_path") or "\\")
        name = str(target["task_name"])
        if action == "enable_task":
            script = f"Enable-ScheduledTask -TaskName {q(name)} -TaskPath {q(path)} -ErrorAction Stop | Out-Null; $t=Get-ScheduledTask -TaskName {q(name)} -TaskPath {q(path)}; [pscustomobject]@{{enabled=[bool]$t.Settings.Enabled;state=[string]$t.State}} | ConvertTo-Json -Compress"
            result = ps_json(script, timeout=20)
            verified = bool(result["enabled"])
        elif action == "disable_task":
            script = f"Disable-ScheduledTask -TaskName {q(name)} -TaskPath {q(path)} -ErrorAction Stop | Out-Null; $t=Get-ScheduledTask -TaskName {q(name)} -TaskPath {q(path)}; [pscustomobject]@{{enabled=[bool]$t.Settings.Enabled;state=[string]$t.State}} | ConvertTo-Json -Compress"
            result = ps_json(script, timeout=20)
            verified = not bool(result["enabled"])
        else:
            script = f"Start-ScheduledTask -TaskName {q(name)} -TaskPath {q(path)} -ErrorAction Stop; Start-Sleep -Milliseconds 500; $i=Get-ScheduledTaskInfo -TaskName {q(name)} -TaskPath {q(path)}; [pscustomobject]@{{last_run=$i.LastRunTime.ToString('o');last_result=$i.LastTaskResult}} | ConvertTo-Json -Compress"
            result = ps_json(script, timeout=20)
            verified = True
    elif action == "flush_dns":
        result = ps_json("Clear-DnsClientCache; [pscustomobject]@{flushed=$true} | ConvertTo-Json -Compress", timeout=15)
        verified = bool(result["flushed"])
    else:
        raise EngineError(f"Unsupported action: {action}")

    if not verified:
        raise EngineError("Post-action verification failed")

    receipt_id = plan_id + "-exec-" + uuid.uuid4().hex[:6]
    receipt = {
        "version": 1,
        "receipt_id": receipt_id,
        "plan_id": plan_id,
        "executed_at": now_iso(),
        "action": action,
        "target": target,
        "irreversible": bool(plan.get("irreversible")),
        "rollback": plan.get("rollback"),
        "result": result,
        "verified": verified,
    }
    receipt["receipt_hash"] = canonical_hash(receipt)
    RECEIPT_ROOT.mkdir(parents=True, exist_ok=True)
    path = RECEIPT_ROOT / f"{receipt_id}.json"
    path.write_text(json.dumps(receipt, indent=2, ensure_ascii=True), encoding="utf-8")
    return {"ok": True, "command": "action_execute", **receipt, "receipt_file": str(path)}

def load_receipt(receipt_id: str) -> dict[str, Any]:
    path = RECEIPT_ROOT / f"{receipt_id}.json"
    if not path.exists():
        raise EngineError(f"Receipt not found: {receipt_id}")
    receipt = json.loads(path.read_text(encoding="utf-8"))
    expected = receipt.get("receipt_hash")
    chk = dict(receipt)
    chk.pop("receipt_hash", None)
    if canonical_hash(chk) != expected:
        raise EngineError("Receipt hash mismatch; receipt file was modified")
    return receipt

def rollback_action(receipt_id: str) -> dict[str, Any]:
    receipt = load_receipt(receipt_id)
    rollback = receipt.get("rollback")
    if not rollback:
        raise EngineError("This action has no safe rollback")
    if receipt.get("rollback_receipt_id"):
        raise EngineError("Receipt already rolled back")
    plan = action_plan(str(rollback["action"]), dict(rollback["target"]), f"rollback-{receipt_id}")
    executed = execute_action(plan["plan_id"], allow_irreversible=False)
    receipt["rollback_receipt_id"] = executed["receipt_id"]
    receipt["rolled_back_at"] = now_iso()
    chk = dict(receipt)
    chk.pop("receipt_hash", None)
    receipt["receipt_hash"] = canonical_hash(chk)
    path = RECEIPT_ROOT / f"{receipt_id}.json"
    path.write_text(json.dumps(receipt, indent=2, ensure_ascii=True), encoding="utf-8")
    return {
        "ok": True,
        "command": "action_rollback",
        "receipt_id": receipt_id,
        "rollback_plan_id": plan["plan_id"],
        "rollback_receipt_id": executed["receipt_id"],
    }

def health() -> dict[str, Any]:
    for p in (PLAN_ROOT, RECEIPT_ROOT):
        p.mkdir(parents=True, exist_ok=True)
    return {
        "ok": True,
        "command": "health",
        "plan_root": str(PLAN_ROOT),
        "receipt_root": str(RECEIPT_ROOT),
        "protected_services": sorted(PROTECTED_SERVICES),
        "remote_ports": sorted(REMOTE_PORTS),
        "supported_actions": sorted(SUPPORTED_ACTIONS),
        "irreversible_actions": sorted(IRREVERSIBLE_ACTIONS),
        "network_mutation": "not exposed except local DNS cache flush",
        "remote_growth_runtime_protection": True,
    }

def main() -> int:
    parser = argparse.ArgumentParser(prog="systemops-engine")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("health")
    sub.add_parser("system-health")

    p = sub.add_parser("process-inspect")
    p.add_argument("--query")
    p.add_argument("--pid", type=int)
    p.add_argument("--limit", type=int, default=30)

    p = sub.add_parser("port-inspect")
    p.add_argument("--port", type=int)
    p.add_argument("--pid", type=int)
    p.add_argument("--limit", type=int, default=50)

    p = sub.add_parser("service-inspect")
    p.add_argument("--query")
    p.add_argument("--limit", type=int, default=50)

    sub.add_parser("network-inspect")
    sub.add_parser("tailscale-inspect")

    p = sub.add_parser("scheduled-task-inspect")
    p.add_argument("--query")
    p.add_argument("--limit", type=int, default=50)

    sub.add_parser("startup-inspect")

    p = sub.add_parser("action-plan")
    p.add_argument("action", choices=sorted(SUPPORTED_ACTIONS))
    p.add_argument("target_json")
    p.add_argument("--label", default="manual")

    p = sub.add_parser("action-execute")
    p.add_argument("plan_id")
    p.add_argument("--allow-irreversible", action="store_true")

    p = sub.add_parser("action-rollback")
    p.add_argument("receipt_id")

    args = parser.parse_args()
    try:
        if args.command == "health":
            result = health()
        elif args.command == "system-health":
            result = system_health()
        elif args.command == "process-inspect":
            result = process_inspect(args.query, args.pid, args.limit)
        elif args.command == "port-inspect":
            result = port_inspect(args.port, args.pid, args.limit)
        elif args.command == "service-inspect":
            result = service_inspect(args.query, args.limit)
        elif args.command == "network-inspect":
            result = network_inspect()
        elif args.command == "tailscale-inspect":
            result = tailscale_inspect()
        elif args.command == "scheduled-task-inspect":
            result = scheduled_task_inspect(args.query, args.limit)
        elif args.command == "startup-inspect":
            result = startup_inspect()
        elif args.command == "action-plan":
            target = json.loads(args.target_json)
            if not isinstance(target, dict):
                raise EngineError("target_json must decode to an object")
            result = action_plan(args.action, target, args.label)
        elif args.command == "action-execute":
            result = execute_action(args.plan_id, args.allow_irreversible)
        elif args.command == "action-rollback":
            result = rollback_action(args.receipt_id)
        else:
            raise EngineError("Unknown command")
        emit(result)
        return 0 if result.get("ok", False) else 2
    except Exception as exc:
        emit({"ok": False, "command": args.command, "error": type(exc).__name__, "message": str(exc)})
        return 1

if __name__ == "__main__":
    raise SystemExit(main())