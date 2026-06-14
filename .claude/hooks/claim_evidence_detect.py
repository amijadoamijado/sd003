#!/usr/bin/env python3
"""claim_evidence_detect.py - deterministic detector for unevidenced causal-confirmation claims.

Guards the sd003 /ai-suspect root cause (2026-06-14): asserting an unverified or
unobservable cause as "確定 / 確認した / 原因は...だ" with NO evidence attached
(証拠より語りを優先する過信). See docs/troubleshooting/RESOLUTION_LOG.md.

Subcommands:
  gate   read a Stop-hook JSON from stdin, inspect the LAST assistant turn, and
         (non-blocking) warn if it is an unevidenced causal-confirmation claim.
         ALWAYS exits 0 and approves -- fail-open, never blocks Stop.
  check  pure deterministic test entrypoint:
           claim_evidence_detect.py check "<text>" <had_tool_use:0|1>
         prints "FLAG" or "OK". Used by the regression test.

Detection is a two-condition AND (low false-positive):
  FLAG  iff  causal-confirmation language present
        AND  no evidence token present in the same turn
  evidence = had_tool_use OR a `path:line` citation OR a `backtick` code span.
fail-open + warn-only + narrow keywords => avoids the 2026-05-26 heavy-gate self-destruct.
"""
import json
import re
import sys

# Causal + confirmation language only (NOT generic "完了"). Narrow on purpose.
CAUSAL_CONFIRM = re.compile(
    r"(真因は"
    r"|確定済み|確定です|確定しました"
    r"|確認した|確認済み"
    r"|原因は[^。\n]{0,40}(だ|です|である|でした)"
    r"|が原因(だ|です|である))"
)
PATH_LINE = re.compile(r"[\w./\\\-]+:\d+")   # e.g. settings.json:8
BACKTICK = re.compile(r"`[^`]+`")            # quoted command / output span


def has_evidence(text, had_tool_use):
    if had_tool_use:
        return True
    if PATH_LINE.search(text):
        return True
    if BACKTICK.search(text):
        return True
    return False


def is_unevidenced_causal_claim(text, had_tool_use):
    if not CAUSAL_CONFIRM.search(text):
        return False
    return not has_evidence(text, had_tool_use)


def _last_assistant_turn(transcript_path):
    """Return (text, had_tool_use) for the last assistant message in the transcript."""
    try:
        with open(transcript_path, "r", encoding="utf-8") as fh:
            lines = fh.readlines()
    except OSError:
        return "", False
    text_parts = []
    had_tool_use = False
    for line in reversed(lines):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except ValueError:
            continue
        if obj.get("type") != "assistant":
            continue
        content = obj.get("message", {}).get("content", [])
        if isinstance(content, str):
            text_parts.append(content)
        else:
            for block in content:
                if not isinstance(block, dict):
                    continue
                if block.get("type") == "text":
                    text_parts.append(block.get("text", ""))
                elif block.get("type") == "tool_use":
                    had_tool_use = True
        break
    return "\n".join(text_parts), had_tool_use


def cmd_gate():
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except ValueError:
        payload = {}
    transcript = payload.get("transcript_path", "")
    text, had_tool_use = _last_assistant_turn(transcript) if transcript else ("", False)
    if text and is_unevidenced_causal_claim(text, had_tool_use):
        warn = ("[claim-evidence] 未検証の因果断定の疑い: 因果の確信語があるのに同ターンに"
                "証拠(tool実行 / path:line引用 / コマンド出力引用)がありません。"
                "証拠を添えるか『推測』と明示してください。")
        sys.stderr.write(warn + "\n")
        sys.stdout.write(json.dumps({"decision": "approve", "systemMessage": warn},
                                    ensure_ascii=False))
    else:
        sys.stdout.write('{"decision":"approve"}')
    return 0  # fail-open: never block Stop


def cmd_check():
    text = sys.argv[2] if len(sys.argv) > 2 else ""
    had_tool_use = len(sys.argv) > 3 and sys.argv[3] == "1"
    print("FLAG" if is_unevidenced_causal_claim(text, had_tool_use) else "OK")
    return 0


def main():
    sub = sys.argv[1] if len(sys.argv) > 1 else "gate"
    return cmd_check() if sub == "check" else cmd_gate()


if __name__ == "__main__":
    sys.exit(main())
