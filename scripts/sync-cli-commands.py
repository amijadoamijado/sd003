#!/usr/bin/env python3
"""
Sync SD003 custom commands across Claude Code, Codex, and Antigravity CLI (agy).

Canonical source strategy:
- Claude Code `.claude/commands/**/*.md` remains the authoring input
- `.sd/commands/` stores normalized specs and a manifest
- Antigravity (agy) skills and Codex skills are generated from the normalized specs

Antigravity CLI (agy) discovers slash commands as Agent Skills (SKILL.md), NOT as
`.toml` command files. agy scans (verified empirically against agy 1.0.1):
  Workspace: <repo>/.agents/skills/{name}/SKILL.md
  Global:    ~/.gemini/antigravity-cli/skills/{name}/SKILL.md
  Shared:    ~/.gemini/skills/{name}/SKILL.md
So SD003 commands are emitted as `.agents/skills/{slug}/SKILL.md`, and the real
`.claude/skills/*` are mirrored into `.agents/skills/` as well.
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
AGENTS_SKILLS_DIR = REPO_ROOT / ".agents" / "skills"
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
        # CLAUDE.md is a claude-mem auto-generated context stub, not a real
        # command. Ingesting it produced a junk `/CLAUDE` skill — skip it.
        if path.name == "CLAUDE.md":
            continue
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
        "antigravity_skill": f"{spec.slug}/SKILL.md",
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
        "Antigravity(agy) skill と Codex skill はこのファイルから生成します。\n\n"
        "## Original Body\n"
        f"{spec.body}"
    )


def yaml_quote(value: str) -> str:
    """Double-quote a scalar so colons (`: `), `#`, etc. stay valid in YAML.

    Frontmatter descriptions are real command descriptions (e.g.
    "スキルインストール: /skills:add") and routinely contain `: `, which an
    unquoted YAML value parses as a nested mapping. Quoting avoids that.
    """
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def antigravity_skill_markdown(spec: CommandSpec, alias_target: str | None = None) -> str:
    """Generate an Agent Skill (SKILL.md) for the Antigravity CLI (agy).

    agy treats the frontmatter `name` as the slash command (`name: foo` -> `/foo`).
    `disable-model-invocation: true` keeps these from auto-firing; they run only
    when the user explicitly types the command. `$ARGUMENTS` receives anything
    typed after the command.
    """
    if alias_target:
        alias_desc = f"Legacy alias for {alias_target} (SD003 command {spec.claude_command})."
        return (
            "---\n"
            f"name: {spec.slug}\n"
            f"description: {yaml_quote(alias_desc)}\n"
            "disable-model-invocation: true\n"
            "---\n\n"
            f"# {spec.slug} (alias)\n\n"
            f"This skill is an alias of `{alias_target}`. Follow the same steps as "
            f"`{alias_target}` to reproduce `{spec.claude_command}`.\n\n"
            "User-provided arguments (if any): $ARGUMENTS\n"
        )

    return (
        "---\n"
        f"name: {spec.slug}\n"
        f"description: {yaml_quote(spec.description)}\n"
        "disable-model-invocation: true\n"
        "---\n\n"
        f"# {spec.title}\n\n"
        f"SD003 custom command `{spec.claude_command}` を Antigravity (agy) skill として再現します。\n\n"
        "User-provided arguments (if any): $ARGUMENTS\n\n"
        "## Antigravity Runtime Rules\n"
        "- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。\n"
        "- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、"
        "agy の通常手順（ファイル読取・編集・コマンド実行・必要時のユーザー確認）に翻訳する。\n"
        "- `/workflow:*` や `/codex:*` など他CLIのスラッシュコマンドは呼ばない。必要な作業はagy自身が直接行う。\n"
        "- 人間向け出力・報告・質問は日本語で書く。\n"
        "- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。\n"
        "- WindowsではPowerShellで実行できるコマンドを優先する。\n\n"
        "## Original Command Body\n"
        f"{spec.body}"
    )


def codex_native_contract(spec: CommandSpec) -> str:
    common = (
        "## Codex Native Execution Contract\n"
        "このセクションはCodex実行時に `Original Command Body` より優先します。\n\n"
        "- Claude Codeのスラッシュコマンド、`/workflow:*`、`/codex:*`、`Agent(...)`、`AskUserQuestion` は文字通り実行しない。\n"
        "- Codex自身がファイル読取、差分確認、編集、検証、報告を直接行う。\n"
        "- `.claude/commands/**/*.md` はauthoring sourceとして読むだけにし、Codex改善のために直接編集しない。\n"
        "- 案件IDがない相談・レビューでは `.sd/ai-coordination/` に報告書を作らず、会話内で完結する。\n"
        "- `.sd/ai-coordination/` に書くのは、案件IDが明示された正式Workflowの場合だけにする。\n"
        "- WindowsではPowerShellで実行できるコマンドを優先し、bash例はWSL/Git Bashが使える場合だけ採用する。\n"
        "- `.sd/` が存在しない場合は、その事実を報告し、可能なら軽量レビューまたは直接実装へ縮退する。\n\n"
    )

    if spec.slug == "workflow-review":
        return common + (
            "### Native workflow-review\n"
            "1. `IMPLEMENT_REQUEST_{番号}.md` が存在すれば読み、レビュー範囲を確定する。\n"
            "2. `git status --short`、`git diff --stat`、必要な `git diff` / `git show` を読む。\n"
            "3. 実行可能な範囲で build/test/lint を実行し、未実行や失敗は結果に明記する。\n"
            "4. `/codex:review` や `/codex:adversarial-review` は呼ばず、Codex自身が重大度順にレビューする。\n"
            "5. 案件IDがある場合のみ `.sd/ai-coordination/workflow/review/{案件ID}/REVIEW_IMPL_{番号}.md` に保存する。\n\n"
        )

    if spec.slug == "workflow-impl":
        return common + (
            "### Native workflow-impl\n"
            "1. `IMPLEMENT_REQUEST_{番号}.md` またはユーザー依頼を読み、変更可能範囲を確認する。\n"
            "2. `--codex` 相当の場合でも `/codex:rescue` は呼ばず、Codex自身が実装する。\n"
            "3. 既存の未コミット変更を保持し、対象スコープ外を戻さない。\n"
            "4. `apply_patch` を優先して編集し、不要なリファクタを避ける。\n"
            "5. 実行可能な検証を行い、失敗時は原因と残作業を明記する。\n\n"
        )

    if spec.slug == "sessionread":
        return common + (
            "### Native sessionread\n"
            "1. 指定4ファイルを読む。存在しないファイルは警告して続行する。\n"
            "2. `git status --short` と直近コミットを確認する。\n"
            "3. bash/WSL前提のバックグラウンド処理が使えない場合は、未実行理由を報告して続行する。\n"
            "4. 前回状況、未解決事項、次回優先タスクを簡潔に要約する。\n\n"
        )

    return common


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
            "詳細は `.codex/CODEX_NATIVE.md` を優先してください。\n"
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
        f"{codex_native_contract(spec)}"
        "## Original Command Body\n"
        f"{body}"
    )


def render_manifest(specs: List[CommandSpec]) -> str:
    manifest = {
        "version": 1,
        "source": ".claude/commands/**/*.md",
        "generated": {
            "canonical_specs": ".sd/commands/specs/*.md",
            "antigravity_skills": ".agents/skills/*/SKILL.md",
            "codex_skills": ".codex/skills/*/SKILL.md",
            "codex_spec": ".codex/CODEX_SPEC.md",
        },
        "commands": [
            {
                "slug": spec.slug,
                "source": spec.source,
                "description": spec.description,
                "claude_command": spec.claude_command,
                "antigravity_skill": f"{spec.slug}/SKILL.md",
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


def _rewrite_skill_md_for_agy(path: Path) -> None:
    """Replace 'allowed-tools:' with 'disable-model-invocation: true' in frontmatter.

    .claude/skills use allowed-tools (Claude Code syntax). agy requires
    disable-model-invocation: true for skills to appear as slash commands.
    """
    text = path.read_text(encoding="utf-8")
    if "disable-model-invocation" in text or not text.startswith("---"):
        return
    close = text.index("---", 3)
    fm = text[3:close].strip()
    rest = text[close + 3:]
    lines = [l for l in fm.splitlines() if not l.startswith("allowed-tools")]
    lines.append("disable-model-invocation: true")
    path.write_text("---\n" + "\n".join(lines) + "\n---" + rest, encoding="utf-8", newline="\n")


def real_skill_names() -> set[str]:
    if not CLAUDE_SKILLS_DIR.exists():
        return set()
    return {p.name for p in CLAUDE_SKILLS_DIR.iterdir() if p.is_dir()}


def sync_agents_skills(specs: List[CommandSpec]) -> None:
    """Populate .agents/skills/ — the directory agy actually scans.

    Two kinds of entries land here:
    - Real skills mirrored from .claude/skills/* (they ship their own SKILL.md).
    - Command skills generated from .claude/commands/* (one per command slug that
      is not already a real skill), so each becomes an agy slash command.
    """
    AGENTS_SKILLS_DIR.mkdir(parents=True, exist_ok=True)

    skills = real_skill_names()
    command_specs = [s for s in specs if s.slug not in skills]
    command_slugs = {s.slug for s in command_specs}
    alias_slugs: set[str] = set()
    for s in command_specs:
        alias_slugs.update(s.aliases)

    desired = skills | command_slugs | alias_slugs

    # Prune stale entries (anything not currently desired)
    for p in AGENTS_SKILLS_DIR.iterdir():
        if p.is_dir() and p.name not in desired:
            shutil.rmtree(p)

    # Mirror real skills
    if CLAUDE_SKILLS_DIR.exists():
        for skill_dir in sorted(CLAUDE_SKILLS_DIR.iterdir()):
            if not skill_dir.is_dir():
                continue
            target_dir = AGENTS_SKILLS_DIR / skill_dir.name
            if target_dir.exists():
                shutil.rmtree(target_dir)
            # Never mirror CLAUDE.md (claude-mem third-party context stubs) into .agents
            shutil.copytree(skill_dir, target_dir, ignore=shutil.ignore_patterns("CLAUDE.md"))
            target_skill_md = target_dir / "SKILL.md"
            if target_skill_md.exists():
                _rewrite_skill_md_for_agy(target_skill_md)
            print(f"  Mirrored skill: {skill_dir.name}")

    # Generate command skills (skip slugs already provided as real skills)
    for spec in command_specs:
        write_text(AGENTS_SKILLS_DIR / spec.slug / "SKILL.md", antigravity_skill_markdown(spec))
        print(f"  Generated command skill: {spec.slug}")
        for alias in spec.aliases:
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
            write_text(
                AGENTS_SKILLS_DIR / alias / "SKILL.md",
                antigravity_skill_markdown(alias_spec, alias_target=spec.slug),
            )

    for spec in specs:
        if spec.slug in skills:
            print(f"  Skipping command skill for {spec.slug} (exists as real skill)")


def sync() -> List[CommandSpec]:
    specs = load_claude_specs()
    CANONICAL_SPECS_DIR.mkdir(parents=True, exist_ok=True)
    AGENTS_SKILLS_DIR.mkdir(parents=True, exist_ok=True)
    CODEX_SKILLS_DIR.mkdir(parents=True, exist_ok=True)

    print("Syncing Antigravity (agy) skills + command skills...")
    sync_agents_skills(specs)

    print("Syncing canonical specs + Codex skills...")
    previous_skill_dirs = previous_codex_skill_dirs()

    desired_spec_files = {f"{spec.slug}.md" for spec in specs}
    for path in CANONICAL_SPECS_DIR.glob("*.md"):
        if path.name not in desired_spec_files:
            path.unlink()

    for spec in specs:
        write_text(CANONICAL_SPECS_DIR / f"{spec.slug}.md", canonical_markdown(spec))

    write_codex_skills(specs, previous_skill_dirs)

    write_text(MANIFEST_PATH, render_manifest(specs))
    return specs


def check() -> int:
    specs = load_claude_specs()
    failures: List[str] = []
    if not (REPO_ROOT / ".codex" / "CODEX_SPEC.md").exists():
        failures.append("missing codex spec: .codex/CODEX_SPEC.md")
    skills = real_skill_names()
    for spec in specs:
        if not (CANONICAL_SPECS_DIR / f"{spec.slug}.md").exists():
            failures.append(f"missing canonical spec: {spec.slug}")
        agy_skill_expected = spec.slug not in skills
        if agy_skill_expected and not (AGENTS_SKILLS_DIR / spec.slug / "SKILL.md").exists():
            failures.append(f"missing antigravity skill: {spec.slug}")
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
