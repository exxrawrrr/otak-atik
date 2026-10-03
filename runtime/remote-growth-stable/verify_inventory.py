from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path

from fastmcp import Client


async def inspect_tools(url: str, auth_file: Path, timeout: int) -> dict:
    token = auth_file.read_text(encoding="utf-8").strip()
    if not token:
        raise RuntimeError("auth file is empty")

    async with Client(url, auth=token, timeout=timeout) as client:
        tools = await client.list_tools()

    names = sorted(tool.name for tool in tools)
    return {
        "ok": True,
        "url": url,
        "count": len(names),
        "tools": names,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True)
    parser.add_argument("--auth-file", required=True)
    parser.add_argument("--expected", type=int, default=64)
    parser.add_argument("--timeout", type=int, default=20)
    parser.add_argument("--names", action="store_true")
    args = parser.parse_args()

    try:
        result = asyncio.run(
            inspect_tools(args.url, Path(args.auth_file), args.timeout)
        )
    except Exception as exc:
        print(json.dumps({
            "ok": False,
            "error": str(exc),
            "count": None,
        }, ensure_ascii=True))
        return 3

    result["expected"] = args.expected
    result["inventory_match"] = result["count"] == args.expected
    if not args.names:
        result.pop("tools", None)

    print(json.dumps(result, ensure_ascii=True))
    return 0 if result["inventory_match"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
