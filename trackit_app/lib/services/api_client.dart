import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class RawFileResponse {
  final List<int> bytes;
  final String? filename;

  const RawFileResponse({required this.bytes, this.filename});
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Thin wrapper around package:http that attaches the auth token, encodes
/// JSON bodies, and turns non-2xx responses into [ApiException].
class ApiClient {
  // Flutter web / Chrome on the same machine as the server: localhost
  // works as-is. Android emulator: use 10.0.2.2 instead of localhost.
  // Physical device: use your machine's LAN IP.
  static const String baseUrl = 'http://localhost:3000';

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _decode(response);
  }

  /// For non-JSON downloads (e.g. CSV export) -- the auth header still
  /// applies, so unlike a plain browser navigation to the URL, this
  /// actually works against an authenticated endpoint.
  Future<RawFileResponse> getBytes(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Something went wrong.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['message'] as String? ?? message;
      } catch (_) {
        // Non-JSON error body -- fall back to the generic message.
      }
      throw ApiException(message, statusCode: response.statusCode);
    }
    final disposition = response.headers['content-disposition'];
    final match = disposition != null
        ? RegExp(r'filename="?([^"]+)"?').firstMatch(disposition)
        : null;
    return RawFileResponse(bytes: response.bodyBytes, filename: match?.group(1));
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _decode(response);
  }

  /// [contentType] matters: without it, MultipartFile.fromBytes defaults to
  /// application/octet-stream, which the server's image-only fileFilter
  /// (jpeg/png/webp) rejects even for a genuine image upload.
  ///
  /// [fields] carries any other form fields (e.g. title/content/classIds)
  /// alongside the file -- multer parses these into req.body as strings on
  /// the server, so a caller sending a list (like classIds) must
  /// JSON-encode it first.
  ///
  /// [method] defaults to POST; pass 'PATCH' for an edit that may also
  /// replace the file. The file itself is optional -- omit [fileBytes] to
  /// send just the form fields (e.g. editing text without touching the
  /// image).
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    List<int>? fileBytes,
    String? fileName,
    String contentType = 'image/jpeg',
    Map<String, String> fields = const {},
    String method = 'POST',
  }) async {
    final request = http.MultipartRequest(method, Uri.parse('$baseUrl$path'));
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    request.fields.addAll(fields);
    if (fileBytes != null && fileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  /// Resolves a possibly-relative media path (e.g. "/uploads/avatars/x.jpg"
  /// as returned by the upload endpoints) into an absolute URL a
  /// NetworkImage can load. Already-absolute URLs pass through unchanged.
  static String resolveUrl(String path) {
    return path.startsWith('http') ? path : '$baseUrl$path';
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected server response.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] as String? ?? 'Something went wrong.';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
