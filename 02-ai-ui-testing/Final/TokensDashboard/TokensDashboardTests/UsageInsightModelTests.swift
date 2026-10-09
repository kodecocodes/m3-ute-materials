/// Copyright (c) 2026 Kodeco Inc. See COPYRIGHT for details.
/// Caution: This is AI-generated code.

import Foundation
import Testing
@testable import TokensDashboard

struct UsageInsightModelTests {

  // MARK: - accessibilityLabel uses human-readable title, not rawValue

  @Test func accessibilityLabelUsesHumanReadableTitleForModelMix() {
    let insight = UsageInsight(
      category: .modelMix,
      title: "Model Mix",
      evidence: "Some evidence.",
      reviewPrompt: "Some prompt.",
      reportingPeriodLabel: "Apr 1–30, 2026 vs. Mar 1–31, 2026",
      trendDirection: .increased
    )

    let label = insight.accessibilityLabel

    #expect(label.contains("Model Mix"))
    #expect(!label.contains("Modelmix"))
    #expect(!label.contains("modelMix"))
  }

  @Test func accessibilityLabelUsesHumanReadableTitleForActivity() {
    let insight = UsageInsight(
      category: .activity,
      title: "AI Activity",
      evidence: "Some evidence.",
      reviewPrompt: "Some prompt.",
      reportingPeriodLabel: "Apr 1–30, 2026 vs. Mar 1–31, 2026",
      trendDirection: .decreased
    )

    let label = insight.accessibilityLabel

    #expect(label.contains("AI Activity"))
  }

  @Test func accessibilityLabelComposesFieldsInOrder() throws {
    let insight = UsageInsight(
      category: .activity,
      title: "TITLE_MARKER",
      evidence: "EVIDENCE_MARKER",
      reviewPrompt: "PROMPT_MARKER",
      reportingPeriodLabel: "PERIOD_MARKER",
      trendDirection: nil
    )

    let label = insight.accessibilityLabel

    #expect(label.contains("TITLE_MARKER"))
    #expect(label.contains("EVIDENCE_MARKER"))
    #expect(label.contains("PERIOD_MARKER"))
    #expect(label.contains("PROMPT_MARKER"))

    let titleRange = try #require(label.range(of: "TITLE_MARKER"))
    let evidenceRange = try #require(label.range(of: "EVIDENCE_MARKER"))
    let periodRange = try #require(label.range(of: "PERIOD_MARKER"))
    let promptRange = try #require(label.range(of: "PROMPT_MARKER"))

    #expect(titleRange.lowerBound < evidenceRange.lowerBound)
    #expect(evidenceRange.lowerBound < periodRange.lowerBound)
    #expect(periodRange.lowerBound < promptRange.lowerBound)
  }
  
  // MARK: - accessibilityLabel does not duplicate the period after evidence

  @Test func accessibilityLabelDoesNotDoublePeriodWhenEvidenceEndsWithPeriod() {
    let insight = UsageInsight(
      category: .activity,
      title: "AI Activity",
      evidence: "Team token activity increased 20% compared with the prior period.",
      reviewPrompt: "Review this alongside the team's current work.",
      reportingPeriodLabel: "Apr 1–30, 2026 vs. Mar 1–31, 2026",
      trendDirection: .increased
    )

    let label = insight.accessibilityLabel

    #expect(!label.contains(".."))
    #expect(label.contains("prior period. Apr 1–30"))
  }
}
