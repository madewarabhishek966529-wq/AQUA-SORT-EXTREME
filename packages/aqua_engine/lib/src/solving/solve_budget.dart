/// Defines resource boundaries for puzzle solving.
class SolveBudget {
  /// Maximum number of search nodes (states) to expand.
  final int maxNodes;

  /// Maximum wall-clock time allowed for search.
  final Duration timeout;

  const SolveBudget({
    this.maxNodes = 25000,
    this.timeout = const Duration(seconds: 3),
  });

  /// Quick budget for real-time hint requests in UI.
  const SolveBudget.hint()
      : maxNodes = 8000,
        timeout = const Duration(milliseconds: 1200);

  /// Deep budget for offline catalog generation and benchmarking.
  const SolveBudget.deep()
      : maxNodes = 60000,
        timeout = const Duration(seconds: 8);

  Map<String, dynamic> toJson() => {
        'maxNodes': maxNodes,
        'timeoutMs': timeout.inMilliseconds,
      };

  factory SolveBudget.fromJson(Map<String, dynamic> json) => SolveBudget(
        maxNodes: json['maxNodes'] as int? ?? 25000,
        timeout: Duration(milliseconds: json['timeoutMs'] as int? ?? 3000),
      );
}
