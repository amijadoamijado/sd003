# Bug Trace Log

/bug-trace コマンドで調査した問題の記録。
3エージェント並列調査の結果と解決策を蓄積する。

---

## Log Entry Template

```markdown
## YYYY-MM-DD [Bug Title]

### Error Summary
[Original error message or description]

### 3-Agent Findings

#### Spec Agent
- Key finding: [specification insight]
- Expected behavior: [what should happen]

#### Code Agent
- Key finding: [code insight]
- Trace: [entry -> step1 -> step2 -> ... -> error]

#### Solution Agent
- Hypothesis: [most likely cause]
- Confidence: High/Medium/Low

### Root Cause
[Confirmed cause after investigation]

### Process Flow Divergence
Expected: [expected flow]
Actual: [actual flow]
Divergence at: [specific step]

### Solution Applied
[What was fixed and how]

### Prevention Measures
[How to prevent recurrence]
```

---

<!-- New entries above this line -->
