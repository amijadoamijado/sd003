import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT_PATH = Path(__file__).resolve().parents[2] / "scripts" / "sync-cli-commands.py"
SPEC = importlib.util.spec_from_file_location("sync_cli_commands", SCRIPT_PATH)
assert SPEC and SPEC.loader
sync_cli_commands = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = sync_cli_commands
SPEC.loader.exec_module(sync_cli_commands)


def command_spec(slug: str = "sample"):
    return sync_cli_commands.CommandSpec(
        slug=slug,
        source=".claude/commands/sample.md",
        description="Sample command",
        allowed_tools=[],
        claude_command="/sample",
        title="Sample",
        body="Do the sample work.\n",
        aliases=[],
    )


class SharedAgentSkillsTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.agents_dir = self.root / ".agents" / "skills"
        self.claude_skills_dir = self.root / ".claude" / "skills"
        self.agents_dir.mkdir(parents=True)
        self.claude_skills_dir.mkdir(parents=True)
        self.original_agents_dir = sync_cli_commands.AGENTS_SKILLS_DIR
        self.original_claude_skills_dir = sync_cli_commands.CLAUDE_SKILLS_DIR
        sync_cli_commands.AGENTS_SKILLS_DIR = self.agents_dir
        sync_cli_commands.CLAUDE_SKILLS_DIR = self.claude_skills_dir

    def tearDown(self):
        sync_cli_commands.AGENTS_SKILLS_DIR = self.original_agents_dir
        sync_cli_commands.CLAUDE_SKILLS_DIR = self.original_claude_skills_dir
        self.temp_dir.cleanup()

    def test_unmanaged_same_name_collision_is_non_destructive(self):
        target = self.agents_dir / "sample"
        target.mkdir()
        custom = target / "SKILL.md"
        custom.write_text("custom content\n", encoding="utf-8")

        with self.assertRaisesRegex(RuntimeError, "unmanaged Agent Skill collision"):
            sync_cli_commands.sync_agents_skills([command_spec()])

        self.assertEqual(custom.read_text(encoding="utf-8"), "custom content\n")
        self.assertFalse((target / sync_cli_commands.MANAGED_MARKER).exists())

    def test_generates_provider_neutral_managed_skill(self):
        sync_cli_commands.sync_agents_skills([command_spec()])

        target = self.agents_dir / "sample"
        text = (target / "SKILL.md").read_text(encoding="utf-8")
        self.assertIn("Codex/agy共通Agent Skill", text)
        self.assertIn("## Runtime Adaptation Rules", text)
        self.assertNotIn("## Antigravity Runtime Rules", text)
        self.assertTrue((target / sync_cli_commands.MANAGED_MARKER).exists())

    def test_manifest_v2_has_one_shared_agent_target(self):
        manifest = json.loads(sync_cli_commands.render_manifest([command_spec()]))

        self.assertEqual(manifest["version"], 2)
        self.assertEqual(
            manifest["generated"]["agent_skills"],
            ".agents/skills/*/SKILL.md",
        )
        self.assertEqual(
            manifest["generated"]["agent_skill_consumers"],
            ["codex", "antigravity"],
        )
        self.assertNotIn("codex_skills", manifest["generated"])
        self.assertNotIn("antigravity_skills", manifest["generated"])
        self.assertEqual(
            manifest["commands"][0]["agent_skill"],
            "sample/SKILL.md",
        )

    def test_legacy_home_deploy_option_fails_closed(self):
        with patch.object(
            sys,
            "argv",
            ["sync-cli-commands.py", "--deploy-codex-home"],
        ):
            self.assertEqual(sync_cli_commands.main(), 2)


if __name__ == "__main__":
    unittest.main()
