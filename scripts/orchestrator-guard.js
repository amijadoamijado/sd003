#!/usr/bin/env node
// Shared PreToolUse guard for Claude Code, Codex, and the orchestration runner.
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  let payload = {};
  try { payload = JSON.parse(input || '{}'); } catch { payload = {}; }
  const toolInput = payload.tool_input || payload.toolInput || payload.input || {};
  const command = String(toolInput.command || payload.command || '');
  const filePath = String(toolInput.file_path || toolInput.filePath || payload.file_path || '');
  const normalized = `${command}\n${filePath}`.replace(/\\/g, '/');
  const rules = [
    [/\bclasp\s+undeploy\b/i, 'clasp undeploy is prohibited'],
    [/\bclasp\s+deploy\b(?![^;&|]*(?:-i|--deploymentId)\s+\S+)/i, 'new clasp deploy is prohibited; use clasp push or an explicitly authorized existing deployment update'],
    [/\bgit\s+(?:-C\s+\S+\s+)?(?:checkout|restore)\b[^;&|]*(?:^|\s)(?:\.|\.sd(?:\/|\s|$))/im, 'destructive checkout/restore of the repository or .sd is prohibited'],
    [/\bgit\s+reset\s+--hard\b/i, 'git reset --hard is prohibited'],
    [/\bgit\s+clean\b/i, 'git clean is prohibited'],
    [/\bgit\s+add\s+-A\b/i, 'repository-wide staging is prohibited; stage explicit paths'],
    [/\b(?:rm|mv)\b[^;&|]*(?:^|[\/\s])\.sd(?:[\/\s]|$)/im, 'destructive operation on .sd is prohibited'],
    [/\bRemove-Item\b[^\n]*(?:^|[\/\s])\.sd(?:[\/\s]|$)/im, 'Remove-Item on .sd is prohibited']
  ];
  const match = rules.find(([pattern]) => pattern.test(normalized));
  if (!match) process.exit(0);
  const reason = `BLOCKED: ${match[1]}`;
  process.stdout.write(JSON.stringify({ hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: 'deny', permissionDecisionReason: reason } }));
});
