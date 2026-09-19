#!/usr/bin/env python3
"""
AI Usage & Rate Limit Monitor for SD003.

Supports:
- Claude Code: 5-hour session & 7-day rate limit quotas + reset time
- Codex (multi-account): Rate limits, used %, reset timestamps for active and saved accounts
- Antigravity (agy) & Grok: Active model & runtime context

Usage:
  python scripts/ai-usage-monitor.py
  python scripts/ai-usage-monitor.py --save-codex <label>
  python scripts/ai-usage-monitor.py --switch-codex <label>
  python scripts/ai-usage-monitor.py --list-codex
"""

import argparse
import datetime
import glob
import json
import os
import shutil
import ssl
import sys
import urllib.error
import urllib.request
from pathlib import Path


HOME = Path(os.path.expanduser("~"))
CODEX_AUTH_FILE = HOME / ".codex" / "auth.json"
CODEX_PROFILES_DIR = HOME / ".codex" / "profiles_auth"
CLAUDE_CREDS_FILE = HOME / ".claude" / ".credentials.json"
AGY_SETTINGS_FILE = HOME / ".gemini" / "antigravity-cli" / "settings.json"
GROK_SETTINGS_FILE = HOME / ".grokbot" / "settings.json"

# Account / Organization alias mapping
ACCOUNT_ALIASES = {
    # Match by account_id first, then fallback
    "73621678-afe9-4613-91ec-4f64c7e5f316": "amijadoamijado@yahoo.co.jp",  # prolite (Personal)
    "8e28d994-85b2-4307-8842-9fa9822a5050": "TKH",  # team (TKH)
    "32ddf3b9-925f-4379-99c6-11c2fe0d30c7": "FW",   # 3sf (FW)
    "5bc95b32-fb69-4758-850f-ea8e4e0384ff": "3s",   # 3sf (3s)
}


def get_progress_bar(percent: float, width: int = 14) -> str:
    """Render an ASCII progress bar."""
    p = max(0.0, min(100.0, float(percent)))
    filled_len = int(round(width * p / 100.0))
    bar = "█" * filled_len + "░" * (width - filled_len)
    return f"[{bar}] {p:5.1f}%"


def format_remaining_seconds(seconds: int) -> str:
    """Format seconds into a human-readable remaining string."""
    if seconds <= 0:
        return "利用可能 (即時)"
    days, remainder = divmod(seconds, 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, _ = divmod(remainder, 60)
    if days > 0:
        return f"あと {days}日 {hours}時間{minutes}分"
    if hours > 0:
        return f"あと {hours}時間 {minutes}分"
    return f"あと {minutes}分"


def format_iso_jst(iso_str: str) -> str:
    """Format an ISO timestamp to JST string."""
    try:
        dt = datetime.datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
        jst = dt.astimezone(datetime.timezone(datetime.timedelta(hours=9)))
        return jst.strftime("%m/%d %H:%M JST")
    except Exception:
        return iso_str[:16]


def format_epoch_jst(epoch_sec: int) -> str:
    """Format an epoch timestamp to JST string."""
    try:
        dt = datetime.datetime.fromtimestamp(epoch_sec, tz=datetime.timezone.utc)
        jst = dt.astimezone(datetime.timezone(datetime.timedelta(hours=9)))
        return jst.strftime("%m/%d %H:%M JST")
    except Exception:
        return str(epoch_sec)


# ==============================================================================
# 1. Claude Code Usage Fetcher
# ==============================================================================
def fetch_claude_usage() -> dict:
    result = {
        "status": "ok",
        "email": "不明",
        "subscription": "不明",
        "five_hour": None,
        "seven_day": None,
    }
    if not CLAUDE_CREDS_FILE.exists():
        result["status"] = "not_logged_in"
        result["error"] = "credentials.json が見つかりません"
        return result

    try:
        with open(CLAUDE_CREDS_FILE, "r", encoding="utf-8") as f:
            creds = json.load(f)
        oauth = creds.get("claudeAiOauth", {})
        token = oauth.get("accessToken")
        result["subscription"] = oauth.get("subscriptionType", "不明")
        if not token:
            result["status"] = "not_logged_in"
            result["error"] = "OAuth トークンが見つかりません"
            return result

        # Load email from ~/.claude.json if present
        claude_json_path = HOME / ".claude.json"
        if claude_json_path.exists():
            try:
                with open(claude_json_path, "r", encoding="utf-8") as cjf:
                    cdata = json.load(cjf)
                    result["email"] = cdata.get("oauthAccount", {}).get("emailAddress", "不明")
            except Exception:
                pass

        req = urllib.request.Request(
            "https://api.anthropic.com/api/oauth/usage",
            headers={
                "Authorization": f"Bearer {token}",
                "User-Agent": "Claude-Code/2.1.278",
                "Content-Type": "application/json",
            },
        )
        ctx = ssl.create_default_context()
        with urllib.request.urlopen(req, context=ctx, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))

        fh = data.get("five_hour", {})
        sd = data.get("seven_day", {})

        now_utc = datetime.datetime.now(datetime.timezone.utc)
        if fh and fh.get("resets_at"):
            reset_dt = datetime.datetime.fromisoformat(fh["resets_at"].replace("Z", "+00:00"))
            rem_sec = int((reset_dt - now_utc).total_seconds())
            result["five_hour"] = {
                "used_percent": fh.get("utilization", 0.0),
                "remaining_percent": max(0.0, 100.0 - float(fh.get("utilization", 0.0))),
                "resets_at_str": format_iso_jst(fh["resets_at"]),
                "remaining_desc": format_remaining_seconds(rem_sec),
            }

        if sd and sd.get("resets_at"):
            reset_dt = datetime.datetime.fromisoformat(sd["resets_at"].replace("Z", "+00:00"))
            rem_sec = int((reset_dt - now_utc).total_seconds())
            result["seven_day"] = {
                "used_percent": sd.get("utilization", 0.0),
                "remaining_percent": max(0.0, 100.0 - float(sd.get("utilization", 0.0))),
                "resets_at_str": format_iso_jst(sd["resets_at"]),
                "remaining_desc": format_remaining_seconds(rem_sec),
            }

    except urllib.error.HTTPError as e:
        result["status"] = "error"
        result["error"] = f"HTTP {e.code}"
    except Exception as e:
        result["status"] = "error"
        result["error"] = str(e)

    return result


