/// Token to signal cancellation to ongoing search tasks.
class CancelToken {
  bool _isCancelled = false;

  /// Whether cancellation has been requested.
  bool get isCancelled => _isCancelled;

  /// Requests cancellation of the associated search task.
  void cancel() {
    _isCancelled = true;
  }

  /// Resets the cancellation state.
  void reset() {
    _isCancelled = false;
  }
}
