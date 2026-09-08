import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/shelftxt_api_service.dart';

/// States representing the lifecycle of library books loading.
enum LibraryViewState {
  initial,
  loading,
  loaded,
  empty,
  error,
}

/// ViewModel for the ShelfTxt Library Screen following the MVVM pattern.
///
/// Encapsulates state management, search/status filtering, and backend interactions.
class LibraryViewModel extends ChangeNotifier {
  final ShelfTxtApiService apiService;

  LibraryViewState _state = LibraryViewState.initial;
  List<Book> _books = [];
  String? _errorMessage;
  String _searchQuery = '';
  BookStatus? _selectedStatus;

  LibraryViewModel({required this.apiService});

  // --- Getters ---

  LibraryViewState get state => _state;
  bool get isLoading => _state == LibraryViewState.loading;
  bool get hasError => _state == LibraryViewState.error;
  bool get isEmpty => _state == LibraryViewState.empty;
  bool get isLoaded => _state == LibraryViewState.loaded;

  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  BookStatus? get selectedStatus => _selectedStatus;
  List<Book> get books => List.unmodifiable(_books);

  /// Computes filtered books according to the selected tab status and search query.
  List<Book> get filteredBooks {
    return _books.where((book) {
      final matchesStatus =
          _selectedStatus == null || book.status == _selectedStatus;

      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);

      return matchesStatus && matchesQuery;
    }).toList();
  }

  // --- Actions ---

  /// Fetches books from the ShelfTxt REST API.
  Future<void> loadBooks() async {
    _state = LibraryViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await apiService.getBooks();
      _books = page.items;
      _state = _books.isEmpty ? LibraryViewState.empty : LibraryViewState.loaded;
      _errorMessage = null;
    } on ShelfTxtApiException catch (e) {
      _state = LibraryViewState.error;
      _errorMessage = e.message;
    } catch (e) {
      _state = LibraryViewState.error;
      _errorMessage = 'An unexpected error occurred: $e';
    }

    notifyListeners();
  }

  /// Alias for pull-to-refresh.
  Future<void> refresh() => loadBooks();

  /// Adds a new book to the library via the API.
  Future<bool> addBook(Book book) async {
    try {
      final created = await apiService.addBook(book);
      _books = [created, ..._books];
      _state = LibraryViewState.loaded;
      notifyListeners();
      return true;
    } on ShelfTxtApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create book: $e';
      notifyListeners();
      return false;
    }
  }

  /// Updates the status filter (e.g. from tab selection).
  void setStatusFilter(BookStatus? status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    notifyListeners();
  }

  /// Updates the search filter query.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }
}
