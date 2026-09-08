/// Reading status enum for a book.
enum BookStatus {
  notStarted('not_started', 'Want to Read'),
  reading('reading', 'Reading'),
  completed('completed', 'Completed'),
  dnf('dnf', 'Did Not Finish');

  final String value;
  final String label;

  const BookStatus(this.value, this.label);

  static BookStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'reading':
        return BookStatus.reading;
      case 'completed':
        return BookStatus.completed;
      case 'dnf':
        return BookStatus.dnf;
      case 'not_started':
      default:
        return BookStatus.notStarted;
    }
  }
}

/// Model representing a Book in the ShelfTxt library.
class Book {
  final String id;
  final String title;
  final String author;
  final int? totalPages;
  final int? currentPage;
  final BookStatus status;
  final double? starRating;
  final String? description;
  final String? coverUrl;
  final List<String> genres;
  final List<String> subjects;
  final String? notes;
  final String? isbnUid;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.totalPages,
    this.currentPage,
    this.status = BookStatus.notStarted,
    this.starRating,
    this.description,
    this.coverUrl,
    this.genres = const <String>[],
    this.subjects = const <String>[],
    this.notes,
    this.isbnUid,
  });

  /// Calculates percentage progress from 0.0 to 1.0.
  double get progressFraction {
    if (status == BookStatus.completed) return 1.0;
    if (totalPages == null || totalPages == 0 || currentPage == null) return 0.0;
    return (currentPage! / totalPages!).clamp(0.0, 1.0);
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: (json['id'] ?? json['isbn_uid'] ?? json['title'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? (json['authors'] is List ? (json['authors'] as List).join(', ') : 'Unknown Author'),
      totalPages: json['total_pages'] is int ? json['total_pages'] as int : int.tryParse(json['total_pages']?.toString() ?? ''),
      currentPage: json['current_page'] is int ? json['current_page'] as int : int.tryParse(json['current_page']?.toString() ?? ''),
      status: BookStatus.fromString(json['status']?.toString()),
      starRating: json['star_rating'] is num ? (json['star_rating'] as num).toDouble() : double.tryParse(json['star_rating']?.toString() ?? ''),
      description: json['description']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const <String>[],
      subjects: (json['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const <String>[],
      notes: json['notes']?.toString(),
      isbnUid: json['isbn_uid']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      if (totalPages != null) 'total_pages': totalPages,
      if (currentPage != null) 'current_page': currentPage,
      'status': status.value,
      if (starRating != null) 'star_rating': starRating,
      if (description != null) 'description': description,
      if (coverUrl != null) 'cover_url': coverUrl,
      'genres': genres,
      'subjects': subjects,
      if (notes != null) 'notes': notes,
      if (isbnUid != null) 'isbn_uid': isbnUid,
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? totalPages,
    int? currentPage,
    BookStatus? status,
    double? starRating,
    String? description,
    String? coverUrl,
    List<String>? genres,
    List<String>? subjects,
    String? notes,
    String? isbnUid,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      starRating: starRating ?? this.starRating,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      genres: genres ?? this.genres,
      subjects: subjects ?? this.subjects,
      notes: notes ?? this.notes,
      isbnUid: isbnUid ?? this.isbnUid,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          author == other.author &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ author.hashCode ^ status.hashCode;
}

/// Paginated book response model.
class BooksPage {
  final List<Book> items;
  final int total;
  final int page;
  final int limit;

  const BooksPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory BooksPage.fromJson(Map<String, dynamic> json) {
    final rawList = json['books'] ?? json['items'] ?? (json is List ? json : []);
    final books = <Book>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          books.add(Book.fromJson(item));
        } else if (item is Map) {
          books.add(Book.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return BooksPage(
      items: books,
      total: json['total'] is int ? json['total'] as int : books.length,
      page: json['page'] is int ? json['page'] as int : 1,
      limit: json['limit'] is int ? json['limit'] as int : 20,
    );
  }
}
