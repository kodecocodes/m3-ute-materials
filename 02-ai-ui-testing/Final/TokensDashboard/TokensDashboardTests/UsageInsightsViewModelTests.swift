/// Copyright (c) 2026 Kodeco Inc. See COPYRIGHT for details.

import Testing
@testable import TokensDashboard

struct UsageInsightsViewModelTests {

  // MARK: - Default initializer exercises the real pipeline

  @Test func defaultInitProducesNonEmptyInsightsFromRealPipeline() throws {
    let viewModel = UsageInsightsViewModel()

    guard case .insights(let cards, _) = viewModel.state else {
      Issue.record("Expected .insights from the real AIUsagePeriodStore + UsageInsightBuilder pipeline, got \(viewModel.state)")
      return
    }
    #expect(!cards.isEmpty)
  }

  // MARK: - init(state:) passes through unchanged

  @Test func stateInitPassesThroughInsufficientData() {
    let viewModel = UsageInsightsViewModel(state: .insufficientData)
    guard case .insufficientData = viewModel.state else {
      Issue.record("Expected .insufficientData, got \(viewModel.state)")
      return
    }
  }

  @Test func stateInitPassesThroughNoQualifyingChanges() {
    let viewModel = UsageInsightsViewModel(state: .noQualifyingChanges)
    guard case .noQualifyingChanges = viewModel.state else {
      Issue.record("Expected .noQualifyingChanges, got \(viewModel.state)")
      return
    }
  }

  @Test func stateInitPassesThroughInsightsWithCardsAndUnavailableCategories() {
    let card = UsageInsight(
      category: .activity,
      title: "AI Activity",
      evidence: "Team token activity increased 20% compared with the prior period.",
      reviewPrompt: "Review this alongside the team's current work.",
      reportingPeriodLabel: "Apr 1–30, 2026 vs. Mar 1–31, 2026",
      trendDirection: .increased
    )
    let given: UsageInsightsState = .insights(cards: [card], unavailableCategories: [.modelMix])

    let viewModel = UsageInsightsViewModel(state: given)

    guard case .insights(let cards, let unavailableCategories) = viewModel.state else {
      Issue.record("Expected .insights, got \(viewModel.state)")
      return
    }
    #expect(cards.map(\.category) == [.activity])
    #expect(unavailableCategories == [.modelMix])
  }
}
