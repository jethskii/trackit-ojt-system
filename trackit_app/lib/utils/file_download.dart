import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart' as impl;

/// Saves [bytes] as a downloadable file named [filename]. Real, working
/// download on web (triggers the browser's save dialog); on mobile/desktop
/// this currently just reports that it isn't supported there yet rather
/// than silently doing nothing, since Admin > Class Management is a
/// web-first surface per the mockup.
bool downloadBytes({required String filename, required List<int> bytes}) {
  return impl.downloadBytes(filename: filename, bytes: bytes);
}
