import 'package:url_launcher/url_launcher.dart';

/// Opens an attachment URL in the platform's external viewer/browser --
/// on web this opens a new tab (PDF viewer or download, browser's
/// choice), on mobile it hands off to whatever app handles the file type.
/// Returns false if nothing on the device could handle it.
Future<bool> openAttachment(String url) async {
  final uri = Uri.parse(url);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
