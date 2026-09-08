import 'package:flutter_test/flutter_test.dart';
import 'package:shelftxt_mobile/models/book.dart';

void main() {
  group('Book Model Tests', () {
    test('parses Book from JSON correctly', () {
      final json = {
        'id': '101',
        'title': 'Clean Architecture',
        'author': 'Robert C. Martin',
        'total_pages': 350,
        'current_page': 175,
        'status': 'reading',
        'star_rating': 4.5,
        'description': 'A Craftsman Guide to Software Structure',
        'genres': ['Software', 'Architecture'],
      };

      final book = Book.fromJson(json);

      expect(book.id, '101');
      expect(book.title, 'Clean Architecture');
      expect(book.author, 'Robert C. Martin');
      expect(book.totalPages, 350);
      expect(book.currentPage, 175);
      expect(book.status, BookStatus.reading);
      expect(book.starRating, 4.5);
      expect(book.progressFraction, 0.5);
    });

    test('calculates progress fraction accurately', () {
      const readingBook = Book(
        id: '1',
        title: 'Book 1',
        author: 'Author 1',
        totalPages: 200,
        currentPage: 50,
        status: BookStatus.reading,
      );

      expect(readingBook.progressFraction, 0.25);

      const completedBook = Book(
        id: '2',
        title: 'Book 2',
        author: 'Author 2',
        status: BookStatus.completed,
      );

      expect(completedBook.progressFraction, 1.0);
    });

    test('serializes to JSON correctly', () {
      const book = Book(
        id: '3',
        title: 'Refactoring',
        author: 'Martin Fowler',
        totalPages: 400,
        status: BookStatus.notStarted,
      );

      final json = book.toJson();
      expect(json['id'], '3');
      expect(json['title'], 'Refactoring');
      expect(json['status'], 'not_started');
    });
  });
}