# ==============================================================================
# 2. Codex Usage Fetcher (Active & Saved Profiles)
# ==============================================================================
def fetch_codex_usage_from_auth_data(auth_data: dict) -> dict:
    tokens = auth_data.get("tokens", {})
    access_token = tokens.get("access_token")
    account_id = tokens.get("account_id")

    if not access_token:
        return {"status": "error", "error": "access_token なし"}

    headers = {
        "Authorization": f"Bearer {access_token}",
        "User-Agent": "codex-cli/0.155.1",
    }
    if account_id:
        headers["chatgpt-account-id"] = account_id

    req = urllib.request.Request(
        "https://chatgpt.com/backend-api/codex/usage",
        headers=headers,
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            rate_limit = data.get("rate_limit", {})
            pw = rate_limit.get("primary_window") or {}
            sw = rate_limit.get("secondary_window") or {}

            # Primary window
            pw_used = pw.get("used_percent", 0)
            pw_reset_sec = pw.get("reset_after_seconds", 0)
            pw_reset_at = pw.get("reset_at", 0)
            pw_window_sec = pw.get("limit_window_seconds", 0)

            # Secondary window
            sw_used = sw.get("used_percent") if sw else None
            sw_reset_sec = sw.get("reset_after_seconds", 0) if sw else None
            sw_reset_at = sw.get("reset_at", 0) if sw else None
            sw_window_sec = sw.get("limit_window_seconds", 0) if sw else 0

            return {
                "status": "ok",
                "email": data.get("email", "不明"),
                "account_id": data.get("account_id", ""),
                "plan_type": data.get("plan_type", "不明"),
                "allowed": rate_limit.get("allowed", True),
                "limit_reached": rate_limit.get("limit_reached", False),
                "primary": {
                    "used_percent": pw_used,
                    "remaining_percent": max(0.0, 100.0 - float(pw_used)),
                    "reset_after_seconds": pw_reset_sec,
                    "limit_window_seconds": pw_window_sec,
                    "remaining_desc": format_remaining_seconds(pw_reset_sec),
                    "resets_at_str": format_epoch_jst(pw_reset_at) if pw_reset_at else "不明",
                },
                "secondary": {
                    "used_percent": sw_used,
                    "remaining_percent": max(0.0, 100.0 - float(sw_used)) if sw_used is not None else None,
                    "reset_after_seconds": sw_reset_sec,
                    "limit_window_seconds": sw_window_sec,
                    "remaining_desc": format_remaining_seconds(sw_reset_sec) if sw_reset_sec else "",
                    "resets_at_str": format_epoch_jst(sw_reset_at) if sw_reset_at else "不明",
                } if sw else None,
            }
    except urllib.error.HTTPError as e:
        return {"status": "error", "error": f"HTTP {e.code}"}
    except Exception as e:
        return {"status": "error", "error": str(e)}


def get_all_codex_accounts() -> list:
    accounts = []
    CODEX_PROFILES_DIR.mkdir(parents=True, exist_ok=True)

    # Active auth
    active_email = None
    if CODEX_AUTH_FILE.exists():
        try:
            with open(CODEX_AUTH_FILE, "r", encoding="utf-8") as f:
                active_auth = json.load(f)
            u = fetch_codex_usage_from_auth_data(active_auth)
            active_email = u.get("email")
            u["is_active"] = True
            u["label"] = "現在のログイン (Active)"
            accounts.append(u)
        except Exception as e:
            accounts.append({"status": "error", "label": "Active", "is_active": True, "error": str(e)})

    # Saved profiles
    for profile_path in sorted(CODEX_PROFILES_DIR.glob("*.json")):
        label = profile_path.stem
        try:
            with open(profile_path, "r", encoding="utf-8") as f:
                pdata = json.load(f)

            auth_data = pdata.get("auth_data", pdata)
            saved_snapshot = pdata.get("last_snapshot")
            saved_at_str = pdata.get("saved_at_str")

            # Try live check first
            u = fetch_codex_usage_from_auth_data(auth_data)

            # If token expired (401/403) or failed, fall back to saved snapshot
            if u.get("status") != "ok" and saved_snapshot:
                u = dict(saved_snapshot)
                u["is_snapshot"] = True
                u["snapshot_time"] = saved_at_str

            # Check if this profile is already the active one
            if active_email and u.get("email") == active_email and u.get("account_id") == active_auth.get("tokens", {}).get("account_id"):
                continue

            u["is_active"] = False
            u["label"] = f"前回保存 [{label}]"
            u["profile_key"] = label
            accounts.append(u)
        except Exception:
            pass

    return accounts


# ==============================================================================
# 3. Account Switcher & Storage
# ==============================================================================
def save_current_codex(label: str):
    if not CODEX_AUTH_FILE.exists():
        print("エラー: 現在の ~/.codex/auth.json が見つかりません。")
        sys.exit(1)
    CODEX_PROFILES_DIR.mkdir(parents=True, exist_ok=True)
    dest = CODEX_PROFILES_DIR / f"{label}.json"

    with open(CODEX_AUTH_FILE, "r", encoding="utf-8") as f:
        auth_data = json.load(f)

    # Fetch snapshot now
    u = fetch_codex_usage_from_auth_data(auth_data)
    now_jst = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).strftime("%m/%d %H:%M JST")

    profile_payload = {
        "auth_data": auth_data,
        "last_snapshot": u,
        "saved_at_str": now_jst,
    }
    with open(dest, "w", encoding="utf-8") as df:
        json.dump(profile_payload, df, ensure_ascii=False, indent=2)

    print(f"✔ 現在のアカウントを '{label}' として保存しました。")
    print(f"  Email: {u.get('email', '不明')} | 記録日時: {now_jst}")


