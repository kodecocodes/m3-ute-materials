# Test Plan: AI Usage Insights

Companion to `reviewed-feature-plan.md` and `execution-plan.md`. Consolidates the five audit
reports (`Acceptance-CornerCases-Audit.md`, `Goals-NonGoals-Audit.md`, `SwiftSurface-Audit.md`,
`Dynamic-Type-Audit.md`, `VoiceOver-Audit.md`) into one findings list, resolves each finding into
either a code fix or a documented decision, and specifies the concrete automated tests that close
the reviewed plan's missing "Automated tests cover..." acceptance criterion — and keep it closed
against future changes.

`execution-plan.md` explicitly deferred all automated tests ("out of scope for this execution plan
— edge-case states are verified via Xcode Previews instead"). All three functional audits
independently flagged that deferral as an unmet acceptance criterion, since that waiver was never
reflected back into `reviewed-feature-plan.md` itself. This plan reverses the deferral.

A unit test target (`TokensDashboardTests`, Swift Testing) already exists in the project with one
placeholder test. No new target/scheme wiring is required for the unit-test work below; only the
optional UI-test task (T9) needs a new target.

## Implementation status

T1, T2, and T5 (prerequisite fixes) and the four unit-test files below (`UsageInsightBuilderTests.swift`,
`UsageInsightModelTests.swift`, `UsageInsightsViewModelTests.swift`, `SummaryViewModelTests.swift`)
have been implemented. All 45 tests pass (`xcodebuild test`). T6 (builder-driven previews), T9 (UI
tests), and the optional T10/T11 were explicitly out of scope for this pass per instruction to
focus on unit tests only.

One additional bug was found and fixed only while verifying the real pipeline end-to-end
(`UsageInsightsViewModelTests.defaultInitProducesNonEmptyInsightsFromRealPipeline`, which exercises
the real `AIUsagePeriodStore` rather than hand-built fixtures): `AIUsagePeriodStore` computed its
30-day windows using `Calendar.current` (the local/device timezone). Because the preceding window
(early March–March 31, 2026) spans a DST "spring forward" transition while the reporting window
(April) does not, the two periods differed by exactly one hour in absolute elapsed seconds despite
both being nominally "30 days" — tripping T1's new equal-length guard and silently producing
`.insufficientData` in the shipped app. Fixed by computing the four period boundaries with a
UTC-anchored `Calendar` instead of `Calendar.current`, so the windows are DST-independent. This is
exactly the kind of regression the acceptance criterion's "period alignment and completeness"
coverage is meant to catch, and it would not have been caught by any test that only exercises
hand-built `AIUsagePeriod` fixtures — the real-pipeline smoke test was essential.

---

## Consolidated findings

Every negative finding across the five audits, deduplicated. "Resolution" says whether this plan
fixes code, adds a test that locks in existing (correct) behavior, or documents a decision without
a code change.

| # | Finding | Source audit(s) | Severity | Resolution | Task |
| --- | --- | --- | --- | --- | --- |
| 1 | Zero automated tests exist; the reviewed plan's acceptance criteria explicitly require them | All three functional audits | High | Fix: add the full test suite below | T3, T6, T7, T8 |
| 2 | Mock periods are unequal-length calendar months (30 vs. 31 days); the builder never checks period length | Acceptance-CornerCases, Goals-NonGoals, SwiftSurface | High | Fix: fixed-length mock windows + builder equal-length guard | T1 |
| 3 | Preview fixtures bypass the builder for 3 of 4 states — thresholds, boundaries, tie-breaks, and below-minimum paths are exercised by nothing | Acceptance-CornerCases, Goals-NonGoals, SwiftSurface | High | Fix: unit tests drive the builder directly; previews reworked to match | T3, T5 |
| 4 | VoiceOver label derives from `category.rawValue.capitalized` → announces "Modelmix" | Acceptance-CornerCases, Goals-NonGoals, SwiftSurface, VoiceOver | Medium | Fix: move label composition into a testable model property using `title` | T2, T4 |
| 5 | `InsightCardView`'s card title carries no `.isHeader` trait — invisible to VoiceOver's Headings rotor | VoiceOver | Medium | Fix: add the trait; UI accessibility audit locks it in | T2, T9 |
| 6 | Ambiguous plan case (one category valid-but-below-threshold + the other invalid) is resolved to `insufficientData` only in a code comment, never in the plan | Acceptance-CornerCases, SwiftSurface | Medium | Document as ratified behavior in `reviewed-feature-plan.md`; test locks it in | T3 |
| 7 | Table-vs-prose conflict: does the 1,000,000-token minimum-volume floor gate model mix, or only activity? | Goals-NonGoals, SwiftSurface | Medium | Resolve: apply the shared floor to model mix too; test locks it in — **flag to plan owner before merging, this changes behavior** | T1, T3 |
| 8 | `AIUsagePeriod` has no explicit timezone/calendar-convention field | Acceptance-CornerCases, SwiftSurface | Medium | Accept as a documented v1 simplification (local mock data only, no real backend); no code change, no test | — |
| 9 | `Configuration` doesn't surface the tie-breaker or max-card-count as data | Acceptance-CornerCases, SwiftSurface | Low | Accept as-is for v1; test pins the current hardcoded behavior so a silent change is caught | T3 |
| 10 | Mock `contributorCount` is hardcoded to 42; privacy-floor/incomplete-period paths never run outside a hand-built state | Goals-NonGoals | Low | Not a defect — fully addressed for testing purposes since T3's tests construct `AIUsagePeriod` directly, bypassing the mock store | T3 |
| 11 | `SummaryView`'s page title is missing `.isHeader` | VoiceOver | Medium | Pre-existing, outside the AI Usage Insights feature diff — optional | T10 (optional) |
| 12 | Donut chart overlay text can clip at large accessibility Dynamic Type sizes | Dynamic Type | Medium | Pre-existing, outside the AI Usage Insights feature diff — optional | T11 (optional) |

Findings 11–12 are pre-existing issues the Dynamic-Type and VoiceOver audits surfaced while
scanning every view file in the app, not defects introduced by this feature. They're kept as
optional, separately-approvable tasks rather than folded silently into this feature's test work —
consistent with the reviewed plan's own instruction not to modify unrelated screens.

---

## Decisions this plan makes (flag before merging if any are wrong)

- **Equal-length periods (Finding 2):** Switch `AIUsagePeriodStore` from calendar-month boundaries
  to two fixed 30-day windows anchored to `DashboardStartDate.today`, **and** add a defensive
  equal-length guard inside `UsageInsightBuilder` that invalidates both categories if the two
  supplied periods ever have different lengths. The mock fix satisfies the acceptance criterion
  today; the builder guard keeps it satisfied if the data source ever changes.
- **Model-mix minimum-volume floor (Finding 7):** Apply `configuration.minimumComparisonVolume` to
  both of model mix's totals, in addition to the existing `> 0` check, so the shared-precondition
  reading of the rule-configuration table wins over the narrower model-mix prose. This is a
  **behavior change**, not a pure test addition. It does not change the shipped mock scenario's
  output (both mock periods are already ~40–50M tokens).
- **Mixed-validity → `insufficientData` (Finding 6):** Ratify the existing implementation's
  interpretation (already explained in a doc comment on `UsageInsightsState`) as intended
  behavior, and promote it from a code comment into `reviewed-feature-plan.md`'s "State rules"
  section.
- **Timezone/calendar field (Finding 8):** Not adding it. Every period is local mock data under
  `Calendar.current` with no real backend in v1, so the field would always hold one value with no
  way to violate it and no meaningful test to write against it.
- **`Configuration` surface (Finding 9):** Not restructuring for v1. Tests pin the current
  hardcoded tie-break and two-category behavior so a future silent change is caught by CI instead
  of by the next manual audit.
- **VoiceOver label fix (Finding 4):** Rather than patching the string only inside
  `InsightCardView` (a private SwiftUI view, not independently testable without a UI-testing
  framework), add a computed `accessibilityLabel: String` property directly on `UsageInsight` in
  `Models/UsageInsight.swift`, built from `title` (not `category.rawValue`). The view becomes a
  one-line call-site (`.accessibilityLabel(insight.accessibilityLabel)`), and the label composition
  itself becomes a plain, unit-testable model property.

---

## Prerequisite code changes

These are small, targeted fixes the tests below depend on. Without them, several tests would just
document existing bugs instead of locking in correct behavior.

### T1 — Fix equal-length period contract and model-mix volume floor

- **Files:** `Models/AIUsagePeriod.swift`, `Models/UsageInsightBuilder.swift`
- Change `AIUsagePeriodStore` to build both periods as fixed 30-day windows instead of calendar
  months.
- Add a private equal-length guard in `UsageInsightBuilder.build(reportingPeriod:precedingPeriod:)`
  (e.g. compare `end.timeIntervalSince(start)` for both periods) that treats **both** categories as
  invalid when the lengths differ.
- Add `reportingPeriod.totalTokens >= configuration.minimumComparisonVolume` and the equivalent for
  `precedingPeriod` to `buildModelMixInsight`'s guard clause, alongside its existing `> 0` check.

### T2 — Fix VoiceOver label and header traits

- **Files:** `Models/UsageInsight.swift`, `Views/UsageInsightsView.swift`
- Add a computed `accessibilityLabel: String` property to `UsageInsight` composed from `title`
  (not `category.rawValue.capitalized`), matching the visible category name.
- Update `InsightCardView` to call `insight.accessibilityLabel` instead of building the string
  inline.
- Add `.accessibilityAddTraits(.isHeader)` to `InsightCardView`'s existing
  `.accessibilityElement(children: .combine)` container.

### T5 — Ratify the mixed-validity state rule

- **Files:** `reviewed-feature-plan.md` ("State rules" section)
- Add an explicit bullet: "When one category is validly comparable but does not qualify, and the
  other category cannot be compared at all, show `insufficientData`." Documentation-only; the
  behavior already exists.

### Optional, out-of-feature (require separate approval)

- **T10:** Add `.accessibilityAddTraits(.isHeader)` to `SummaryView`'s page title (Finding 11).
- **T11:** Fix `CostbyModelView`'s donut overlay clipping risk via `@ScaledMetric` or
  `.dynamicTypeSize(...up to:)` (Finding 12).

---

## Detailed test specifications

All unit tests use the Swift Testing framework (`import Testing`) in the existing
`TokensDashboardTests` target. Boundary/threshold cases use `@Test(arguments:)` parameterization
where noted, rather than duplicated test functions. Every `AIUsagePeriod` value in
`UsageInsightBuilderTests` is hand-constructed in the test itself — none of these tests depend on
`AIUsagePeriodStore` or `DashboardStartDate.today`, so they can't be broken by mock-data changes.

### File: `UsageInsightBuilderTests.swift`

Covers `UsageInsightBuilder.build(reportingPeriod:precedingPeriod:)` and its private
`buildActivityInsight` / `buildModelMixInsight` rules (exercised only through `build`, since they
are private).

| Test name | Function(s) covered | Description | Assertions / data |
| --- | --- | --- | --- |
| `activityQualifies_atOrAboveThreshold` | `build` (activity path) | Parameterized over relative changes of exactly 15.0%, 18%, and 25%, both periods otherwise valid (≥10 contributors, ≥1,000,000 tokens, complete, equal length). | Result is `.insights`; the returned `cards` contains a `.activity` card; `evidence` contains the expected rounded percent (e.g. "18%"); `trendDirection == .increased`. |
| `activityDoesNotQualify_belowThreshold` | `build` (activity path) | Parameterized over relative changes of 14.999%, 10%, and 0%, all other inputs valid. | Result is `.noQualifyingChanges` (model mix also non-qualifying in the same fixture) — no `.activity` card appears in any `.insights` case produced by this fixture. |
| `activityBoundary_evaluatesUnroundedValue` | `build` (activity path) | Two fixtures: (a) an unrounded relative change of 14.994% that would *round* to 15% for display but must not qualify; (b) an unrounded change of 15.001% that must qualify even though display still rounds to 15%. | (a) category `.activity` does not produce a card (falls to `.noQualifyingChanges`); (b) `.activity` card is present. Confirms "evaluate using unrounded values, round only for display." |
| `activitySuppressed_belowMinimumVolume` | `build` (activity path) | Reporting period at 999,999 tokens (one below the 1,000,000 floor), preceding period valid, activity change otherwise well above threshold. Parameterized to also cover the inverse (preceding period below floor). | Neither period-below-floor fixture produces an `.activity` card; if model mix is also suppressed, result is `.insufficientData`. |
| `activitySuppressed_belowPrivacyFloor` | `build` (activity path) | `contributorCount` of 9 in one period (one below the 10-contributor floor), the other period at 42; all other fields valid and well past threshold. Parameterized for reporting-side and preceding-side. | No `.activity` card produced for either fixture. |
| `activitySuppressed_whenPeriodIncomplete` | `build` (activity path) | `isComplete = false` on one period, all other fields otherwise valid and above threshold. Parameterized for reporting-side and preceding-side. | No `.activity` card produced for either fixture. |
| `activityAllowsZeroTotalTokens_nonNegativeCheck` | `build` (activity path) | Custom `Configuration(minimumComparisonVolume: 0)` so the floor doesn't mask the check; reporting period `totalTokens = 0`, preceding period `totalTokens = 1_000_000`. | Category is valid; relative change computes to `-1.0` (100% decrease); `.activity` card is produced with `trendDirection == .decreased` and evidence containing "100%". Confirms activity's `>= 0` (not `> 0`) semantics. |
| `activitySuppressed_onInvalidNumericValues` | `build` (activity path) | Parameterized over `totalTokens` of `-5_000_000`, `Double.nan`, and `Double.infinity` in one period, other period valid. | No `.activity` card produced for any of the three fixtures. |
| `modelMixQualifies_atOrAboveThreshold` | `build` (model-mix path) | Parameterized over absolute share shifts of exactly 10.0, 12, and 20 percentage points for a single model, both periods valid and above the (post-fix) volume floor. | Result contains a `.modelMix` card; evidence contains the expected rounded point value; `trendDirection` matches the shift's sign. |
| `modelMixDoesNotQualify_belowThreshold` | `build` (model-mix path) | Parameterized over shifts of 9.999 and 5 percentage points. | No `.modelMix` card produced; category is valid (so it does not appear in `unavailableCategories`), it's simply non-qualifying. |
| `modelMixSuppressed_whenTotalTokensIsZero_positiveCheck` | `build` (model-mix path) | Custom `Configuration(minimumComparisonVolume: 0)`; one period's `totalTokens = 0`. | No `.modelMix` card and the category is invalid (`unavailableCategories` contains `.modelMix` when this is the only valid-shape category checked in isolation). Confirms model mix's `> 0` (stricter than activity's `>= 0`) semantics — the two rules' differentiated wording from the plan. |
| `modelMixSuppressed_belowMinimumVolume` | `build` (model-mix path) | Reporting period at 999,999 tokens with an otherwise-qualifying share shift. Parameterized for reporting-side and preceding-side. | No `.modelMix` card produced for either fixture. Locks in the T1 volume-floor fix (Finding 7). |
| `modelMixSuppressed_belowPrivacyFloor` | `build` (model-mix path) | `contributorCount` of 9 in one period, otherwise-qualifying share shift. Parameterized for reporting-side and preceding-side. | No `.modelMix` card produced for either fixture. |
| `modelMixSuppressed_onInvalidNumericValues` | `build` (model-mix path) | Parameterized over one model's token value in `tokensByModel` being `-1_000`, `Double.nan`, or `Double.infinity`, all else valid. | No `.modelMix` card produced for any of the three fixtures. |
| `modelMixTreatsAbsentModelAsZeroShare` | `build` (model-mix path) | A model key present only in `reportingPeriod.tokensByModel` (absent from `precedingPeriod.tokensByModel`) with a share large enough to exceed the 10-point threshold once the missing period is treated as 0%. | `.modelMix` card is produced identifying that model; evidence's percentage matches `(reportingShare - 0) * 100`, rounded. |
| `modelMixTieBreak_selectsAlphabeticallyFirstModel` | `build` (model-mix path) | Two models with numerically equal absolute share shifts (e.g. both exactly 12 points, one increasing one decreasing) but different names, e.g. `"Claude Opus 4.8"` and `"GPT-5 Codex"`. | `.modelMix` card's evidence names `"Claude Opus 4.8"` (alphabetically first), not the other model, regardless of insertion order in the dictionary literal. |
| `modelMixSelectsLargestShift_amongMultipleQualifiers` | `build` (model-mix path) | Three or more models each individually crossing the 10-point threshold, with distinct magnitudes (e.g. 11, 15, 30 points). | Exactly one `.modelMix` card is produced; it names the model with the 30-point shift; the 11- and 15-point models are not mentioned anywhere in the state. |
| `buildSuppressesBothCategories_whenPeriodLengthsDiffer` | `build` (equal-length guard) | Reporting period spanning 30 days, preceding period spanning 31 days, both otherwise well-formed and each individually well above every other threshold. | Result is `.insufficientData` (both categories invalidated by the length mismatch alone). Locks in the T1 fix for Finding 2. |
| `buildReturnsInsufficientData_whenNeitherCategoryValid` | `build` (top-level state selection) | Both periods below the privacy floor (`contributorCount = 5`), which invalidates both activity and model mix simultaneously. | Result is exactly `.insufficientData`. |
| `buildReturnsNoQualifyingChanges_whenBothValidButNeitherQualifies` | `build` (top-level state selection) | Both periods valid for both categories; activity change of 5% (below 15%) and largest model-mix shift of 3 points (below 10). | Result is exactly `.noQualifyingChanges`, not `.insufficientData`. |
| `buildReturnsInsights_withCoverageNote_whenOnlyOneCategoryComparable` | `build` (top-level state selection) | Fixture A: activity qualifies (25% change), model mix has one period below the privacy floor. Fixture B: the inverse (model mix qualifies, activity's period below the privacy floor). | Result is `.insights(cards:, unavailableCategories:)`; `cards` contains exactly the one qualifying category's card; `unavailableCategories` contains exactly the other, invalid category — never a category that was merely non-qualifying. |
| `buildReturnsInsufficientData_onMixedValidityWithNoQualifiers` | `build` (top-level state selection, Finding 6) | Activity is validly comparable but its change is only 5% (non-qualifying); model mix's period is below the privacy floor (invalid). | Result is exactly `.insufficientData`, not `.noQualifyingChanges` and not `.insights` with an empty `cards` array. Locks in the ratified decision from T5. |
| `buildReturnsBothCards_inActivityThenModelMixOrder` | `build` (card ordering) | Both categories qualify (activity 20% increase, one model's 15-point shift). | Result is `.insights`; `cards[0].category == .activity` and `cards[1].category == .modelMix`, regardless of internal computation order. |
| `configurationDefaults_matchApprovedV1Thresholds` | `UsageInsightBuilder.Configuration` | No builder call — constructs `UsageInsightBuilder.Configuration()` directly. | `minimumComparisonVolume == 1_000_000`, `minimumGroupSize == 10`, `activityThreshold == 0.15`, `modelMixThreshold == 0.10`. Guards against an accidental threshold edit shipping without a deliberate plan/audit update. |

### File: `UsageInsightModelTests.swift`

Covers `UsageInsight.accessibilityLabel` (new computed property from T2) and
`UsageInsightsState` construction invariants.

| Test name | Function(s) covered | Description | Assertions / data |
| --- | --- | --- | --- |
| `accessibilityLabel_usesHumanReadableTitle_forModelMix` | `UsageInsight.accessibilityLabel` | Construct a `UsageInsight` with `category: .modelMix`, `title: "Model Mix"`. | Label contains `"Model Mix"`; label does **not** contain `"Modelmix"` or the raw string `"modelMix"`. Directly regresses Finding 4. |
| `accessibilityLabel_usesHumanReadableTitle_forActivity` | `UsageInsight.accessibilityLabel` | Construct a `UsageInsight` with `category: .activity`, `title: "AI Activity"`. | Label contains `"AI Activity"`. |
| `accessibilityLabel_composesCategoryEvidencePeriodAndPrompt` | `UsageInsight.accessibilityLabel` | One fixture with distinct, easily-matched substrings for `title`, `evidence`, `reportingPeriodLabel`, and `reviewPrompt`. | Label contains all four substrings, in that order (category before evidence before period before prompt), matching the plan's accessibility requirement that labels include "category, observed comparison, reporting-period context, and review-oriented caution." |

### File: `UsageInsightsViewModelTests.swift`

Covers `UsageInsightsViewModel.init(periodStore:builder:)` and `init(state:)`.

| Test name | Function(s) covered | Description | Assertions / data |
| --- | --- | --- | --- |
| `defaultInit_producesNonEmptyInsightsFromRealPipeline` | `UsageInsightsViewModel.init(periodStore:builder:)` | Construct `UsageInsightsViewModel()` with all real defaults (real `AIUsagePeriodStore`, real `UsageInsightBuilder`) — no test doubles. | `viewModel.state` matches `.insights(cards:, _)` where `cards.isEmpty == false`. A smoke test: this is the one test that would have caught the shipped mock data silently degrading to `.insufficientData` or `.noQualifyingChanges` (Finding 2) before release. |
| `stateInit_passesThroughGivenState_forEachCase` | `UsageInsightsViewModel.init(state:)` | Parameterized over `.insufficientData`, `.noQualifyingChanges`, and a hand-built `.insights(cards: [aCard], unavailableCategories: [.modelMix])`. | `UsageInsightsViewModel(state: given).state` is exactly the given value for every case — locks in the escape hatch the view and previews rely on. |

### File: `SummaryViewModelTests.swift`

Covers `SummaryViewModel.init(costStore:outcomeStore:ticketToMergeStore:)` and its `insights`
property.

| Test name | Function(s) covered | Description | Assertions / data |
| --- | --- | --- | --- |
| `insights_containsExactlyOneUsageInsightsRow` | `SummaryViewModel.init` | Construct `SummaryViewModel()` with default stores. | Exactly one element of `insights` has `destination == .usageInsights`; that element's `headline == "AI Usage Insights"` and `detail == "Review aggregate team AI usage patterns."` |
| `insights_preservesExistingThreeRows_unchangedAndOrderedFirst` | `SummaryViewModel.init` | Same default-store construction. | `insights.count == 4`; the first three elements' `destination` values are `.costByModel`, `.tokensVsOutcomes`, `.ticketToMerge` in that order; the `.usageInsights` row is last. Fails if a future change reorders, duplicates, or drops any of the four rows — directly enforces the reviewed plan's non-goal that existing rows must not be modified or removed. |

### File: `TokensDashboardUITests.swift` (optional — new `TokensDashboardUITests` target)

Covers end-to-end navigation and the two view-layer bugs (header traits, Dynamic Type clipping)
that aren't reachable from pure unit tests. Requires adding an XCUIAutomation UI-test target,
which is a bigger lift than T1–T8; treat as a stretch goal once the unit-test suite above is
merged, not a blocker for closing the "automated tests" acceptance criterion (T3 + T6–T8 already
close it).

| Test name | Function(s) covered | Description | Assertions / data |
| --- | --- | --- | --- |
| `tappingUsageInsightsRow_navigatesToUsageInsightsScreen` | `SummaryView` navigation, `DestinationGraph.usageInsights` | Launch the app, find the summary row labeled "AI Usage Insights", tap it. | The navigation bar / screen title "AI Usage Insights" is present after the tap. End-to-end version of the reviewed plan's acceptance criterion "Selecting the row resolves through `DestinationGraph` to exactly one `UsageInsightsView`." |
| `usageInsightsScreen_passesAccessibilityAudit` | `UsageInsightsView`, `InsightCardView` | Navigate to the Usage Insights screen, call `app.performAccessibilityAudit(for: [.trait, .textClipped, .dynamicType, .contrast, .sufficientElementDescription])` at default Dynamic Type size. | The audit call throws no issues. Mechanically re-checks the exact defect classes VoiceOver-Audit and Dynamic-Type-Audit found by hand (missing header traits, clipped text) on every future change to this screen, with no per-element assertions to maintain. Depends on T2 landing first, or this starts red for an already-tracked reason. |
| `usageInsightsScreen_passesAccessibilityAudit_atAccessibilityLargeTypeSize` | `UsageInsightsView`, `InsightCardView` | Same as above, but launch with the content size category overridden to an accessibility size (e.g. AX3) via launch environment/arguments before navigating. | The audit call throws no issues at the larger size — specifically exercises `.textClipped`/`.dynamicType` categories against long evidence/review-prompt strings, matching the plan's "large accessibility text sizes" edge case. |

---

## Coverage check against the reviewed plan's acceptance criterion

> "Automated tests cover period alignment and completeness, thresholds and boundaries, missing
> periods, low volumes, zero totals, invalid numeric values, one-period-only models, tied and
> multiple shifts, partial coverage, and no-qualifying-change states."

| Clause | Covered by |
| --- | --- |
| Period alignment and completeness | `buildSuppressesBothCategories_whenPeriodLengthsDiffer`, `activitySuppressed_whenPeriodIncomplete` |
| Thresholds and boundaries | `activityQualifies_atOrAboveThreshold`, `activityDoesNotQualify_belowThreshold`, `activityBoundary_evaluatesUnroundedValue`, `modelMixQualifies_atOrAboveThreshold`, `modelMixDoesNotQualify_belowThreshold` |
| Missing periods / low volumes | `activitySuppressed_belowMinimumVolume`, `modelMixSuppressed_belowMinimumVolume` |
| Zero totals | `activityAllowsZeroTotalTokens_nonNegativeCheck`, `modelMixSuppressed_whenTotalTokensIsZero_positiveCheck` |
| Invalid numeric values | `activitySuppressed_onInvalidNumericValues`, `modelMixSuppressed_onInvalidNumericValues` |
| One-period-only models | `modelMixTreatsAbsentModelAsZeroShare` |
| Tied and multiple shifts | `modelMixTieBreak_selectsAlphabeticallyFirstModel`, `modelMixSelectsLargestShift_amongMultipleQualifiers` |
| Partial coverage | `buildReturnsInsights_withCoverageNote_whenOnlyOneCategoryComparable` |
| No-qualifying-change states | `buildReturnsNoQualifyingChanges_whenBothValidButNeitherQualifies` |

`insufficientData` (including the mixed-validity edge case from Finding 6) is additionally covered
by `buildReturnsInsufficientData_whenNeitherCategoryValid` and
`buildReturnsInsufficientData_onMixedValidityWithNoQualifiers` — closing the one state the
acceptance-criteria sentence doesn't name but the plan's own "State rules" section requires.

Privacy floor (`activitySuppressed_belowPrivacyFloor`, `modelMixSuppressed_belowPrivacyFloor`),
card ordering (`buildReturnsBothCards_inActivityThenModelMixOrder`), the summary-row/navigation
acceptance criteria (`SummaryViewModelTests.swift`), and the VoiceOver label defect
(`UsageInsightModelTests.swift`) are covered beyond the literal acceptance-criteria sentence,
closing findings 4–7 and 11 from the consolidated table above.
