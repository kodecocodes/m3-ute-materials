/// Copyright (c) 2026 Kodeco Inc. See COPYRIGHT for details.
/// Caution: This is AI-generated code.

import Testing
@testable import TokensDashboard

struct SummaryViewModelTests {
  @Test func usageInsightsRowHasExpectedContent() throws {
    let viewModel = SummaryViewModel()
    let usageInsightsInsights = viewModel.insights.filter { $0.destination == .usageInsights }
    #expect(usageInsightsInsights.count == 1)
    let row = try #require(usageInsightsInsights.first)
    #expect(row.headline == "AI Usage Insights")
    #expect(row.detail == "Review aggregate team AI usage patterns.")
  }

  @Test func insightsPreservesExistingRowsAndOrder() {
    let viewModel = SummaryViewModel()
    #expect(viewModel.insights.count == 4)
    #expect(viewModel.insights[0].destination == .costByModel)
    #expect(viewModel.insights[1].destination == .tokensVsOutcomes)
    #expect(viewModel.insights[2].destination == .ticketToMerge)
    #expect(viewModel.insights[3].destination == .usageInsights)
  }
}
