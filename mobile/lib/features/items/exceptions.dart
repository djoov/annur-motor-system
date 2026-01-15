class DuplicateItemException implements Exception {
  final String message;
  DuplicateItemException(this.message);

  @override
  String toString() => message;
}
