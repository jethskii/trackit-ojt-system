import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );
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
