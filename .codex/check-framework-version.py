#!/usr/bin/env python3
"""Read local SD003 version declarations without updating either project."""

import argparse
import json
import os
from pathlib import Path
import re


def framework_version(root):
    versions = []
    for name, prefix in (("deploy.ps1", r"\$"), ("deploy.sh", "")):
        text = (root / ".claude/skills/sd-deploy" / name).read_text(encoding="utf-8-sig")
        matches = re.findall(
            rf'^\s*{prefix}FRAMEWORK_VERSION\s*=\s*["\'](\d+\.\d+\.\d+)["\']\s*$',
            text, re.MULTILINE,
        )
        if len(matches) != 1:
            raise ValueError(f"{name}: expected one numeric FRAMEWORK_VERSION declaration")
        versions.append(matches[0])
    if versions[0] != versions[1]:
        raise ValueError(f"{root}: deploy.ps1/deploy.sh versions disagree")
    return versions[0]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--source", type=Path)
    args = parser.parse_args()
    project = args.project.resolve()
    source = args.source
    if source is None and os.environ.get("SD003_SOURCE"):
        source = Path(os.environ["SD003_SOURCE"])
    if source is None:
        candidates = [project.parent / "sd003"]
        if os.name == "nt":
            candidates.append(Path("D:/claudecode/sd003"))
        source = next((candidate for candidate in candidates if candidate.is_dir()), None)
    source = source.resolve() if source is not None else None
    result = dict(status="unknown", project=str(project),
                  source=str(source) if source is not None else None,
                  currentVersion=None, latestVersion=None, reason="")
    try:
        result["currentVersion"] = framework_version(project)
        if source is None:
            raise ValueError("SD003 source could not be resolved")
        result["latestVersion"] = framework_version(source)
        current = tuple(map(int, result["currentVersion"].split(".")))
        latest = tuple(map(int, result["latestVersion"].split(".")))
        result["status"] = "update_available" if current < latest else "ahead" if current > latest else "current"
        result["reason"] = "Version declarations compared; file contents were not compared"
    except (OSError, ValueError) as error:
        result["reason"] = str(error)
    print(json.dumps(result, ensure_ascii=True))
    return 2 if result["status"] == "unknown" else 0


if __name__ == "__main__":
    raise SystemExit(main())
