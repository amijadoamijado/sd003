"""Regression checks with temporary credentials only; no live account changes."""
import base64
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch, MagicMock
import urllib.error

SPEC = importlib.util.spec_from_file_location(
    "usage_monitor", Path(__file__).resolve().parents[2] / "scripts/ai-usage-monitor.py")
monitor = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(monitor)


def auth():
    payload = base64.urlsafe_b64encode(json.dumps({"email": "example@example.com"}).encode()).decode().rstrip("=")
    return {"tokens": {"access_token": "fake", "account_id": "test-account", "id_token": f"x.{payload}.x"}}


class UsageRegression(unittest.TestCase):
    def test_official_cli_protocol_and_quota(self):
        replies = [
            {"id": 1, "result": {}},
            {"id": 2, "result": {"account": {"email": "example@example.com"}}},
            {"id": 3, "result": {"rateLimits": {"primary": {"usedPercent": 24, "windowDurationMins": 300, "resetsAt": 2000000000}}}},
        ]
        process = MagicMock()
        process.stdout = io.StringIO("\n".join(json.dumps(reply) for reply in replies))
        process.poll.return_value = 0
        with patch.object(monitor.shutil, "which", return_value="codex"), patch.object(monitor.subprocess, "Popen", return_value=process):
            result = monitor.fetch_active_codex_usage(auth())
        self.assertEqual(result["status"], "ok")
        self.assertEqual(result["source"], "Codex CLI")
        self.assertEqual(result["primary"]["remaining_percent"], 76)
        self.assertEqual(result["primary"]["limit_window_seconds"], 18000)
        requests = [json.loads(call.args[0]) for call in process.stdin.write.call_args_list]
        self.assertEqual([request["method"] for request in requests], ["initialize", "initialized", "account/read", "account/rateLimits/read"])

    def test_cli_errors_do_not_expose_backend_body(self):
        process = MagicMock()
        process.stdout = io.StringIO(json.dumps({"id": 1, "error": {"message": "secret-response"}}))
        process.poll.return_value = 0
        with patch.object(monitor.shutil, "which", return_value="codex"), patch.object(monitor.subprocess, "Popen", return_value=process):
            result = monitor.fetch_active_codex_usage(auth())
        self.assertEqual(result["status"], "error")
        self.assertNotIn("secret-response", result["error"])

    def test_cli_unavailable_keeps_identity(self):
        with patch.object(monitor.shutil, "which", return_value=None):
            result = monitor.fetch_active_codex_usage(auth())
        self.assertEqual(result["status"], "error")
        self.assertEqual(result["email"], "example@example.com")

    def test_identity_survives_403_and_wrapped_profile(self):
        error = urllib.error.HTTPError("https://example.com", 403, "Forbidden", {}, None)
        with patch.object(monitor.urllib.request, "urlopen", side_effect=error):
            result = monitor.fetch_codex_usage_from_auth_data({"auth_data": auth()})
        self.assertEqual(result["email"], "example@example.com")
        self.assertEqual(result["account_id"], "test-account")
        self.assertEqual(result["error"], "HTTP 403")

    def test_missing_quota_is_not_full_quota(self):
        with patch.object(monitor.urllib.request, "urlopen") as request:
            request.return_value.__enter__.return_value.read.return_value = b'{}'
            result = monitor.fetch_codex_usage_from_auth_data(auth())
        self.assertEqual(result["status"], "error")
        self.assertNotIn("primary", result)

    def test_switch_unwraps_profile_in_temp_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "auth.json"
            target.write_text(json.dumps({"old": True}), encoding="utf-8")
            (root / "example.json").write_text(json.dumps({"auth_data": auth()}), encoding="utf-8")
            with patch.object(monitor, "CODEX_AUTH_FILE", target), patch.object(monitor, "CODEX_PROFILES_DIR", root), patch.object(monitor, "fetch_codex_usage_from_auth_data", return_value={}), contextlib.redirect_stdout(io.StringIO()):
                monitor.switch_codex("example")
            self.assertEqual(json.loads(target.read_text(encoding="utf-8")), auth())
            self.assertEqual(json.loads(target.with_suffix(".json.bak").read_text()), {"old": True})

    def test_missing_secondary_usage_does_not_crash_display(self):
        data = {"rate_limit": {"primary_window": {"used_percent": 24}, "secondary_window": {"limit_window_seconds": 604800}}}
        with patch.object(monitor.urllib.request, "urlopen") as request:
            request.return_value.__enter__.return_value.read.return_value = json.dumps(data).encode()
            result = monitor.fetch_codex_usage_from_auth_data(auth())
        self.assertEqual(result["primary"]["remaining_percent"], 76)
        self.assertIsNone(result["secondary"])

    def test_snapshot_is_stale_and_active_is_not_duplicated(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "active.json"
            target.write_text(json.dumps(auth()), encoding="utf-8")
            profiles = root / "profiles"
            profiles.mkdir()
            (profiles / "same.json").write_text(json.dumps({"auth_data": auth()}), encoding="utf-8")
            (profiles / "same_snapshot_only.json").write_text(json.dumps({"auth_data": {}, "last_snapshot": {"status": "ok", "account_id": "test-account"}}), encoding="utf-8")
            other = auth()
            other["tokens"]["account_id"] = "another-account"
            snapshot = {"status": "ok", "primary": {"remaining_desc": "あと5時間", "remaining_percent": 76}}
            (profiles / "other.json").write_text(json.dumps({"auth_data": other, "last_snapshot": snapshot}), encoding="utf-8")
            error = urllib.error.HTTPError("https://example.com", 403, "Forbidden", {}, None)
            with patch.object(monitor, "CODEX_AUTH_FILE", target), patch.object(monitor, "CODEX_PROFILES_DIR", profiles), patch.object(monitor, "fetch_active_codex_usage", return_value={"status": "error", "account_id": "test-account"}), patch.object(monitor.urllib.request, "urlopen", side_effect=error):
                results = monitor.get_all_codex_accounts()
            self.assertEqual(len(results), 2)
            self.assertTrue(results[1]["is_snapshot"])
            self.assertIn("現在残量は未確認", results[1]["primary"]["remaining_desc"])

    def test_agy_does_not_invent_quota(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(monitor, "HOME", Path(directory)), patch.object(monitor, "AGY_SETTINGS_FILE", Path(directory) / "missing"):
            result = monitor.fetch_agy_status()
        self.assertIsNone(result["five_hour"])
        self.assertIsNone(result["seven_day"])
        self.assertEqual(result["status"], "unavailable")


if __name__ == "__main__":
    unittest.main()
