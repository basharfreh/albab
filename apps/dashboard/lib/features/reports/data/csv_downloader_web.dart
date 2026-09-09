// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

/// Triggers a browser file-save of [content] as [filename]. `dart:html` is only ever
/// compiled in when the entrypoint (`csv_downloader.dart`) is built for web — see that
/// file's conditional export — so this never reaches (and never breaks) `flutter test`'s
/// VM runner.
void downloadCsv({required String filename, required String content}) {
  // Leading BOM so Excel opens the Arabic text as UTF-8 instead of guessing a local codepage.
  final bytes = utf8.encode('﻿$content');
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
