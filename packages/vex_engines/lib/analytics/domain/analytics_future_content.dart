/// Future analytics capabilities not implemented in Version 1.
enum AnalyticsFutureCapability {
  marketIntelligence,
  predictiveAnalytics,
  aiInsights,
}

/// Documents planned analytics modules (structure only in Version 1).
final class AnalyticsFutureContent {
  AnalyticsFutureContent._();

  static const planned = {
    AnalyticsFutureCapability.marketIntelligence,
    AnalyticsFutureCapability.predictiveAnalytics,
    AnalyticsFutureCapability.aiInsights,
  };
}
