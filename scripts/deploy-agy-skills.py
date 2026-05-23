#!/usr/bin/env python3
"""Deploy SD003 skills to agy's global skill dir so they appear as un-prefixed `/` commands.

agy (Antigravity CLI v1.0.1) dropdown behavior, verified empirically:
- Workspace `<repo>/.agents/skills/*/SKILL.md`  -> shown in `/skills`, NOT in the `/` dropdown.
- Global `~/.gemini/skills/{name}/SKILL.md`      -> shown in the `/` dropdown as `/{name}` (un-prefixed). ✅
- `agy plugin import` of an extension            -> dropdown but namespaced as `/{ext}:{name}` (prefixed). ✗ rejected.

So to get un-prefixed slash commands in agy's dropdown, the skills must live in the GLOBAL
skill directory. This script mirrors `.agents/skills/*` into `~/.gemini/skills/` with a
single-line description (the format proven to render in the dropdown), and prunes stale
SD003-managed skills. Only directories carrying the `.sd003-managed` marker are pruned, so
unrelated user skills are never touched.

Run after `scripts/sync-cli-commands.py`. Restart agy to pick up changes.
"""

from __future__ import annotations

import os
import shutil
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
AGENTS_SKILLS_DIR = REPO_ROOT / ".agents" / "skills"
MARKER = ".sd003-managed"


def global_skills_dir() -> Path:
    user_profile = os.environ.get("USERPROFILE") or str(Path.home())
    return Path(user_profile) / ".gemini" / "skills"


def parse_name_and_desc(skill_md: str) -> tuple[str, str, str]:
    """Return (name, single-line description, body) from a SKILL.md."""
    if not skill_md.startswith("---"):
        return "", "", skill_md
    close = skill_md.index("---", 3)
    fm = skill_md[3:close]
    body = skill_md[close + 3:].lstrip("\r\n")
    name = ""
    desc = ""
    lines = fm.splitlines()
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("name:"):
            name = stripped[len("name:"):].strip().strip('"')
        elif stripped.startswith("description:"):
            val = stripped[len("description:"):].strip()
            if val in ("|", ">"):  # block scalar -> first indented line
                for follow in lines[i + 1:]:
                    if follow.strip():
                        desc = follow.strip()
                        break
            else:
                desc = val.strip().strip('"')
    return name, desc, body


def render_skill(name: str, desc: str, body: str) -> str:
    safe_desc = desc.replace('"', '\\"') if desc else name
    return f'---\nname: {name}\ndescription: "{safe_desc}"\n---\n\n{body}'


def main() -> int:
    target_root = global_skills_dir()
    target_root.mkdir(parents=True, exist_ok=True)

    source_slugs: set[str] = set()
    count = 0
    for skill_dir in sorted(AGENTS_SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            continue
        name, desc, body = parse_name_and_desc(skill_md.read_text(encoding="utf-8"))
        if not name:
            continue
        source_slugs.add(name)
        dest = target_root / name
        if dest.exists():
            shutil.rmtree(dest)
        # Copy supporting files (scripts/, references/, assets/, etc.), excluding SKILL.md
        shutil.copytree(skill_dir, dest, ignore=shutil.ignore_patterns("SKILL.md", "CLAUDE.md"))
        dest.mkdir(parents=True, exist_ok=True)
        (dest / "SKILL.md").write_text(render_skill(name, desc, body), encoding="utf-8", newline="\n")
        (dest / MARKER).write_text("managed by SD003 deploy-agy-skills.py\n", encoding="utf-8", newline="\n")
        count += 1

    # Prune stale SD003-managed skills no longer in source
    pruned = []
    for d in target_root.iterdir():
        if d.is_dir() and (d / MARKER).exists() and d.name not in source_slugs:
            shutil.rmtree(d)
            pruned.append(d.name)

    print(f"Deployed {count} skills to {target_root}")
    if pruned:
        print(f"Pruned stale: {', '.join(pruned)}")
    print("Restart agy. Commands appear as /<name> (un-prefixed) in the / dropdown.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
