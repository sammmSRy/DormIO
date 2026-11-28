/// Friendly error thrown by the repositories.
/// Member 1 (UI) can show `e.message` directly in a SnackBar / dialog.
class DbException implements Exception {
  final String message;
  DbException(this.message);

  @override
  String toString() => message;
}
