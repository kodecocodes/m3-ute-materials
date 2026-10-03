# Token Usage

This document outlines the approximate token usage in this module.

## Tools for Measuring Token Count

### Claude Agent in Xcode

In Xcode 27, Xcode and Claude don't show the token count. Therefore, [**ccusage**](https://ccusage.com) calculated the tokens.

## Important Caveats Before Proceeding

Here are a few key points:

- The numbers reported here are approximate.
- Token counts can vary significantly depending on the model used.
- AI output can vary on every run.
- The second model row in a demo's totals (`sonnet-4-6`) represents tokens consumed by subagents spawned during that conversation — not a separate manual step.
- Throughout this course, use `/usage` in an Xcode conversation with Claude Agent to learn more about your usage quota and costs.

## Token Usage for Claude Agent in Xcode

### From Audits to a Test Plan

| Model | Input | Cache Create | Cache Read | Output | Total Tokens |
| ---: | ---: | ---: | ---: | ---: | ---: |
|sonnet-5 | 170 | 951,195 | 19,263,320 | 125,999 | |
|sonnet-4-6 | 74 | 251,140 | 1,506,098 | 19,590 | |
|**Total** | | | | | **~22,117,586** |

**Per-prompt breakdown**

*Prompt 1: Consolidate Audits Into a Test Plan*

| Model | Input | Cache Create | Cache Read | Output | Total Tokens |
| ---: | ---: | ---: | ---: | ---: | ---: |
|sonnet-5 | 44 | 97,505 | 2,296,522 | 32,247 | **~2,426,318** |

*Prompt 2: Implement the Test Plan Using Workflows*

| Model | Input | Cache Create | Cache Read | Output | Total Tokens |
| ---: | ---: | ---: | ---: | ---: | ---: |
|sonnet-5 | 114 | 840,266 | 14,906,704 | 81,011 | |
|sonnet-4-6 | 74 | 251,140 | 1,506,098 | 19,590 | |
|**Total** | | | | | **~17,604,997** |

> Prompt 2 is where the agent spawned subagents to implement the test plan in parallel — the `sonnet-4-6` row is the combined cost of every subagent it launched.

*Prompt 3: Confirm the Audit Findings Are Fixed*

| Model | Input | Cache Create | Cache Read | Output | Total Tokens |
| ---: | ---: | ---: | ---: | ---: | ---: |
|sonnet-5 | 12 | 13,424 | 2,060,094 | 12,741 | **~2,086,271** |

### Testing the Running App With an AI Agent

| Model | Input | Cache Create | Cache Read | Output | Total Tokens |
| ---: | ---: | ---: | ---: | ---: | ---: |
|sonnet-5 | 52 | 370,707 | 3,897,398 | 14,099 | |
|sonnet-4-6 | 45 | 88,456 | 1,798,453 | 7,283 | |
|**Total** | | | | | **~6,176,493** |

This demo is a single prompt (`/device-interaction`), so the per-prompt total is the same as the demo total above — the `sonnet-4-6` row is the subagent cost of running the simulator-driven test steps.

### AI Breakpoints

| Model | Input | Cache Create | Cache Read | Output | Total Tokens |
| ---: | ---: | ---: | ---: | ---: | ---: |
|sonnet-5 | 44 | 22,673 | 1,675,438 | 6,071 | **~1,704,226** |

This demo is also a single prompt, with no subagents spawned — the per-prompt total matches the demo total above.
