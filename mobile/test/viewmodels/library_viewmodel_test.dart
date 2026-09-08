import 'package:flutter_test/flutter_test.dart';
import 'package:shelftxt_mobile/models/book.dart';
import 'package:shelftxt_mobile/services/shelftxt_api_service.dart';
import 'package:shelftxt_mobile/viewmodels/library_viewmodel.dart';

class MockShelfTxtApiService extends ShelfTxtApiService {
  MockShelfTxtApiService({super.baseUrl = 'http://test.local:8000'});

  List<Book> mockBooks = [];
  bool shouldThrow = false;
  String errorMessage = 'Server unreachable';

  @override
  Future<BooksPage> getBooks({
    int page = 1,
    int limit = 50,
    BookStatus? status,
  }) async {
    if (shouldThrow) {
      throw ShelfTxtNetworkException(serverUrl: baseUrl, message: errorMessage);
    }
    return BooksPage(
      items: List.from(mockBooks),
      total: mockBooks.length,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Book> addBook(Book book) async {
    if (shouldThrow) {
      throw ShelfTxtNetworkException(serverUrl: baseUrl, message: errorMessage);
    }
    mockBooks.insert(0, book);
    return book;
  }
}

void main() {
  group('LibraryViewModel Unit Tests (MVVM)', () {
    late MockShelfTxtApiService mockApi;
    late LibraryViewModel viewModel;

    final sampleBooks = [
      const Book(
        id: '1',
        title: 'Clean Architecture',
        author: 'Robert C. Martin',
        status: BookStatus.reading,
        totalPages: 400,
        currentPage: 150,
      ),
      const Book(
        id: '2',
        title: 'Design Patterns',
        author: 'Gang of Four',
        status: BookStatus.notStarted,
        totalPages: 395,
      ),
      const Book(
        id: '3',
        title: 'Refactoring',
        author: 'Martin Fowler',
        status: BookStatus.completed,
        totalPages: 448,
        currentPage: 448,
      ),
    ];

    setUp(() {
      mockApi = MockShelfTxtApiService();
      viewModel = LibraryViewModel(apiService: mockApi);
    });

    test('initial state is correct', () {
      expect(viewModel.state, LibraryViewState.initial);
      expect(viewModel.books, isEmpty);
      expect(viewModel.selectedStatus, isNull);
      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.errorMessage, isNull);
    });

    test('loadBooks transitions to loaded on success', () async {
      mockApi.mockBooks = sampleBooks;

      final future = viewModel.loadBooks();
      expect(viewModel.isLoading, isTrue);

      await future;

      expect(viewModel.state, LibraryViewState.loaded);
      expect(viewModel.isLoaded, isTrue);
      expect(viewModel.books.length, 3);
    });

    test('loadBooks transitions to empty when API returns empty list', () async {
      mockApi.mockBooks = [];

      await viewModel.loadBooks();

      expect(viewModel.state, LibraryViewState.empty);
      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.books, isEmpty);
    });

    test('loadBooks transitions to error when network fails', () async {
      mockApi.shouldThrow = true;
      mockApi.errorMessage = 'Backend 500';

      await viewModel.loadBooks();

      expect(viewModel.state, LibraryViewState.error);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.errorMessage, 'Backend 500');
    });

    test('filteredBooks filters by status and search query', () async {
      mockApi.mockBooks = sampleBooks;
      await viewModel.loadBooks();

      viewModel.setStatusFilter(BookStatus.reading);
      expect(viewModel.filteredBooks.length, 1);
      expect(viewModel.filteredBooks.first.id, '1');

      viewModel.setStatusFilter(null);
      viewModel.setSearchQuery('Fowler');
      expect(viewModel.filteredBooks.length, 1);
      expect(viewModel.filteredBooks.first.title, 'Refactoring');
    });

    test('addBook inserts new book to top of list', () async {
      mockApi.mockBooks = List.from(sampleBooks);
      await viewModel.loadBooks();

      const newBook = Book(
        id: '4',
        title: 'Flutter in Action',
        author: 'Eric Windmill',
        status: BookStatus.reading,
      );

      final success = await viewModel.addBook(newBook);
      expect(success, isTrue);
      expect(viewModel.books.first.title, 'Flutter in Action');
      expect(viewModel.books.length, 4);
    });
  });
}
