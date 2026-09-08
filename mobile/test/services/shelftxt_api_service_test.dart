import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelftxt_mobile/models/book.dart';
import 'package:shelftxt_mobile/services/shelftxt_api_service.dart';

void main() {
  group('ShelfTxtApiService Tests', () {
    test('fetches list of books successfully', () async {
      final mockData = {
        'books': [
          {
            'id': '1',
            'title': 'Design Patterns',
            'author': 'Gang of Four',
            'total_pages': 395,
            'status': 'reading',
          }
        ],
        'total': 1,
        'page': 1,
        'limit': 20,
      };

      final client = MockClient((request) async {
        if (request.url.path == '/books') {
          return http.Response(jsonEncode(mockData), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = ShelfTxtApiService(client: client);
      final page = await service.getBooks();

      expect(page.items.length, 1);
      expect(page.items[0].title, 'Design Patterns');
      expect(page.items[0].status, BookStatus.reading);
    });

    test('adds new book successfully', () async {
      const newBook = Book(
        id: '2',
        title: 'The Pragmatic Programmer',
        author: 'Andy Hunt',
      );

      final client = MockClient((request) async {
        if (request.url.path == '/books' && request.method == 'POST') {
          return http.Response(jsonEncode(newBook.toJson()), 201);
        }
        return http.Response('Bad Request', 400);
      });

      final service = ShelfTxtApiService(client: client);
      final created = await service.addBook(newBook);

      expect(created.title, 'The Pragmatic Programmer');
    });

    test('handles health check properly', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('Down', 500);
      });

      final service = ShelfTxtApiService(client: client);
      final isHealthy = await service.checkHealth();

      expect(isHealthy, isTrue);
    });
  });
}