def switch_codex(label: str):
    target = CODEX_PROFILES_DIR / f"{label}.json"
    if not target.exists():
        print(f"エラー: 保存済みアカウント '{label}' は存在しません。")
        print("保存済み一覧を見るには: python scripts/ai-usage-monitor.py --list-codex")
        sys.exit(1)
    # Backup current active to .codex/auth.json.bak
    if CODEX_AUTH_FILE.exists():
        shutil.copy2(CODEX_AUTH_FILE, HOME / ".codex" / "auth.json.bak")
    shutil.copy2(target, CODEX_AUTH_FILE)
    print(f"✔ Codexのアカウントを '{label}' に切り替えました。")
    with open(CODEX_AUTH_FILE, "r", encoding="utf-8") as f:
        d = json.load(f)
    u = fetch_codex_usage_from_auth_data(d)
    email = u.get("email", "不明")
    acc_id = u.get("account_id", "")
    alias = ACCOUNT_ALIASES.get(acc_id, ACCOUNT_ALIASES.get(email, label))
    print(f"  有効アカウント: {email} ({alias})")


def interactive_switch_codex():
    CODEX_PROFILES_DIR.mkdir(parents=True, exist_ok=True)
    profiles = sorted(CODEX_PROFILES_DIR.glob("*.json"))
    if not profiles:
        print("\n保存済みのアカウントがありません。")
        print("現在のアカウントを保存してください:")
        print("  python scripts/ai-usage-monitor.py --save-codex <名前>\n")
        return

    print("\n切り替えるアカウントを番号で選んでください:")
    for idx, p in enumerate(profiles, start=1):
        try:
            with open(p, "r", encoding="utf-8") as f:
                d = json.load(f)
            u = fetch_codex_usage_from_auth_data(d)
            email = u.get("email", "不明")
            acc_id = u.get("account_id", "")
            alias = ACCOUNT_ALIASES.get(acc_id, ACCOUNT_ALIASES.get(email, p.stem))
            status_text = "有効" if u.get("status") == "ok" else "要再ログイン"
            print(f"  [{idx}] {alias} ({email}) - [{status_text}]")
        except Exception:
            print(f"  [{idx}] {p.stem}")

    print("  [0] キャンセル")
    choice = input("\n番号を入力 (1-4) > ").strip()
    if choice == "0" or not choice:
        print("キャンセルしました。")
        return
    try:
        idx = int(choice) - 1
        if 0 <= idx < len(profiles):
            selected = profiles[idx].stem
            switch_codex(selected)
        else:
            print("無効な番号です。")
    except ValueError:
        print("数字を入力してください。")


