#!/usr/bin/env python3
"""Zoe MCP Server — Streamable HTTP transport for Claude Web + Claude Code.

Exposes Zoe's state files as MCP resources and tools.
Scoped to ~/zoe/ only. Git-commits every write.
"""

import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from mcp.server.fastmcp import FastMCP

ZOE_ROOT = Path(os.environ.get("ZOE_ROOT", Path.home() / "zoe"))
STATE_DIR = ZOE_ROOT / "STATE"

# Allowed state files — nothing outside this list
ALLOWED_FILES = {
    "ZOE.md",
    "version.json",
    "STATE/CHANGELOG.md",
    "STATE/MAILBOX.md",
    "STATE/TODO.md",
    "STATE/ENVIRONMENT.md",
    "STATE/JOURNAL",
}

mcp = FastMCP("zoe-mcp")


def _resolve(relpath: str) -> Path | None:
    """Resolve a relative path against ZOE_ROOT, rejecting anything outside."""
    clean = relpath.lstrip("/")
    if clean not in ALLOWED_FILES:
        return None
    resolved = (ZOE_ROOT / clean).resolve()
    if not str(resolved).startswith(str(ZOE_ROOT.resolve())):
        return None
    return resolved


def _git_commit(filepath: Path, message: str):
    """Stage and commit a single file."""
    try:
        subprocess.run(
            ["git", "add", str(filepath)],
            cwd=ZOE_ROOT, capture_output=True, timeout=10
        )
        subprocess.run(
            ["git", "commit", "-m", message,
             "--author", "Zoe MCP <noreply@zoe.local>"],
            cwd=ZOE_ROOT, capture_output=True, timeout=10
        )
    except subprocess.SubprocessError:
        pass  # non-fatal — file is still written


# --- Resources ---

@mcp.resource("zoe://state/{path}")
def read_state(path: str) -> str:
    """Read a Zoe state file."""
    resolved = _resolve(path)
    if not resolved or not resolved.exists():
        return f"ERROR: file not found or not allowed: {path}"
    return resolved.read_text()


@mcp.resource("zoe://manifest")
def manifest() -> str:
    """List all available state files and their sizes."""
    lines = []
    for f in sorted(ALLOWED_FILES):
        p = ZOE_ROOT / f
        if p.exists():
            size = p.stat().st_size
            lines.append(f"  {f} ({size} bytes)")
        else:
            lines.append(f"  {f} (missing)")
    return "Zoe state files:\n" + "\n".join(lines)


# --- Tools ---

@mcp.tool()
def read_file(path: str) -> str:
    """Read a Zoe state file. Path is relative to Zoe root, e.g. 'STATE/CHANGELOG.md' or 'ZOE.md'."""
    resolved = _resolve(path)
    if not resolved or not resolved.exists():
        return f"ERROR: file not found or not allowed: {path}"
    return resolved.read_text()


@mcp.tool()
def write_file(path: str, content: str, reason: str) -> str:
    """Write a Zoe state file. Requires a reason for the change (used as commit message).
    Path is relative to Zoe root. Only allowed state files can be written."""
    resolved = _resolve(path)
    if not resolved:
        return f"ERROR: path not allowed: {path}"
    resolved.parent.mkdir(parents=True, exist_ok=True)
    resolved.write_text(content)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    _git_commit(resolved, f"zoe-mcp: {reason}\n\nTimestamp: {ts}")
    return f"OK: wrote {path} ({len(content)} bytes), committed."


@mcp.tool()
def append_file(path: str, content: str, reason: str) -> str:
    """Append to a Zoe state file. Good for CHANGELOG and MAILBOX entries."""
    resolved = _resolve(path)
    if not resolved:
        return f"ERROR: path not allowed: {path}"
    resolved.parent.mkdir(parents=True, exist_ok=True)
    existing = resolved.read_text() if resolved.exists() else ""
    resolved.write_text(content + "\n" + existing if "CHANGELOG" in path or "MAILBOX" in path else existing + "\n" + content)
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    _git_commit(resolved, f"zoe-mcp: {reason}\n\nTimestamp: {ts}")
    return f"OK: appended to {path}, committed."


@mcp.tool()
def list_files() -> str:
    """List all available Zoe state files."""
    lines = []
    for f in sorted(ALLOWED_FILES):
        p = ZOE_ROOT / f
        if p.exists():
            size = p.stat().st_size
            mtime = datetime.fromtimestamp(p.stat().st_mtime, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            lines.append(f"{f} ({size}B, {mtime})")
        else:
            lines.append(f"{f} (missing)")
    return "\n".join(lines)


if __name__ == "__main__":
    from mcp.server.transport_security import TransportSecuritySettings

    # Allow tunnel hostnames through DNS rebinding protection
    mcp.settings.transport_security = TransportSecuritySettings(
        enable_dns_rebinding_protection=False,
    )
    mcp.settings.host = "0.0.0.0"
    mcp.settings.port = 8000
    mcp.run(transport="streamable-http")
