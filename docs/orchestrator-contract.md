# SD003 AI-Neutral Orchestrator Contract

## Principle

The orchestrator is a role, not a product. Claude, Codex, Antigravity, Grok, or a deterministic local provider may fill any role when its configured capabilities satisfy the scenario. The `orchestrator` field is an accountability label; the deterministic runner remains the execution authority.

## Roles

| Role | Responsibility | Required output |
|---|---|---|
| orchestrator | Read the task, select and sequence roles, own final state | run manifest |
| implementer | Produce the requested change or deliverable | declared artifacts |
| reviewer | Evaluate the implementation and return an explicit decision | review artifact or successful exit |
| tester | Execute verification and preserve evidence | test artifact or successful exit |

Role names are stable. Provider names are replaceable.

## State model

Each stage moves through `pending -> running -> succeeded|failed|skipped`. A run is successful only when every stage succeeds and every expected artifact exists. Provider unavailability, non-zero exit, timeout, and missing artifacts are failures; none may be rewritten as success.

## Safety invariants

1. Never stage, commit, reset, restore, deploy, or delete user files implicitly.
2. Execute providers without an intermediate shell. Commands are an executable plus an argument array.
3. Write run evidence only under the configured evidence directory.
4. Refuse a dirty Git workspace unless the scenario explicitly permits it.
5. Preserve stdout, stderr, exit code, timestamps, role, and provider in the run manifest.
6. `clasp deploy` and `clasp undeploy` remain prohibited without explicit user authorization.

## Completion contract

A run is complete only when:

- all stages reached `succeeded`;
- expected artifacts exist inside the configured workspace;
- the manifest was written;
- the runner exits with code 0.

Any mismatch produces a failed manifest and non-zero process exit.

## Scenario contract

Scenarios are JSON documents containing:

- `id`, `task`, `workspace`, and `evidenceDir`;
- `orchestrator`, identifying the provider that owns the run;
- `providers`, executable/argument definitions;
- ordered `stages`, each mapping a role to a provider;
- `expectedArtifacts` relative to the workspace;
- optional `allowDirtyWorkspace` for an explicitly accepted dirty repository.

Arguments may use `${workspace}`, `${evidenceDir}`, `${runId}`, `${task}`, `${stage}`, and `${role}` placeholders.

On Windows PowerShell, use a positional scenario path through npm because some `npm.ps1` versions consume long options:

```powershell
npm run orchestrate -- config/orchestrator.codex-e2e.json
npm run orchestrate:dry-run -- config/orchestrator.codex-e2e.json
```

Direct Node invocation continues to support `--scenario` and `--dry-run` normally.

Non-interactive Grok stages require `bypassPermissions` with Grok CLI 0.2.93; `acceptEdits` may return exit code 0 while reporting `PermissionCancelled`. Because bypass mode is intentionally non-interactive, use it only with an isolated workspace and explicit expected artifacts. The runner treats a permission-cancellation marker as a failed stage even when the provider exits with code 0.

Until cancellation markers are measured and registered for Claude and agy, scenarios using either provider must declare per-stage `expectedArtifacts`.

## Compatibility

Existing Claude/Codex/agy/Grok skills remain adapters. They must translate into this contract rather than redefine state or completion. The TypeScript runner is the canonical execution path; Bash and PowerShell entrypoints, when retained, are thin wrappers only.
