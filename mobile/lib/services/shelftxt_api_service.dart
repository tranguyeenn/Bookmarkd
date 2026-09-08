import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/book.dart';

/// Base exception for ShelfTxt API client.
abstract class ShelfTxtApiException implements Exception {
  final String message;
  final dynamic details;

  const ShelfTxtApiException(this.message, [this.details]);

  @override
  String toString() => message;
}

class ShelfTxtNetworkException extends ShelfTxtApiException {
  final String serverUrl;

  const ShelfTxtNetworkException({
    required this.serverUrl,
    String? message,
    dynamic details,
  }) : super(
          message ??
              'Unable to connect to the ShelfTxt server at $serverUrl.\n\n'
                  'Please ensure the backend is running (e.g. "uvicorn api:app --reload") '
                  'or check your server settings.',
          details,
        );
}

class ShelfTxtHttpException extends ShelfTxtApiException {
  final int statusCode;
  final String responseBody;

  const ShelfTxtHttpException({
    required this.statusCode,
    required this.responseBody,
    String? message,
  }) : super(
          message ?? 'ShelfTxt server returned HTTP error $statusCode.',
          responseBody,
        );
}

class ShelfTxtFormatException extends ShelfTxtApiException {
  const ShelfTxtFormatException({
    String? message,
    dynamic details,
  }) : super(
          message ?? 'Received invalid or malformed data from the ShelfTxt server.',
          details,
        );
}

/// Service class for interacting with the ShelfTxt REST API.
class ShelfTxtApiService {
  static const String defaultBaseUrl = String.fromEnvironment(
    'SHELFTXT_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  String _baseUrl;
  String? authToken;
  final http.Client _client;
  final Duration timeout;

  ShelfTxtApiService({
    String baseUrl = defaultBaseUrl,
    this.authToken,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  })  : _baseUrl = _normalizeUrl(baseUrl),
        _client = client ?? http.Client();

  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    _baseUrl = _normalizeUrl(url);
  }

  static String _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Map<String, String> _buildHeaders() {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  /// Checks server health status (`GET /health`).
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches library books with optional pagination and status filter (`GET /books`).
  Future<BooksPage> getBooks({
    int page = 1,
    int limit = 50,
    BookStatus? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'details': 'true',
    };
    if (status != null) {
      queryParams['status'] = status.value;
    }

    final uri = Uri.parse('$_baseUrl/books').replace(queryParameters: queryParams);

    try {
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw ShelfTxtHttpException(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return BooksPage.fromJson(decoded);
      } else if (decoded is List) {
        return BooksPage.fromJson({'books': decoded, 'total': decoded.length});
      } else {
        throw const ShelfTxtFormatException(
          message: 'Expected a list or paginated object of books from /books.',
        );
      }
    } on ShelfTxtApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ShelfTxtNetworkException(serverUrl: _baseUrl, details: e);
    } on TimeoutException catch (e) {
      throw ShelfTxtNetworkException(
        serverUrl: _baseUrl,
        message: 'Connection timed out while contacting ShelfTxt at $_baseUrl.',
        details: e,
      );
    } on FormatException catch (e) {
      throw ShelfTxtFormatException(details: e);
    } catch (e) {
      throw ShelfTxtNetworkException(
        serverUrl: _baseUrl,
        message: 'Network error connecting to $_baseUrl: $e',
        details: e,
      );
    }
  }

  /// Adds a new book to the library (`POST /books`).
  Future<Book> addBook(Book book) async {
    final uri = Uri.parse('$_baseUrl/books');
    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode(book.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ShelfTxtHttpException(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return Book.fromJson(decoded);
      }
      return book;
    } on ShelfTxtApiException {
      rethrow;
    } catch (e) {
      throw ShelfTxtNetworkException(serverUrl: _baseUrl, details: e);
    }
  }

  /// Updates reading progress of a book.
  Future<void> updateBookProgress(
    String bookId, {
    int? currentPage,
    BookStatus? status,
    double? rating,
  }) async {
    final uri = Uri.parse('$_baseUrl/books/$bookId');
    final payload = <String, dynamic>{};
    if (currentPage != null) payload['current_page'] = currentPage;
    if (status != null) payload['status'] = status.value;
    if (rating != null) payload['star_rating'] = rating;

    try {
      final response = await _client
          .patch(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ShelfTxtHttpException(
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } on ShelfTxtApiException {
      rethrow;
    } catch (e) {
      throw ShelfTxtNetworkException(serverUrl: _baseUrl, details: e);
    }
  }

  void dispose() {
    _client.close();
  }
}
