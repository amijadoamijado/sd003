#!/usr/bin/env python3
"""switch-phase-update.py - update the registered Stop-hook command in settings.json
to point at the given bash Stop hook file (B18 fix: switch-phase.sh used to require
jq to rewrite settings.json; Git Bash for Windows may not have jq. This uses stdlib
json instead, matching the rest of sd003's hooks).

Usage: switch-phase-update.py <settings.json path> <hook file name>

Updates: .hooks.Stop[0].hooks[0].command -> 'bash "$CLAUDE_PROJECT_DIR/.claude/hooks/<hook file name>"'
Exit codes: 0 = updated, 1 = read/parse/structure error (settings.json left untouched).
"""
import json
import sys


def main():
    if len(sys.argv) < 3:
        sys.stderr.write("switch-phase-update.py: usage: switch-phase-update.py <settings.json> <hook file>\n")
        return 1

    settings_path = sys.argv[1]
    hook_file = sys.argv[2]

    try:
        with open(settings_path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError) as exc:
        sys.stderr.write("switch-phase-update.py: failed to read %s: %s\n" % (settings_path, exc))
        return 1

    try:
        data["hooks"]["Stop"][0]["hooks"][0]["command"] = (
            'bash "$CLAUDE_PROJECT_DIR/.claude/hooks/%s"' % hook_file
        )
    except (KeyError, IndexError, TypeError) as exc:
        sys.stderr.write("switch-phase-update.py: unexpected settings.json structure: %s\n" % exc)
        return 1

    try:
        with open(settings_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
    except OSError as exc:
        sys.stderr.write("switch-phase-update.py: failed to write %s: %s\n" % (settings_path, exc))
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
