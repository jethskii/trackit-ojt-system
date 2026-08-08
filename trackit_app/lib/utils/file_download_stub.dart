// Non-web fallback, selected via the conditional import in
// file_download.dart. Returns false so the caller can show an honest
// "not supported here yet" message instead of silently doing nothing.
bool downloadBytes({required String filename, required List<int> bytes}) {
  return false;
}