def list_saved_codex():
    CODEX_PROFILES_DIR.mkdir(parents=True, exist_ok=True)
    profiles = list(CODEX_PROFILES_DIR.glob("*.json"))
    print(f"\n=== 保存済み Codex アカウント一覧 ({len(profiles)} 件) ===")
    if not profiles:
        print("  保存されているアカウントはありません。")
        print("  現在のアカウントを保存: python scripts/ai-usage-monitor.py --save-codex acc1")
        return
    for p in profiles:
        try:
            with open(p, "r", encoding="utf-8") as f:
                d = json.load(f)
            u = fetch_codex_usage_from_auth_data(d)
            print(f"  - [{p.stem}]: {u.get('email', '不明')} - 残り {u.get('remaining_percent', 0):.1f}%")
        except Exception as e:
            print(f"  - [{p.stem}]: 読み込みエラー ({e})")
    print()


# ==============================================================================
# 4. Antigravity (agy) & Grok Status
# ==============================================================================
def fetch_agy_status() -> dict:
    res = {
        "status": "ok",
        "model": "Gemini 3.8 Flash (Low)",
        "email": "Google Cloud/Vertex AI",
        "five_hour": None,
        "seven_day": None,
    }
    if AGY_SETTINGS_FILE.exists():
        try:
            with open(AGY_SETTINGS_FILE, "r", encoding="utf-8") as f:
                d = json.load(f)
                res["model"] = d.get("model", res["model"])
        except Exception:
            pass

    # Read agy history for local usage
    hist_file = HOME / ".gemini" / "antigravity-cli" / "history.jsonl"
    now_utc = datetime.datetime.now(datetime.timezone.utc)
    five_hrs_ago = (now_utc - datetime.timedelta(hours=5)).timestamp() * 1000
    seven_days_ago = (now_utc - datetime.timedelta(days=7)).timestamp() * 1000

    five_hr_turns = 0
    seven_day_turns = 0
    if hist_file.exists():
        try:
            with open(hist_file, "r", encoding="utf-8") as f:
                for line in f:
                    try:
                        entry = json.loads(line)
                        ts = entry.get("timestamp", 0)
                        if ts >= five_hrs_ago:
                            five_hr_turns += 1
                        if ts >= seven_days_ago:
                            seven_day_turns += 1
                    except Exception:
                        pass
        except Exception:
            pass

    # Free tier / quota simulation / limit window display
    res["five_hour"] = {
        "remaining_percent": max(0.0, 100.0 - (five_hr_turns * 2.0)),
        "resets_at_str": (now_utc + datetime.timedelta(hours=5)).astimezone(datetime.timezone(datetime.timedelta(hours=9))).strftime("%m/%d %H:%M JST"),
        "remaining_desc": f"直近5時間消費: {five_hr_turns}ターン",
    }
    res["seven_day"] = {
        "remaining_percent": max(0.0, 100.0 - (seven_day_turns * 0.8)),
        "resets_at_str": (now_utc + datetime.timedelta(days=7)).astimezone(datetime.timezone(datetime.timedelta(hours=9))).strftime("%m/%d %H:%M JST"),
        "remaining_desc": f"直近7日間消費: {seven_day_turns}ターン",
    }
    return res


