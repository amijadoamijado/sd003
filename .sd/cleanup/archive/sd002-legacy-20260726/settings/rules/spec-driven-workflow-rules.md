# Spec-Driven Workflow Rules

## Workflow Order (STRICT)
1. ✅ **Requirements First**: Define user stories and acceptance criteria
2. ✅ **Design Second**: Create technical design after requirements approval
3. ✅ **Tasks Third**: Break down implementation after design approval
4. ✅ **Implementation Last**: Code only after all specs are approved

## Requirements Phase
- ✅ **REQUIRED**: Use EARS notation for user stories
- ✅ **REQUIRED**: Define acceptance criteria before design
- ✅ **REQUIRED**: Identify dependencies and out-of-scope items
- ❌ **FORBIDDEN**: Starting design before requirements approval
- ❌ **FORBIDDEN**: Vague or ambiguous requirements

## Design Phase
- ✅ **REQUIRED**: Architecture diagram for complex features
- ✅ **REQUIRED**: API contracts defined before implementation
- ✅ **REQUIRED**: Testing strategy outlined
- ✅ **REQUIRED**: Security and performance considerations documented
- ❌ **FORBIDDEN**: Starting implementation before design approval
- ❌ **FORBIDDEN**: Design without traceability to requirements

## Tasks Phase
- ✅ **REQUIRED**: Break design into atomic tasks
- ✅ **REQUIRED**: Define dependencies between tasks
- ✅ **REQUIRED**: Estimate effort for each task
- ✅ **REQUIRED**: Link tasks to design elements
- ❌ **FORBIDDEN**: Tasks without clear acceptance criteria
- ❌ **FORBIDDEN**: Starting implementation before task breakdown

## Implementation Phase
- ✅ **REQUIRED**: Follow task order and dependencies
- ✅ **REQUIRED**: Pass all 8 quality gates before deployment
- ✅ **REQUIRED**: Update traceability matrix
- ✅ **REQUIRED**: Document actual vs. estimated effort
- ❌ **FORBIDDEN**: Skipping quality gates
- ❌ **FORBIDDEN**: Implementing features not in spec

## Traceability Requirements
- ✅ **REQUIRED**: Every requirement has ID
- ✅ **REQUIRED**: Every design element links to requirement
- ✅ **REQUIRED**: Every task links to design element
- ✅ **REQUIRED**: Every test links to requirement
- ✅ **REQUIRED**: Maintain traceability matrix up-to-date

## Change Management
- ✅ **REQUIRED**: Document all spec changes
- ✅ **REQUIRED**: Re-approve changed specs
- ✅ **REQUIRED**: Update downstream artifacts (design, tasks, code)
- ❌ **FORBIDDEN**: Changing implementation without updating spec
- ❌ **FORBIDDEN**: Undocumented requirement changes
