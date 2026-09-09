/// VM (non-web) fallback — only reached if `flutter test` (or any non-web compile target)
/// ever calls this; the real implementation lives in `csv_downloader_web.dart` and is the
/// only one ever wired up in practice, since `apps/dashboard` is web-only.
void downloadCsv({required String filename, required String content}) {
  throw UnsupportedError('CSV download is only supported on Flutter Web.');
}
