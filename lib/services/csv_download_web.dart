// Web: trigger a browser download.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

/// Web: trigger a browser download with the correct MIME type so the browser
/// and the OS offer the right app (Word, Excel, PDF reader) to open it.
Future<void> saveFile(List<int> bytes, String filename,
    {String mime = 'application/octet-stream'}) async {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none'
    ..click();

  // Revoking immediately can abort the download before the browser has read
  // the blob, so give it a moment.
  Timer(const Duration(seconds: 2), () => html.Url.revokeObjectUrl(url));
}
