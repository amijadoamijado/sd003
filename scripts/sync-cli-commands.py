#!/usr/bin/env python3
"""
Sync SD003 custom commands across Claude Code, Codex, and Antigravity CLI (agy).

Canonical source strategy:
- Claude Code `.claude/commands/**/*.md` remains the authoring input
- `.sd/commands/` stores normalized specs and a manifest
- Antigravity TOML and Codex skills are generated from the normalized specs
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple


REPO_ROOT = Path(__file__).resolve().parents[1]
CLAUDE_COMMANDS_DIR = REPO_ROOT / ".claude" / "commands"
ANTIGRAVITY_COMMANDS_DIR = REPO_ROOT / ".antigravity" / "commands"
ANTIGRAVITY_SKILLS_DIR = REPO_ROOT / ".antigravity" / "skills"
CODEX_SKILLS_DIR = REPO_ROOT / ".codex" / "skills"
CLAUDE_SKILLS_DIR = REPO_ROOT / ".claude" / "skills"
CANONICAL_DIR = REPO_ROOT / ".sd" / "commands"
CANONICAL_SPECS_DIR = CANONICAL_DIR / "specs"
MANIFEST_PATH = CANONICAL_DIR / "manifest.json"


ALIASES: Dict[str, List[str]] = {
    "sessionread": ["session-read"],
    "sessionwrite": ["session-write"],
}


@dataclass
class CommandSpec:
    slug: str
    source: str
    description: str
    allowed_tools: List[str]
    claude_command: str
    title: str
    body: str
    aliases: List[str]


def parse_frontmatter(text: str) -> Tuple[Dict[str, str], str]:
    if not text.startswith("---"):
        return {}, text

    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text

    frontmatter_text = parts[1].strip()
    body = parts[2].lstrip("\r\n")
    metadata: Dict[str, str] = {}

    for line in frontmatter_text.splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        metadata[key.strip()] = value.strip()

    return metadata, body


def slug_from_path(path: Path) -> str:
    rel = path.relative_to(CLAUDE_COMMANDS_DIR)
    if rel.parts and rel.parts[0] == "sd":
        return rel.stem
    return rel.with_suffix("").as_posix().replace("/", "-")


def extract_title(body: str, fallback: str) -> str:
    for line in body.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return fallback


def extract_command(body: str, slug: str) -> str:
    for line in body.splitlines():
        stripped = line.strip().strip("`")
        if stripped.startswith("/"):
            return stripped.split()[0]
        match = re.search(r":\s*`?(/[A-Za-z0-9:_-]+)`?$", line)
        if match:
            return match.group(1)
    return f"/{slug}"


def load_claude_specs() -> List[CommandSpec]:
    specs: List[CommandSpec] = []
    for path in sorted(CLAUDE_COMMANDS_DIR.rglob("*.md")):
        text = path.read_text(encoding="utf-8")
        metadata, body = parse_frontmatter(text)
        slug = slug_from_path(path)
        title = extract_title(body, slug)
        description = metadata.get("description", title)
        allowed_tools = [
            item.strip()
            for item in metadata.get("allowed-tools", "").split(",")
            if item.strip()
        ]
        claude_command = extract_command(body, slug)
        specs.append(
            CommandSpec(
                slug=slug,
                source=path.relative_to(REPO_ROOT).as_posix(),
                description=description,
                allowed_tools=allowed_tools,
                claude_command=claude_command,
                title=title,
                body=body.rstrip() + "\n",
                aliases=ALIASES.get(slug, []),
            )
        )
    return specs


def canonical_markdown(spec: CommandSpec) -> str:
    frontmatter = {
        "slug": spec.slug,
        "source": spec.source,
        "description": spec.description,
        "claude_command": spec.claude_command,
        "codex_skill": spec.slug,
        "antigravity_file": f"{spec.slug}.toml",
    }
    if spec.aliases:
        frontmatter["aliases"] = ", ".join(spec.aliases)
    if spec.allowed_tools:
        frontmatter["allowed_tools"] = ", ".join(spec.allowed_tools)

    header_lines = ["---"]
    for key, value in frontmatter.items():
        header_lines.append(f"{key}: {value}")
    header_lines.append("---")
    header = "\n".join(header_lines)

    return (
        f"{header}\n\n"
        f"# {spec.title}\n\n"
        "## Canonical Intent\n"
        "Claude Code のカスタムコマンド仕様を CLI 非依存で保持する正本です。\n"
        "Antigravity CLI の TOML と Codex の skill はこのファイルから生成します。\n\n"
        "## Original Body\n"
        f"{spec.body}"
    )


def antigravity_toml(spec: CommandSpec) -> str:
    escaped_description = spec.description.replace('"', '\\"')
    # Use literal triple quotes (''') to avoid issues with backslashes in the body.
    # TOML literal strings do not support escape sequences.
    return (
        f'description = "{escaped_description}"\n'
        "prompt = '''\n"
        f"{spec.body}"
        "'''\n"
    )


def codex_skill_markdown(spec: CommandSpec, alias_target: str | None = None) -> str:
    if alias_target:
        return (
            f"---\nname: {spec.slug}\n"
            f"description: Legacy alias for `{alias_target}`. "
            f"Use when the user invokes `{spec.claude_command}` or `{spec.slug}` in Codex.\n"
            "---\n\n"
            f"# {spec.slug}\n\n"
            f"この skill は `{alias_target}` の互換エイリアスです。\n"
            f"`{alias_target}` と同じ手順で `{spec.claude_command}` を再現してください。\n"
            "Codex内ではClaude Codeのスラッシュコマンドや `/codex:*` を文字通り実行せず、"
            "ファイル読取・編集・検証・報告をCodexの通常手順に置き換えてください。\n"
        )

    triggers = [f"`{spec.claude_command}`", f"`{spec.slug}`"]
    triggers.extend(f"`{alias}`" for alias in spec.aliases)
    trigger_text = ", ".join(triggers)

    body = spec.body
    return (
        f"---\nname: {spec.slug}\n"
        f"description: Codex equivalent of the SD003 custom command `{spec.claude_command}`. "
        f"Use when the user invokes {trigger_text}.\n"
        "---\n\n"
        f"# {spec.title}\n\n"
        f"この skill は Claude Code の `{spec.claude_command}` を Codex で再現するためのものです。\n"
        "本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。\n\n"
        "## Codex Runtime Rules\n"
        "- `.claude/commands/**/*.md` はClaude Code側のauthoring sourceです。直接変更せず、CodexではこのSkillを実行仕様として扱います。\n"
        "- Claude Codeのスラッシュコマンド、`Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Codexの通常手順に翻訳します。\n"
        "- Codex内で `/codex:review`、`/codex:rescue` などのCodexプラグインコマンドを再帰的に呼ばないでください。必要な読取・差分確認・編集・検証・報告をCodex自身で実施します。\n"
        "- 人間向け出力、レビュー報告、質問、完了報告は日本語で書きます。\n"
        "- `.sd/ai-coordination/` に依頼書・報告書を書く場合は、既存の案件ID配下に限定し、プロジェクトルートへ散らさないでください。\n"
        "- Windows環境ではPowerShellで実行できるコマンドを優先し、bash専用の例はWSLやGit Bashが使える場合だけ採用します。\n\n"
        "## Original Command Body\n"
        f"{body}"
    )


def render_manifest(specs: List[CommandSpec]) -> str:
    manifest = {
        "version": 1,
        "source": ".claude/commands/**/*.md",
        "generated": {
            "canonical_specs": ".sd/commands/specs/*.md",
            "antigravity_commands": ".antigravity/commands/*.toml",
            "codex_skills": ".codex/skills/*/SKILL.md",
            "codex_spec": ".codex/CODEX_SPEC.md",
            "legacy_codex_skills": ".agents/skills/*/SKILL.md",
        },
        "commands": [
            {
                "slug": spec.slug,
                "source": spec.source,
                "description": spec.description,
                "claude_command": spec.claude_command,
                "antigravity_file": f"{spec.slug}.toml",
                "codex_skill": spec.slug,
                "aliases": spec.aliases,
            }
            for spec in specs
        ],
    }
    return json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")


def codex_home_skills_dir() -> Path:
    user_profile = os.environ.get("USERPROFILE")
    if user_profile:
        return Path(user_profile) / ".codex" / "skills"
    return Path.home() / ".codex" / "skills"


def deploy_codex_home(specs: List[CommandSpec]) -> Path:
    target_root = codex_home_skills_dir()
    target_root.mkdir(parents=True, exist_ok=True)

    for spec in specs:
        skill_names = [spec.slug, *spec.aliases]
        for skill_name in skill_names:
            src_dir = CODEX_SKILLS_DIR / skill_name
            dest_dir = target_root / skill_name
            if dest_dir.exists():
                shutil.rmtree(dest_dir)
            shutil.copytree(src_dir, dest_dir)

    return target_root


def previous_codex_skill_dirs() -> set[str]:
    previous_skill_dirs: set[str] = set()
    if MANIFEST_PATH.exists():
        try:
            previous_manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
            for item in previous_manifest.get("commands", []):
                skill_name = item.get("codex_skill")
                if skill_name:
                    previous_skill_dirs.add(skill_name)
                for alias in item.get("aliases", []):
                    previous_skill_dirs.add(alias)
        except json.JSONDecodeError:
            previous_skill_dirs = set()
    return previous_skill_dirs


def desired_codex_skill_dirs(specs: List[CommandSpec]) -> set[str]:
    desired_skill_dirs = {spec.slug for spec in specs}
    for spec in specs:
        desired_skill_dirs.update(spec.aliases)
    return desired_skill_dirs


def write_codex_skills(specs: List[CommandSpec], previous_skill_dirs: set[str] | None = None) -> None:
    CODEX_SKILLS_DIR.mkdir(parents=True, exist_ok=True)
    previous_skill_dirs = previous_skill_dirs or set()
    desired_skill_dirs = desired_codex_skill_dirs(specs)

    for skill_name in previous_skill_dirs - desired_skill_dirs:
        stale_dir = CODEX_SKILLS_DIR / skill_name
        if stale_dir.exists():
            shutil.rmtree(stale_dir)

    for spec in specs:
        skill_dir = CODEX_SKILLS_DIR / spec.slug
        write_text(skill_dir / "SKILL.md", codex_skill_markdown(spec))

        for alias in spec.aliases:
            alias_dir = CODEX_SKILLS_DIR / alias
            alias_spec = CommandSpec(
                slug=alias,
                source=spec.source,
                description=spec.description,
                allowed_tools=spec.allowed_tools,
                claude_command=spec.claude_command,
                title=spec.title,
                body=spec.body,
                aliases=[],
            )
            write_text(alias_dir / "SKILL.md", codex_skill_markdown(alias_spec, alias_target=spec.slug))


def sync_skills() -> None:
    if not CLAUDE_SKILLS_DIR.exists():
        return

    ANTIGRAVITY_SKILLS_DIR.mkdir(parents=True, exist_ok=True)

    # Get desired skill names from .claude/skills/
    desired_skills = {p.name for p in CLAUDE_SKILLS_DIR.iterdir() if p.is_dir()}

    # Remove stale skills from .antigravity/skills/
    for p in ANTIGRAVITY_SKILLS_DIR.iterdir():
        if p.is_dir() and p.name not in desired_skills:
            shutil.rmtree(p)

    # Sync skills
    for skill_dir in CLAUDE_SKILLS_DIR.iterdir():
        if not skill_dir.is_dir():
            continue

        skill_name = skill_dir.name
        target_dir = ANTIGRAVITY_SKILLS_DIR / skill_name

        # Simple copytree with overwrite
        if target_dir.exists():
            shutil.rmtree(target_dir)
        shutil.copytree(skill_dir, target_dir)
        print(f"  Synced skill: {skill_name}")


def sync() -> List[CommandSpec]:
    specs = load_claude_specs()
    CANONICAL_SPECS_DIR.mkdir(parents=True, exist_ok=True)
    ANTIGRAVITY_COMMANDS_DIR.mkdir(parents=True, exist_ok=True)
    CODEX_SKILLS_DIR.mkdir(parents=True, exist_ok=True)

    print("Syncing skills...")
    sync_skills()

    print("Syncing commands...")
    previous_skill_dirs = previous_codex_skill_dirs()

    desired_spec_files = {f"{spec.slug}.md" for spec in specs}
    for path in CANONICAL_SPECS_DIR.glob("*.md"):
        if path.name not in desired_spec_files:
            path.unlink()

    desired_antigravity_files = {
        f"{spec.slug}.toml"
        for spec in specs
        if not (CLAUDE_SKILLS_DIR / spec.slug).is_dir()
    }
    for path in ANTIGRAVITY_COMMANDS_DIR.glob("*.toml"):
        if path.name not in desired_antigravity_files:
            path.unlink()

    for spec in specs:
        write_text(CANONICAL_SPECS_DIR / f"{spec.slug}.md", canonical_markdown(spec))

        # Skip generating Antigravity TOML if a skill with the same name exists in .claude/skills/
        # This avoids conflicts where both a command and a skill provide the same slash command.
        if (CLAUDE_SKILLS_DIR / spec.slug).is_dir():
            print(f"  Skipping Antigravity command TOML for {spec.slug} (exists as skill)")
        else:
            write_text(ANTIGRAVITY_COMMANDS_DIR / f"{spec.slug}.toml", antigravity_toml(spec))

    write_codex_skills(specs, previous_skill_dirs)

    write_text(MANIFEST_PATH, render_manifest(specs))
    return specs


def check() -> int:
    specs = load_claude_specs()
    failures: List[str] = []
    if not (REPO_ROOT / ".codex" / "CODEX_SPEC.md").exists():
        failures.append("missing codex spec: .codex/CODEX_SPEC.md")
    for spec in specs:
        if not (CANONICAL_SPECS_DIR / f"{spec.slug}.md").exists():
            failures.append(f"missing canonical spec: {spec.slug}")
        antigravity_command_expected = not (CLAUDE_SKILLS_DIR / spec.slug).is_dir()
        if antigravity_command_expected and not (ANTIGRAVITY_COMMANDS_DIR / f"{spec.slug}.toml").exists():
            failures.append(f"missing antigravity command: {spec.slug}")
        if not (CODEX_SKILLS_DIR / spec.slug / "SKILL.md").exists():
            failures.append(f"missing codex skill: {spec.slug}")
        for alias in spec.aliases:
            if not (CODEX_SKILLS_DIR / alias / "SKILL.md").exists():
                failures.append(f"missing codex alias skill: {alias}")

    if failures:
        print("SYNC CHECK FAILED")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"SYNC CHECK OK ({len(specs)} commands)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--codex-only", action="store_true")
    parser.add_argument("--deploy-codex-home", action="store_true")
    args = parser.parse_args()

    if args.check:
        return check()

    if args.codex_only:
        specs = load_claude_specs()
        write_codex_skills(specs, previous_codex_skill_dirs())
        if args.deploy_codex_home:
            target_root = deploy_codex_home(specs)
            print(f"Deployed generated Codex skills to {target_root}")
        print(f"Synced {len(specs)} Codex skill specs.")
        return 0

    specs = sync()
    if args.deploy_codex_home:
        target_root = deploy_codex_home(specs)
        print(f"Deployed generated Codex skills to {target_root}")
    print(f"Synced {len(specs)} command specs.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
