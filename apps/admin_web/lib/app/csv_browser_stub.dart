/// Non-web fallbacks for CSV pick / download (widget tests, desktop).
Future<String?> pickCsvFile() async => null;

void downloadCsvFile({
  required String filename,
  required String contents,
}) {
  // No-op off web; callers should still fill the paste field / clipboard.
}
