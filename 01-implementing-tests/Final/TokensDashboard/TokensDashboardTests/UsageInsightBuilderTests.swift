/// Copyright (c) 2026 Kodeco Inc. See COPYRIGHT for details.

import Foundation
import Testing
@testable import TokensDashboard

// MARK: - Fixture helpers

private func day(_ n: Int) -> Date {
  Date(timeIntervalSince1970: TimeInterval(n) * 86_400)
}

// Default reporting/preceding windows are both exactly 29 days, so any test
// that doesn't care about period length gets equal-length periods for free.
private let defaultReportingStart = day(30)
private let defaultReportingEnd = day(59)
private let defaultPrecedingStart = day(0)
private let defaultPrecedingEnd = day(29)

private func makePeriod(
  start: Date,
  end: Date,
  isComplete: Bool = true,
  contributorCount: Int = 20,
  totalTokens: Double = 10_000_000,
  tokensByModel: [String: Double] = [:]
) -> AIUsagePeriod {
  AIUsagePeriod(
    start: start,
    end: end,
    isComplete: isComplete,
    contributorCount: contributorCount,
    totalTokens: totalTokens,
    tokensByModel: tokensByModel
  )
}

private func reportingPeriod(
  isComplete: Bool = true,
  contributorCount: Int = 20,
  totalTokens: Double = 10_000_000,
  tokensByModel: [String: Double] = [:]
) -> AIUsagePeriod {
  makePeriod(
    start: defaultReportingStart,
    end: defaultReportingEnd,
    isComplete: isComplete,
    contributorCount: contributorCount,
    totalTokens: totalTokens,
    tokensByModel: tokensByModel
  )
}

private func precedingPeriod(
  isComplete: Bool = true,
  contributorCount: Int = 20,
  totalTokens: Double = 10_000_000,
  tokensByModel: [String: Double] = [:]
) -> AIUsagePeriod {
  makePeriod(
    start: defaultPrecedingStart,
    end: defaultPrecedingEnd,
    isComplete: isComplete,
    contributorCount: contributorCount,
    totalTokens: totalTokens,
    tokensByModel: tokensByModel
  )
}

private func card(in cards: [UsageInsight], category: UsageInsightCategory) -> UsageInsight? {
  cards.first { $0.category == category }
}

struct UsageInsightBuilderTests {

  // MARK: - Activity: qualification and boundaries

  @Test(arguments: [0.15, 0.18, 0.25])
  func activityQualifiesAtOrAboveThreshold(percent: Double) throws {
    let preceding = precedingPeriod(totalTokens: 10_000_000)
    let reporting = reportingPeriod(totalTokens: 10_000_000 * (1 + percent))
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insights(let cards, _) = state else {
      Issue.record("Expected .insights for a \(percent * 100)% activity change, got \(state)")
      return
    }
    let activityCard = try #require(card(in: cards, category: .activity))
    let expectedPercent = Int((percent * 100).rounded())
    #expect(activityCard.evidence.contains("\(expectedPercent)%"))
    guard case .increased = activityCard.trendDirection else {
      Issue.record("Expected .increased trend, got \(String(describing: activityCard.trendDirection))")
      return
    }
  }

  @Test(arguments: [0.10, 0.0])
  func activityDoesNotQualifyBelowThreshold(percent: Double) {
    let preceding = precedingPeriod(totalTokens: 10_000_000)
    let reporting = reportingPeriod(totalTokens: 10_000_000 * (1 + percent))
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    // Model mix is valid-but-non-qualifying too (empty tokensByModel on both
    // sides), so a non-qualifying activity change resolves to .noQualifyingChanges.
    guard case .noQualifyingChanges = state else {
      Issue.record("Expected .noQualifyingChanges for a \(percent * 100)% activity change, got \(state)")
      return
    }
  }

  @Test func activityBoundaryJustBelowThresholdDoesNotQualifyEvenThoughItRoundsTo15Percent() {
    // 14.994% is unrounded-below-threshold even though Int((... * 100).rounded()) would show "15%".
    let preceding = precedingPeriod(totalTokens: 10_000_000)
    let reporting = reportingPeriod(totalTokens: 11_499_400)
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .noQualifyingChanges = state else {
      Issue.record("Expected .noQualifyingChanges for an unrounded 14.994% change, got \(state)")
      return
    }
  }

