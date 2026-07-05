#!/usr/bin/env python3
"""lib_transcript.py - shared helper for sd003 bash Stop hooks (B2 fix).

Background: the Claude Code Stop-hook stdin JSON does NOT contain a `transcript`
field with the conversation text -- it only contains `transcript_path`, a path to
a JSONL transcript file (see .claude/hooks/claim_evidence_detect.py for the
reference pattern already used elsewhere in this repo). sd003-stop-hook.sh and
sd003-stop-hook-endgame.sh used to do `jq -r '.transcript // empty'`, which is
always empty (wrong field name) AND depends on jq, which Git Bash for Windows may
not have. This helper fixes both problems: it reads `transcript_path` from the
stdin JSON (stdlib json, no jq) and extracts the plain-text content of the JSONL
transcript (assistant/user message text + tool_result text), which is what the
hooks need to pattern-match against (e.g. "All tests pass", "FAIL", "Error:").

Usage:
  lib_transcript.py stdin-to-text        Read hook JSON from stdin, print extracted text.
  lib_transcript.py path-to-text <path>  Read a transcript file directly, print extracted text.

Exit code is always 0; on any error the empty string is printed (fail-open, same
policy as claim_evidence_detect.py -- a Stop hook must never crash the turn).
"""
import json
import sys


def _iter_text_blocks(content):
    """Yield text strings from a message `content` value (str, or list of blocks)."""
    if isinstance(content, str):
        if content:
            yield content
        return
    if not isinstance(content, list):
        return
    for block in content:
        if not isinstance(block, dict):
            continue
        btype = block.get("type")
        if btype == "text":
            yield block.get("text", "")
        elif btype == "tool_result":
            # tool_result content can itself be a string or a list of blocks
            # (e.g. bash/test output is where "All tests pass" / "FAIL" actually appear).
            yield from _iter_text_blocks(block.get("content", ""))


def extract_text(transcript_path):
    """Read a Claude Code JSONL transcript and return concatenated plain text
    from every user/assistant message (text blocks + tool_result text blocks)."""
    if not transcript_path:
        return ""
    parts = []
    try:
        with open(transcript_path, "r", encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except ValueError:
                    continue
                if obj.get("type") not in ("assistant", "user"):
                    continue
                content = obj.get("message", {}).get("content", [])
                parts.extend(_iter_text_blocks(content))
    except OSError:
        return ""
    return "\n".join(parts)


def resolve_transcript_path(raw_stdin):
    try:
        payload = json.loads(raw_stdin) if raw_stdin.strip() else {}
    except ValueError:
        payload = {}
    if not isinstance(payload, dict):
        return ""
    path = payload.get("transcript_path", "")
    return path if isinstance(path, str) else ""


def main():
    args = sys.argv[1:]
    cmd = args[0] if args else "stdin-to-text"

    if cmd == "path-to-text":
        path = args[1] if len(args) > 1 else ""
        sys.stdout.write(extract_text(path))
        return 0

    # default: stdin-to-text
    raw = sys.stdin.read()
    path = resolve_transcript_path(raw)
    sys.stdout.write(extract_text(path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
