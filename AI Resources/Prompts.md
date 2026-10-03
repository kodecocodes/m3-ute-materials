# Prompts

## Lesson 1: Using AI for Testing in iOS

### Demo: From Audits to a Test Plan

**Prompt 1: Consolidate Audits Into a Test Plan**

```text
The files, "Acceptance-CornerCases-Audit.md", "Goals-NonGoals-Audit.md", "Dynamic-Type-Audit.md", "SwiftSurface-Audit.md", "VoiceOver-Audit.md" are all audits against a feature implemented by "reviewed-feature-plan.md" and "execution-plan.md".  All those files are on the same folder as the project file itself.
The plan intentionally skipped the addition of the tests. I want you to consolidate the audit files and create a new plan for the new tests to be implemented. Ensure that the tests are meaningful and the plan guarantees fixes for all the outcomes of the audit and creates valuable tests that ensures they wouldn't break by accident in the future with future changes. This plan needs to include some details on each test that will be introduced:
- Name of test
- Function(s) it will cover
- Description on what the test will cover
- Assertions and what data the test will check to fail or succeed on.
```

**Prompt 2: Implement the Test Plan Using Workflows**

```text
Implement the plan using workflows. skip the optional points and don't implement UI Tests now, only focus on Unit Tests
```

**Prompt 3: Confirm the Audit Findings Are Fixed**

```text
Revise again that the issues found in the audits are fixed
```

## Lesson 2: Testing the Running App and Debugging With AI

### Demo 01: Testing the Running App With an AI Agent

**Prompt 1: Run the Plain-English Test Steps Against the Simulator**

```text
/device-interaction run UI tests in "test-plan.md" directly in the simulator within the AI session and report findings. Those Tests were meant to be implemented in TokensDashboardUITests.swift. Fix issues as you find them then confirm its fixed.
Don't Implement actual UI tests for now.
Use `xcrun simctl` commands to control the simulator settings for dynamic type or any accessibility settings.
Run only 1 test not all the cases and explain the findings as the test is running for Demo purposes
```

### Demo 02: AI Breakpoints

**Prompt 1: Debug the App Through Breakpoints and the Console**

```text
I want you to debug the app and use breakpoints while running the app and report the usage insights directly from the debugger by capturing it from the init of UsageInsightsView. I'll navigate to the screen myself once u confirm the breakpoint is ready.
use "AI-BREAKPOINT-GUIDE.md" for instructions for the breakpoint setup

Capture the data and show the information captured after each breakpoint.
This is only a demo for the debugging controls agentic AI has with Xcode 27. no bugs and no fixes needed, only printing the data caught from the debugging session into the conversation.
```
