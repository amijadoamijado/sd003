#!/usr/bin/env node
// Shared PreToolUse guard for Claude Code, Codex, and the orchestration runner.
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  let payload = {};
  try { payload = JSON.parse(input || '{}'); } catch { payload = {}; }

  const toolName = String(payload.tool_name || payload.toolName || payload.name || '');
  const toolInput = payload.tool_input || payload.toolInput || payload.input || {};
  const command = String(toolInput.command || payload.command || '');
  const filePath = String(toolInput.file_path || toolInput.filePath || payload.file_path || '');
  const normalized = `${command}\n${filePath}`.replace(/\\/g, '/');

  // Patch payloads contain arbitrary documentation and code. Do not run shell-command
  // regexes over that text. Only block structurally destructive directives against .sd.
  const isPatch = /apply[_-]?patch/i.test(toolName) || command.startsWith('*** Begin Patch');
  if (isPatch) {
    const destructivePatch = /^\*\*\* (?:Delete File|Move to): .*\/\.sd(?:\/|$)/im;
    if (!destructivePatch.test(normalized)) process.exit(0);
    return deny('destructive patch operation on .sd is prohibited');
  }

  const rules = [
    [/\bclasp\s+undeploy\b/i, 'GAS deployment deletion is prohibited'],
    [/\bclasp\s+deploy\b(?![^;&|]*(?:-i|--deploymentId)\s+\S+)/i, 'new GAS deployment creation is prohibited; use push or an explicitly authorized existing deployment update'],
    [/\bgit(?:\s+-C\s+(?:"[^"]+"|'[^']+'|\S+))*\s+(?:checkout|restore)\b[^;&|]*(?:^|\s)(?:\.|\.sd(?:\/|\s|$))/im, 'destructive checkout/restore of the repository or .sd is prohibited'],
    [/\bgit(?:\s+-C\s+(?:"[^"]+"|'[^']+'|\S+))*\s+reset\s+--hard\b/i, 'hard reset is prohibited'],
    [/\bgit(?:\s+-C\s+(?:"[^"]+"|'[^']+'|\S+))*\s+clean\b/i, 'repository clean is prohibited'],
    [/\bgit(?:\s+-C\s+(?:"[^"]+"|'[^']+'|\S+))*\s+stash\b/i, 'stash is prohibited because it can capture another agent\'s work'],
    [/\bgit(?:\s+-C\s+(?:"[^"]+"|'[^']+'|\S+))*\s+add\s+(?:-A|--all)\b/i, 'repository-wide staging is prohibited; stage explicit paths'],
    [/\b(?:rm|mv|rmdir)\b[^;&|]*(?:^|[\/\s])\.sd(?:[\/\s]|$)/im, 'destructive operation on .sd is prohibited'],
    [/\b(?:Remove-Item|Move-Item)\b[^\n]*(?:^|[\/\s])\.sd(?:[\/\s]|$)/im, 'PowerShell destructive operation on .sd is prohibited'],
    [/\bcmd(?:\.exe)?\s+\/c\s+(?:rd|rmdir|del|move)\b[^\n]*(?:^|[\/\s])\.sd(?:[\/\s]|$)/im, 'cmd destructive operation on .sd is prohibited']
  ];
  const match = rules.find(([pattern]) => pattern.test(normalized));
  if (!match) process.exit(0);
  deny(match[1]);

  function deny(message) {
    const reason = `BLOCKED: ${message}`;
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'deny',
        permissionDecisionReason: reason
      }
    }));
  }
});
