export type StageStatus = 'pending' | 'running' | 'succeeded' | 'failed' | 'skipped';
export interface ProviderDefinition { command: string; args: string[]; timeoutMs?: number; }
export interface StageDefinition { id: string; role: 'implementer' | 'reviewer' | 'tester'; provider: string; required?: boolean; }
export interface OrchestratorScenario {
  version: 1; id: string; task: string; workspace: string; evidenceDir: string; orchestrator: string;
  providers: Record<string, ProviderDefinition>; stages: StageDefinition[]; expectedArtifacts: string[];
  allowDirtyWorkspace?: boolean;
}
export interface StageResult extends StageDefinition {
  status: StageStatus; startedAt?: string; completedAt?: string; exitCode?: number; stdout?: string; stderr?: string;
}
export interface RunManifest {
  contractVersion: 1; runId: string; scenarioId: string; task: string; orchestrator: string; workspace: string;
  status: 'running' | 'succeeded' | 'failed'; startedAt: string; completedAt?: string;
  stages: StageResult[]; artifacts: string[]; error?: string;
}