  @Test func activityBoundaryJustAboveThresholdQualifiesAndDisplaysAs15Percent() throws {
    let preceding = precedingPeriod(totalTokens: 10_000_000)
    let reporting = reportingPeriod(totalTokens: 11_500_100)
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insights(let cards, _) = state else {
      Issue.record("Expected .insights for an unrounded 15.001% change, got \(state)")
      return
    }
    let activityCard = try #require(card(in: cards, category: .activity))
    #expect(activityCard.evidence.contains("15%"))
  }

  // MARK: - Fields shared by both rules' guard clauses

  @Test(arguments: [true, false])
  func buildReturnsInsufficientDataWhenAPeriodIsBelowMinimumVolume(invalidateReportingSide: Bool) {
    let lowVolume = precedingPeriod(totalTokens: 999_999)
    let validVolume = precedingPeriod(totalTokens: 10_000_000)
    let reporting = invalidateReportingSide ? lowVolume : validVolume
    let preceding = invalidateReportingSide ? validVolume : lowVolume
    let builder = UsageInsightBuilder()

    // 999,999 tokens is below the shared 1,000,000 floor, which now gates
    // both activity and model mix (Finding 7's fix) - so both are invalidated.
    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insufficientData = state else {
      Issue.record("Expected .insufficientData below the minimum volume floor, got \(state)")
      return
    }
  }

  @Test(arguments: [true, false])
  func buildReturnsInsufficientDataWhenAPeriodIsBelowPrivacyFloor(invalidateReportingSide: Bool) {
    let lowGroupSize = precedingPeriod(contributorCount: 9)
    let validGroupSize = precedingPeriod(contributorCount: 20)
    let reporting = invalidateReportingSide ? lowGroupSize : validGroupSize
    let preceding = invalidateReportingSide ? validGroupSize : lowGroupSize
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insufficientData = state else {
      Issue.record("Expected .insufficientData below the 10-contributor privacy floor, got \(state)")
      return
    }
  }

  @Test(arguments: [true, false])
  func buildReturnsInsufficientDataWhenAPeriodIsIncomplete(invalidateReportingSide: Bool) {
    let incomplete = precedingPeriod(isComplete: false)
    let complete = precedingPeriod(isComplete: true)
    let reporting = invalidateReportingSide ? incomplete : complete
    let preceding = invalidateReportingSide ? complete : incomplete
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insufficientData = state else {
      Issue.record("Expected .insufficientData when a period is incomplete, got \(state)")
      return
    }
  }

  @Test(arguments: [-5_000_000.0, Double.nan, Double.infinity])
  func buildReturnsInsufficientDataWhenTotalTokensIsInvalid(invalidValue: Double) {
    let invalid = precedingPeriod(totalTokens: invalidValue)
    let valid = precedingPeriod(totalTokens: 10_000_000)
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: invalid, precedingPeriod: valid)