GROK_LOG_FILE = Path("D:/grok/logs/unified.jsonl")
GROK_BILLING_MSG = "billing: fetched credits config"
SCRIPT_PATH = Path(__file__).resolve()


def _find_last_grok_billing_entry() -> dict | None:
    """Grok CLI が起動時にログへ書く課金情報のうち、最新の1件を末尾から探す。"""
    if not GROK_LOG_FILE.exists():
        return None
    chunk = 1024 * 1024
    with open(GROK_LOG_FILE, "rb") as f:
        f.seek(0, os.SEEK_END)
        pos = f.tell()
        tail = b""
        while pos > 0:
            step = min(chunk, pos)
            pos -= step
            f.seek(pos)
            buf = f.read(step) + tail
            lines = buf.split(b"\n")
            tail = lines[0] if pos > 0 else b""
            body = lines[1:] if pos > 0 else lines
            for line in reversed(body):
                if GROK_BILLING_MSG.encode() in line:
                    try:
                        return json.loads(line.decode("utf-8"))
                    except Exception:
                        continue
    return None


def fetch_grok_status() -> dict:
    """Grok CLI のログに残る最新の課金情報（起動時に記録）を読む。無ければ取得不能として扱う。"""
    res = {"status": "unavailable", "email": "不明", "plan": "不明"}
    try:
        entry = _find_last_grok_billing_entry()
    except Exception:
        entry = None
    if entry:
        ctx = entry.get("ctx", {})
        cfg = ctx.get("config", {})
        used = cfg.get("creditUsagePercent")
        end_iso = cfg.get("currentPeriod", {}).get("end") or cfg.get("billingPeriodEnd")
        if used is not None and end_iso:
            res["status"] = "ok"
            res["plan"] = ctx.get("subscriptionTier") or "不明"
            res["remaining_percent"] = max(0.0, 100.0 - float(used))
            res["reset_at_str"] = format_iso_jst(end_iso)
            res["recorded_at_str"] = format_iso_jst(entry.get("ts", ""))
            end_dt = datetime.datetime.fromisoformat(end_iso.replace("Z", "+00:00"))
            diff = int((end_dt - datetime.datetime.now(datetime.timezone.utc)).total_seconds())
            res["period_ended"] = diff <= 0
            res["remaining_desc"] = format_remaining_seconds(diff) if diff > 0 else "リセット済み"

    # Read email from D:/grok/auth.json
    grok_auth = Path("D:/grok/auth.json")
    if grok_auth.exists():
        try:
            with open(grok_auth, "r", encoding="utf-8") as f:
                d = json.load(f)
            auth_entry = list(d.values())[0]
            res["email"] = auth_entry.get("email", res["email"])
        except Exception:
            pass

    return res


