import argparse
import atexit
import ctypes
import json
import os
import re
import sqlite3
import time
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent
CONFIG_PATH = BASE / "config.json"
DB_PATH = BASE / "data" / "local-index.sqlite3"
LOCK_PATH = BASE / "data" / "index.lock"

def now_iso():
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")

def load_config():
    with CONFIG_PATH.open("r", encoding="utf-8-sig") as f:
        return json.load(f)

def pid_running(pid):
    try:
        handle = ctypes.windll.kernel32.OpenProcess(0x1000, False, int(pid))
        if handle:
            ctypes.windll.kernel32.CloseHandle(handle)
            return True
    except Exception:
        pass
    return False

def release_index_lock():
    try:
        if LOCK_PATH.exists():
            owner = LOCK_PATH.read_text(encoding="ascii", errors="ignore").strip()
            if owner == str(os.getpid()):
                LOCK_PATH.unlink(missing_ok=True)
    except Exception:
        pass

def acquire_index_lock():
    LOCK_PATH.parent.mkdir(parents=True, exist_ok=True)
    if LOCK_PATH.exists():
        try:
            old_pid = int(LOCK_PATH.read_text(encoding="ascii", errors="ignore").strip())
        except Exception:
            old_pid = 0
        if old_pid and pid_running(old_pid):
            return False, old_pid
        try:
            LOCK_PATH.unlink()
        except Exception:
            pass
    try:
        fd = os.open(str(LOCK_PATH), os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        os.write(fd, str(os.getpid()).encode("ascii"))
        os.close(fd)
        atexit.register(release_index_lock)
        return True, os.getpid()
    except FileExistsError:
        try:
            owner = int(LOCK_PATH.read_text(encoding="ascii", errors="ignore").strip())
        except Exception:
            owner = 0
        return False, owner

def connect():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(str(DB_PATH), timeout=30)
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA journal_mode=WAL")
    con.execute("PRAGMA synchronous=NORMAL")
    con.execute("PRAGMA temp_store=MEMORY")
    con.execute("PRAGMA busy_timeout=30000")
    return con

def init_db(con):
    con.executescript("""
    CREATE TABLE IF NOT EXISTS files (
      id INTEGER PRIMARY KEY,
      path TEXT NOT NULL UNIQUE COLLATE NOCASE,
      name TEXT NOT NULL,
      ext TEXT NOT NULL,
      root TEXT NOT NULL,
      size INTEGER NOT NULL,
      mtime_ns INTEGER NOT NULL,
      indexed_at TEXT NOT NULL,
      content_indexed INTEGER NOT NULL DEFAULT 0
    );
    CREATE INDEX IF NOT EXISTS idx_files_root ON files(root);
    CREATE INDEX IF NOT EXISTS idx_files_name ON files(name COLLATE NOCASE);
    CREATE INDEX IF NOT EXISTS idx_files_ext ON files(ext);
    CREATE INDEX IF NOT EXISTS idx_files_mtime ON files(mtime_ns DESC);

    CREATE VIRTUAL TABLE IF NOT EXISTS files_fts USING fts5(
      path,
      name,
      content,
      tokenize='unicode61 remove_diacritics 2'
    );

    CREATE TABLE IF NOT EXISTS workspaces (
      path TEXT PRIMARY KEY COLLATE NOCASE,
      name TEXT NOT NULL,
      root TEXT NOT NULL,
      markers TEXT NOT NULL,
      detected_at TEXT NOT NULL
    );
    CREATE VIRTUAL TABLE IF NOT EXISTS workspaces_fts USING fts5(
      path,
      name,
      markers,
      tokenize='unicode61 remove_diacritics 2'
    );

    CREATE TABLE IF NOT EXISTS meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
    """)
    con.commit()

def excluded_dir(name, cfg):
    excluded = {x.casefold() for x in cfg["exclude_dir_names"]}
    return name.casefold() in excluded

def is_text_ext(ext, cfg):
    return ext.lower() in set(cfg["text_extensions"])

def read_text(path, limit_chars):
    try:
        data = Path(path).read_bytes()
        if not data or b"\x00" in data[:8192]:
            return ""
        for enc in ("utf-8", "utf-8-sig", "cp1252", "latin-1"):
            try:
                return data.decode(enc, errors="strict")[:limit_chars]
            except UnicodeDecodeError:
                continue
        return data.decode("utf-8", errors="ignore")[:limit_chars]
    except Exception:
        return ""

def detect_workspace(filenames, dirnames, cfg):
    markers = []
    file_set = set(filenames)
    dir_set = set(dirnames)
    for marker in cfg["workspace_markers"]:
        if marker == ".git":
            if ".git" in dir_set or ".git" in file_set:
                markers.append(marker)
        elif marker in file_set:
            markers.append(marker)
    if not markers:
        for filename in filenames:
            if filename.lower().endswith(".sln"):
                markers.append(filename)
                break
    return markers

def index_cmd(_args):
    locked, owner_pid = acquire_index_lock()
    if not locked:
        print(json.dumps({
            "ok": False,
            "command": "index",
            "reason": "INDEX_ALREADY_RUNNING",
            "owner_pid": owner_pid
        }))
        return

    cfg = load_config()
    con = connect()
    init_db(con)
    roots = [r for r in cfg["roots"] if os.path.isdir(r)]
    started = time.perf_counter()
    scanned = changed = deleted = content_count = errors = 0
    seen_paths = set()
    workspaces_found = {}

    con.execute("INSERT OR REPLACE INTO meta(key,value) VALUES('index_state','RUNNING')")
    con.execute("INSERT OR REPLACE INTO meta(key,value) VALUES('index_started_at',?)", (now_iso(),))
    con.commit()

    existing = {
        row["path"].lower(): (row["id"], row["size"], row["mtime_ns"])
        for row in con.execute("SELECT id,path,size,mtime_ns FROM files")
    }

    for root in roots:
        for dirpath, dirnames, filenames in os.walk(root, topdown=True):
            original_dirs = list(dirnames)
            markers = detect_workspace(filenames, original_dirs, cfg)
            if markers:
                workspaces_found[dirpath] = (root, markers)

            dirnames[:] = [d for d in dirnames if not excluded_dir(d, cfg)]

            for filename in filenames:
                path = os.path.join(dirpath, filename)
                try:
                    st = os.stat(path)
                except OSError:
                    errors += 1
                    continue

                scanned += 1
                key = path.lower()
                seen_paths.add(key)
                size = int(st.st_size)
                mtime_ns = int(st.st_mtime_ns)
                old = existing.get(key)

                if old and old[1] == size and old[2] == mtime_ns:
                    continue

                try:
                    name = os.path.basename(path)
                    ext = os.path.splitext(name)[1].lower()
                    content = ""
                    content_indexed = 0
                    if size <= int(cfg["max_text_file_bytes"]) and is_text_ext(ext, cfg):
                        content = read_text(path, int(cfg["max_text_chars"]))
                        content_indexed = 1 if content else 0

                    if old:
                        file_id = old[0]
                        con.execute(
                            "UPDATE files SET name=?,ext=?,root=?,size=?,mtime_ns=?,indexed_at=?,content_indexed=? WHERE id=?",
                            (name, ext, root, size, mtime_ns, now_iso(), content_indexed, file_id),
                        )
                        con.execute("DELETE FROM files_fts WHERE rowid=?", (file_id,))
                    else:
                        cur = con.execute(
                            "INSERT INTO files(path,name,ext,root,size,mtime_ns,indexed_at,content_indexed) VALUES(?,?,?,?,?,?,?,?)",
                            (path, name, ext, root, size, mtime_ns, now_iso(), content_indexed),
                        )
                        file_id = cur.lastrowid

                    con.execute(
                        "INSERT INTO files_fts(rowid,path,name,content) VALUES(?,?,?,?)",
                        (file_id, path, name, content),
                    )
                    changed += 1
                    content_count += content_indexed

                    if changed % 500 == 0:
                        con.execute(
                            "INSERT OR REPLACE INTO meta(key,value) VALUES('index_progress',?)",
                            (json.dumps({"scanned": scanned, "changed": changed}),),
                        )
                        con.commit()
                except Exception:
                    errors += 1

    for key, old in existing.items():
        if key not in seen_paths:
            file_id = old[0]
            con.execute("DELETE FROM files_fts WHERE rowid=?", (file_id,))
            con.execute("DELETE FROM files WHERE id=?", (file_id,))
            deleted += 1

    con.execute("DELETE FROM workspaces")
    con.execute("DELETE FROM workspaces_fts")
    workspace_count = 0
    for path, (root, markers) in sorted(workspaces_found.items()):
        name = os.path.basename(path.rstrip("\\/")) or path
        marker_text = ",".join(markers)
        cur = con.execute(
            "INSERT INTO workspaces(path,name,root,markers,detected_at) VALUES(?,?,?,?,?)",
            (path, name, root, marker_text, now_iso()),
        )
        rowid = cur.lastrowid
        con.execute(
            "INSERT INTO workspaces_fts(rowid,path,name,markers) VALUES(?,?,?,?)",
            (rowid, path, name, marker_text),
        )
        workspace_count += 1

    finished = now_iso()
    con.execute("INSERT OR REPLACE INTO meta(key,value) VALUES('last_indexed_at',?)", (finished,))
    con.execute("INSERT OR REPLACE INTO meta(key,value) VALUES('index_state','COMPLETE')")
    con.execute("INSERT OR REPLACE INTO meta(key,value) VALUES('index_progress',?)",
                (json.dumps({"scanned": scanned, "changed": changed, "deleted": deleted}),))
    con.execute("INSERT OR REPLACE INTO meta(key,value) VALUES('roots',?)",
                (json.dumps(roots, ensure_ascii=False),))
    con.commit()
    try:
        con.execute("PRAGMA optimize")
    except Exception:
        pass

    total = con.execute("SELECT count(*) FROM files").fetchone()[0]
    elapsed = round(time.perf_counter() - started, 3)
    print(json.dumps({
        "ok": True,
        "command": "index",
        "roots": roots,
        "scanned": scanned,
        "changed": changed,
        "deleted": deleted,
        "content_indexed_changed": content_count,
        "total_files": total,
        "workspaces": workspace_count,
        "errors": errors,
        "elapsed_seconds": elapsed,
        "db": str(DB_PATH),
        "db_bytes": DB_PATH.stat().st_size if DB_PATH.exists() else 0
    }, ensure_ascii=False))

def query_terms(query):
    return [t for t in re.findall(r"[\w.-]+", query, flags=re.UNICODE) if t]

def fts_candidates(query):
    ts = query_terms(query)
    if not ts:
        return []
    quoted = ['"%s"*' % t.replace('"', '""') for t in ts]
    if len(quoted) == 1:
        return quoted
    return [" AND ".join(quoted), " OR ".join(quoted)]

def file_row(row):
    return {
        "path": row["path"],
        "name": row["name"],
        "ext": row["ext"],
        "size": row["size"],
        "modified": datetime.fromtimestamp(
            row["mtime_ns"] / 1_000_000_000
        ).astimezone().isoformat(timespec="seconds"),
        "content_indexed": bool(row["content_indexed"])
    }

def search_files(query, limit, mode):
    con = connect()
    init_db(con)
    rows = []
    weights = "1.8,5.0,1.0" if mode == "file-find" else "1.5,3.5,1.0"
    sql = f"""
    SELECT f.*, bm25(files_fts,{weights}) AS score
    FROM files_fts
    JOIN files f ON f.id=files_fts.rowid
    WHERE files_fts MATCH ?
    ORDER BY score ASC, f.mtime_ns DESC
    LIMIT ?
    """
    for fq in fts_candidates(query):
        try:
            rows = con.execute(sql, (fq, limit)).fetchall()
        except sqlite3.OperationalError:
            rows = []
        if rows:
            break

    if not rows:
        like = "%" + query + "%"
        rows = con.execute(
            """SELECT *, 0.0 AS score FROM files
               WHERE name LIKE ? COLLATE NOCASE OR path LIKE ? COLLATE NOCASE
               ORDER BY mtime_ns DESC LIMIT ?""",
            (like, like, limit),
        ).fetchall()

    return [
        {**file_row(row), "score": round(float(row["score"]), 4)}
        for row in rows
    ]

def search_cmd(args):
    started = time.perf_counter()
    results = search_files(args.query, args.limit, "search")
    print(json.dumps({
        "ok": True,
        "command": "local_search",
        "query": args.query,
        "count": len(results),
        "elapsed_ms": round((time.perf_counter() - started) * 1000, 2),
        "results": results
    }, ensure_ascii=False))

def file_find_cmd(args):
    started = time.perf_counter()
    results = search_files(args.query, args.limit, "file-find")
    print(json.dumps({
        "ok": True,
        "command": "file_find",
        "query": args.query,
        "count": len(results),
        "elapsed_ms": round((time.perf_counter() - started) * 1000, 2),
        "results": results
    }, ensure_ascii=False))

def workspace_find_cmd(args):
    con = connect()
    init_db(con)
    started = time.perf_counter()
    rows = []
    sql = """
    SELECT w.*, bm25(workspaces_fts,1.5,5.0,1.0) AS score
    FROM workspaces_fts
    JOIN workspaces w ON w.rowid=workspaces_fts.rowid
    WHERE workspaces_fts MATCH ?
    ORDER BY score ASC
    LIMIT ?
    """
    for fq in fts_candidates(args.query):
        try:
            rows = con.execute(sql, (fq, args.limit)).fetchall()
        except sqlite3.OperationalError:
            rows = []
        if rows:
            break

    if not rows:
        like = "%" + args.query + "%"
        rows = con.execute(
            """SELECT *, 0.0 AS score FROM workspaces
               WHERE name LIKE ? COLLATE NOCASE OR path LIKE ? COLLATE NOCASE
               ORDER BY path LIMIT ?""",
            (like, like, args.limit),
        ).fetchall()

    results = [{
        "path": row["path"],
        "name": row["name"],
        "markers": row["markers"].split(",") if row["markers"] else [],
        "score": round(float(row["score"]), 4)
    } for row in rows]

    print(json.dumps({
        "ok": True,
        "command": "workspace_find",
        "query": args.query,
        "count": len(results),
        "elapsed_ms": round((time.perf_counter() - started) * 1000, 2),
        "results": results
    }, ensure_ascii=False))

def workspace_summary_cmd(args):
    path = os.path.abspath(args.path)
    con = connect()
    init_db(con)
    prefix = path.rstrip("\\/") + os.sep
    rows = con.execute(
        """SELECT path,name,ext,size,mtime_ns,content_indexed FROM files
           WHERE path LIKE ? COLLATE NOCASE
           ORDER BY mtime_ns DESC""",
        (prefix + "%",),
    ).fetchall()

    direct_dirs = []
    try:
        direct_dirs = sorted([
            entry.name for entry in os.scandir(path)
            if entry.is_dir(follow_symlinks=False)
            and entry.name.casefold() not in {
                ".git","node_modules",".venv","venv","__pycache__"
            }
        ])[:30]
    except Exception:
        pass

    ext_counts = Counter((row["ext"] or "<none>") for row in rows)
    total_bytes = sum(int(row["size"]) for row in rows)
    marker_row = con.execute(
        "SELECT markers FROM workspaces WHERE path=? COLLATE NOCASE",
        (path,),
    ).fetchone()

    print(json.dumps({
        "ok": True,
        "command": "workspace_summary",
        "path": path,
        "exists": os.path.isdir(path),
        "indexed_files": len(rows),
        "indexed_bytes": total_bytes,
        "markers": marker_row["markers"].split(",") if marker_row and marker_row["markers"] else [],
        "direct_directories": direct_dirs,
        "top_extensions": ext_counts.most_common(12),
        "recent_files": [file_row(row) for row in rows[:12]]
    }, ensure_ascii=False))

def health_cmd(_args):
    con = connect()
    init_db(con)
    def meta(key):
        row = con.execute("SELECT value FROM meta WHERE key=?", (key,)).fetchone()
        return row["value"] if row else None

    count = con.execute("SELECT count(*) FROM files").fetchone()[0]
    content_count = con.execute(
        "SELECT count(*) FROM files WHERE content_indexed=1"
    ).fetchone()[0]
    workspaces = con.execute("SELECT count(*) FROM workspaces").fetchone()[0]

    lock_owner = None
    index_running = False
    if LOCK_PATH.exists():
        try:
            lock_owner = int(LOCK_PATH.read_text(encoding="ascii", errors="ignore").strip())
            index_running = pid_running(lock_owner)
        except Exception:
            lock_owner = None

    print(json.dumps({
        "ok": True,
        "command": "health",
        "db": str(DB_PATH),
        "db_exists": DB_PATH.exists(),
        "db_bytes": DB_PATH.stat().st_size if DB_PATH.exists() else 0,
        "files": count,
        "content_indexed_files": content_count,
        "workspaces": workspaces,
        "last_indexed_at": meta("last_indexed_at"),
        "index_state": meta("index_state"),
        "index_progress": meta("index_progress"),
        "index_running": index_running,
        "index_pid": lock_owner if index_running else None,
        "fts5": True
    }, ensure_ascii=False))

def main():
    parser = argparse.ArgumentParser(prog="fast-local-engine")
    sub = parser.add_subparsers(dest="command", required=True)

    sp = sub.add_parser("index")
    sp.set_defaults(func=index_cmd)

    sp = sub.add_parser("search")
    sp.add_argument("query")
    sp.add_argument("--limit", type=int, default=20)
    sp.set_defaults(func=search_cmd)

    sp = sub.add_parser("file-find")
    sp.add_argument("query")
    sp.add_argument("--limit", type=int, default=20)
    sp.set_defaults(func=file_find_cmd)

    sp = sub.add_parser("workspace-find")
    sp.add_argument("query")
    sp.add_argument("--limit", type=int, default=20)
    sp.set_defaults(func=workspace_find_cmd)

    sp = sub.add_parser("workspace-summary")
    sp.add_argument("path")
    sp.set_defaults(func=workspace_summary_cmd)

    sp = sub.add_parser("health")
    sp.set_defaults(func=health_cmd)

    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()