    guard case .insufficientData = state else {
      Issue.record("Expected .insufficientData for totalTokens = \(invalidValue), got \(state)")
      return
    }
  }

  @Test func buildSuppressesBothCategoriesWhenPeriodLengthsDiffer() {
    let reporting = makePeriod(start: day(30), end: day(59), totalTokens: 10_000_000) // 29-day span
    let preceding = makePeriod(start: day(0), end: day(28), totalTokens: 10_000_000) // 28-day span
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insufficientData = state else {
      Issue.record("Expected .insufficientData for mismatched period lengths, got \(state)")
      return
    }
  }

  // MARK: - Activity's >= 0 vs model mix's > 0 (differentiated wording from the plan)

  @Test func activityAllowsZeroTotalTokensViaItsNonNegativeCheck() throws {
    let configuration = UsageInsightBuilder.Configuration(minimumComparisonVolume: 0)
    let reporting = reportingPeriod(totalTokens: 0)
    let preceding = precedingPeriod(totalTokens: 1_000_000)
    let builder = UsageInsightBuilder(configuration: configuration)

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insights(let cards, _) = state else {
      Issue.record("Expected .insights with zero reporting tokens under a lowered volume floor, got \(state)")
      return
    }
    let activityCard = try #require(card(in: cards, category: .activity))
    #expect(activityCard.evidence.contains("100%"))
    guard case .decreased = activityCard.trendDirection else {
      Issue.record("Expected .decreased trend, got \(String(describing: activityCard.trendDirection))")
      return
    }
  }

  @Test func modelMixSuppressedWhenTotalTokensIsExactlyZero() {
    let configuration = UsageInsightBuilder.Configuration(minimumComparisonVolume: 0)
    let reporting = reportingPeriod(totalTokens: 0)
    let preceding = precedingPeriod(totalTokens: 1_000_000)
    let builder = UsageInsightBuilder(configuration: configuration)

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insights(_, let unavailableCategories) = state else {
      Issue.record("Expected .insights (activity still valid) with model mix unavailable, got \(state)")
      return
    }
    #expect(unavailableCategories == [.modelMix])
  }

  // MARK: - Model mix: qualification, boundaries, tie-break, selection

  @Test(arguments: [10.0, 12.0, 20.0])
  func modelMixQualifiesAtOrAboveThreshold(points: Double) throws {
    let precedingTokens: Double = 1_000_000 // 10% share of a 10,000,000 total
    let reportingTokens = precedingTokens + points / 100 * 10_000_000
    let reporting = reportingPeriod(totalTokens: 10_000_000, tokensByModel: ["Solo Model": reportingTokens])
    let preceding = precedingPeriod(totalTokens: 10_000_000, tokensByModel: ["Solo Model": precedingTokens])
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insights(let cards, _) = state else {
      Issue.record("Expected .insights for a \(points)-point model-mix shift, got \(state)")
      return
    }
    let modelMixCard = try #require(card(in: cards, category: .modelMix))
    let expectedPoints = Int(points.rounded())
    #expect(modelMixCard.evidence.contains("\(expectedPoints) percentage point"))
    #expect(modelMixCard.evidence.contains("Solo Model"))
  }

  @Test(arguments: [9.999, 5.0])
  func modelMixDoesNotQualifyBelowThreshold(points: Double) {
    let precedingTokens: Double = 1_000_000
    let reportingTokens = precedingTokens + points / 100 * 10_000_000
    let reporting = reportingPeriod(totalTokens: 10_000_000, tokensByModel: ["Solo Model": reportingTokens])
    let preceding = precedingPeriod(totalTokens: 10_000_000, tokensByModel: ["Solo Model": precedingTokens])
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    // Activity is 0% change here (equal totals), so both categories are
    // valid-but-non-qualifying and the result is .noQualifyingChanges.
    guard case .noQualifyingChanges = state else {
      Issue.record("Expected .noQualifyingChanges for a \(points)-point model-mix shift, got \(state)")
      return
    }
  }

  @Test func modelMixTreatsAModelAbsentFromOnePeriodAsZeroShareThere() throws {
    let reporting = reportingPeriod(totalTokens: 10_000_000, tokensByModel: ["Only In Reporting": 1_500_000])
    let preceding = precedingPeriod(totalTokens: 10_000_000, tokensByModel: [:])
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insights(let cards, _) = state else {
      Issue.record("Expected .insights for a model absent from one period, got \(state)")
      return
    }
    let modelMixCard = try #require(card(in: cards, category: .modelMix))
    #expect(modelMixCard.evidence.contains("Only In Reporting"))
    #expect(modelMixCard.evidence.contains("15 percentage point"))
  }

  @Test func modelMixTieBreakSelectsAlphabeticallyFirstModel() throws {
    // Both models shift by exactly 12 points in opposite directions.
    let reporting = reportingPeriod(totalTokens: 10_000_000, tokensByModel: [
      "Alpha": 2_200_000, // 22% share, up from 10% preceding: +12pp
      "Bravo": 1_800_000, // 18% share, down from 30% preceding: -12pp
    ])
    let preceding = precedingPeriod(totalTokens: 10_000_000, tokensByModel: [
      "Alpha": 1_000_000, // 10% share
      "Bravo": 3_000_000, // 30% share
    ])
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insights(let cards, _) = state else {
      Issue.record("Expected .insights for a tied model-mix shift, got \(state)")
      return
    }
    let modelMixCard = try #require(card(in: cards, category: .modelMix))
    #expect(modelMixCard.evidence.contains("Alpha"))
    #expect(!modelMixCard.evidence.contains("Bravo"))
  }

  @Test func modelMixSelectsOnlyTheLargestShiftAmongMultipleQualifiers() throws {
    let reporting = reportingPeriod(totalTokens: 10_000_000, tokensByModel: [
      "Model A": 2_100_000, // 21% share, up from 10%: +11pp
      "Model B": 2_500_000, // 25% share, up from 10%: +15pp
      "Model C": 4_000_000, // 40% share, up from 10%: +30pp
    ])
    let preceding = precedingPeriod(totalTokens: 10_000_000, tokensByModel: [
      "Model A": 1_000_000,
      "Model B": 1_000_000,
      "Model C": 1_000_000,
    ])
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insights(let cards, _) = state else {
      Issue.record("Expected .insights for multiple qualifying model shifts, got \(state)")
      return
    }
    let modelMixCards = cards.filter { $0.category == .modelMix }
    #expect(modelMixCards.count == 1)
    let modelMixCard = try #require(modelMixCards.first)
    #expect(modelMixCard.evidence.contains("Model C"))
    #expect(!modelMixCard.evidence.contains("Model A"))
    #expect(!modelMixCard.evidence.contains("Model B"))
  }

  @Test(arguments: [-1_000.0, Double.nan, Double.infinity])
  func modelMixSuppressedOnInvalidTokensByModelValuesWhileActivityStaysAvailable(invalidValue: Double) throws {
    // Activity qualifies (25% change) while model mix's own tokensByModel
    // validity check fails - this is the only way, given the shared
    // period-level guards above, to get "activity valid, model mix invalid."
    let reporting = reportingPeriod(totalTokens: 12_500_000, tokensByModel: ["Bad Model": invalidValue])
    let preceding = precedingPeriod(totalTokens: 10_000_000, tokensByModel: ["Bad Model": 1_000_000])
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insights(let cards, let unavailableCategories) = state else {
      Issue.record("Expected .insights with model mix unavailable, got \(state)")
      return
    }
    #expect(cards.map(\.category) == [.activity])
    #expect(unavailableCategories == [.modelMix])
  }

  // MARK: - Overall state selection

  @Test func buildReturnsInsufficientDataWhenNeitherCategoryIsValid() {
    let reporting = reportingPeriod(contributorCount: 5)
    let preceding = precedingPeriod(contributorCount: 5)
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insufficientData = state else {
      Issue.record("Expected .insufficientData when neither category is valid, got \(state)")
      return
    }
  }

  @Test func buildReturnsNoQualifyingChangesWhenBothValidButNeitherQualifies() {
    // Activity: 5% change (below 15%). Model mix: 3-point shift (below 10).
    let reporting = reportingPeriod(totalTokens: 10_500_000, tokensByModel: ["Solo Model": 1_300_000])
    let preceding = precedingPeriod(totalTokens: 10_000_000, tokensByModel: ["Solo Model": 1_000_000])
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .noQualifyingChanges = state else {
      Issue.record("Expected .noQualifyingChanges when both categories are valid but neither qualifies, got \(state)")
      return
    }
  }

  @Test func buildReturnsInsufficientDataOnMixedValidityWithNoQualifiers() {
    // Activity is validly comparable but only changes by 5% (non-qualifying).
    // Model mix is invalidated by a NaN per-model value. Per the ratified
    // "State rules" decision, this must be .insufficientData, not
    // .noQualifyingChanges and not an empty .insights case.
    let reporting = reportingPeriod(totalTokens: 10_500_000, tokensByModel: ["Bad Model": Double.nan])
    let preceding = precedingPeriod(totalTokens: 10_000_000, tokensByModel: ["Bad Model": 1_000_000])
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insufficientData = state else {
      Issue.record("Expected .insufficientData for mixed validity with no qualifiers, got \(state)")
      return
    }
  }

  @Test func buildReturnsBothCardsInActivityThenModelMixOrder() {
    let reporting = reportingPeriod(totalTokens: 12_000_000, tokensByModel: ["Widget": 2_400_000]) // +20% activity, 15pp shift
    let preceding = precedingPeriod(totalTokens: 10_000_000, tokensByModel: ["Widget": 500_000])
    let builder = UsageInsightBuilder()

    let state = builder.build(reportingPeriod: reporting, precedingPeriod: preceding)

    guard case .insights(let cards, _) = state else {
      Issue.record("Expected .insights with both categories qualifying, got \(state)")
      return
    }
    #expect(cards.map(\.category) == [.activity, .modelMix])
  }

  // MARK: - Configuration

  @Test func configurationDefaultsMatchApprovedV1Thresholds() {
    let configuration = UsageInsightBuilder.Configuration()

    #expect(configuration.minimumComparisonVolume == 1_000_000)
    #expect(configuration.minimumGroupSize == 10)
    #expect(configuration.activityThreshold == 0.15)
    #expect(configuration.modelMixThreshold == 0.10)
  }
}