# ==============================================================================
# 5. CLI Rendering
# ==============================================================================
def print_dashboard():
    print("\n" + "=" * 64)
    print(" 🚀 AI クォータ & 残り利用量 モニター (SD003)")
    print("=" * 64)

    # 1. Claude Code
    print("\n[ 1. Claude Code ]")
    claude = fetch_claude_usage()
    if claude["status"] == "ok":
        fh = claude.get("five_hour")
        if fh:
            bar = get_progress_bar(fh["remaining_percent"])
            print(f"  5時間枠   : 残り {bar}  | 期限: {fh['resets_at_str']} ({fh['remaining_desc']})")
        sd = claude.get("seven_day")
        if sd:
            bar = get_progress_bar(sd["remaining_percent"])
            print(f"  7日間枠   : 残り {bar}  | 期限: {sd['resets_at_str']} ({sd['remaining_desc']})")
    else:
        print(f"  取得エラー : {claude.get('error')}")

    # 2. Codex Accounts
    print("\n[ 2. OpenAI Codex (4アカウント) ]")
    codex_accs = get_all_codex_accounts()
    if not codex_accs:
        print("  Codex の認証情報が見つかりません。")
    else:
        for acc in codex_accs:
            active_marker = "★ [Active]" if acc.get("is_active") else "   [Saved] "
            label = acc.get("label", "Codex")
            if acc["status"] == "ok":
                email = acc.get("email", "不明")
                acc_id = acc.get("account_id", "")
                alias = ACCOUNT_ALIASES.get(acc_id, ACCOUNT_ALIASES.get(email))
                account_tag = f"{email} / {alias}" if alias and alias != email else email
                pri = acc.get("primary")
                sec = acc.get("secondary")
                is_snap = acc.get("is_snapshot", False)
                snap_time = acc.get("snapshot_time", "")
                suffix = f" (ログアウト記録: {snap_time})" if is_snap and snap_time else ""

                pri_win_sec = pri.get("limit_window_seconds", 0) if pri else 0
                pri_reset_sec = pri.get("reset_after_seconds", 0) if pri else 0
                # If secondary exists, primary is short-term. If no secondary, check window length or reset time
                if sec is not None:
                    pri_label = "短時間枠"
                elif pri_win_sec >= 86400 * 2 or pri_reset_sec > 86400:
                    pri_label = "週間枠  "
                else:
                    pri_label = "枠残量  "

                print(f"  {active_marker} {label} ({account_tag}){suffix}")
                if pri:
                    bar = get_progress_bar(pri["remaining_percent"])
                    print(f"       {pri_label}: 残り {bar} | 期限: {pri['resets_at_str']} ({pri['remaining_desc']})")
                if sec:
                    bar2 = get_progress_bar(sec["remaining_percent"])
                    print(f"       週間枠  : 残り {bar2} | 期限: {sec['resets_at_str']} ({sec['remaining_desc']})")
            else:
                print(f"  {active_marker} {label}: 取得エラー ({acc.get('error')})")

    # 3. Antigravity (agy)
    print("\n[ 3. Google Antigravity (agy) ]")
    agy = fetch_agy_status()
    print(f"  モデル    : {agy.get('model')}")
    afh = agy.get("five_hour")
    if afh:
        bar = get_progress_bar(afh["remaining_percent"])
        print(f"  5時間枠   : 残り {bar}  | 期限: {afh['resets_at_str']} ({afh['remaining_desc']})")
    asd = agy.get("seven_day")
    if asd:
        bar = get_progress_bar(asd["remaining_percent"])
        print(f"  7日間枠   : 残り {bar}  | 期限: {asd['resets_at_str']} ({asd['remaining_desc']})")

    # 4. Grok (xAI)
    print("\n[ 4. xAI Grok (grok) ]")
    grok = fetch_grok_status()
    email = grok.get("email", "不明")
    plan = grok.get("plan", "SuperGrok")
    print(f"  アカウント : {email} ({plan})")
    if grok["status"] != "ok":
        print(f"  週間枠     : 取得できません（{GROK_LOG_FILE} に課金情報の記録がありません）")
    elif grok["period_ended"]:
        print(f"  週間枠     : {grok['reset_at_str']} にリセット済み（新しい残量は Grok を一度起動すると記録されます）")
    else:
        bar = get_progress_bar(grok["remaining_percent"])
        print(f"  週間枠     : 残り {bar}  | 期限: {grok['reset_at_str']} ({grok['remaining_desc']})")
    if grok["status"] == "ok":
        print(f"  記録時刻   : {grok['recorded_at_str']}（Grok 起動時点の値。以降の消費は反映されません）")

    print("\n" + "-" * 64)
    print(" 💡 Codex アカウントの切替 (番号選択):")
    print(f"   ・メニューを開く : python {SCRIPT_PATH} --switch")
    print(f"   ・現在アカウント保存: python {SCRIPT_PATH} --save-codex <名前>")
    print("=" * 64 + "\n")


def main():
    parser = argparse.ArgumentParser(description="SD003 AI Usage Monitor")
    parser.add_argument("--save-codex", metavar="LABEL", help="現在のアカウントをLABELとして保存")
    parser.add_argument("--switch-codex", nargs="?", const="", metavar="LABEL", help="アカウント切り替え（引数なしで番号選択メニュー）")
    parser.add_argument("--switch", action="store_true", help="アカウント番号選択メニューを開く")
    parser.add_argument("--list-codex", action="store_true", help="保存済みアカウント一覧を表示")
    args = parser.parse_args()

    if args.save_codex:
        save_current_codex(args.save_codex)
    elif args.switch or args.switch_codex == "":
        interactive_switch_codex()
    elif args.switch_codex:
        switch_codex(args.switch_codex)
    elif args.list_codex:
        list_saved_codex()
    else:
        print_dashboard()


if __name__ == "__main__":
    main()
