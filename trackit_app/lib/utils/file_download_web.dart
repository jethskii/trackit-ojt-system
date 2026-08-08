// Web-only implementation, selected via the conditional import in
// file_download.dart. dart:html is soft-deprecated but still fully
// functional in Flutter web -- this avoids pulling in a new package for
// what's a small, self-contained Blob-download.
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

bool downloadBytes({required String filename, required List<int> bytes}) {
  final blob = html.Blob([Uint8List.fromList(bytes)], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
