# DONE - 2026-03-28 16:11
## Completed
- Hook isolation 7/7 PASS
- Root cause: Claude Code runtime deletes `.sd/` by name
- Fix: `.sd/` → `.sd/` rename, fully stable
## Next
- P0: Full `.sd/` → `.sd/` migration across framework
- P1: Deploy to all projects + file bug report
