import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/shelftxt_api_service.dart';
import '../widgets/book_card.dart';
import '../widgets/state_views.dart';

class LibraryScreen extends StatefulWidget {
  final ShelfTxtApiService apiService;

  const LibraryScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Book> _books = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  final List<BookStatus?> _tabs = [
    null, // All
    BookStatus.reading,
    BookStatus.notStarted,
    BookStatus.completed,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadBooks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final page = await widget.apiService.getBooks();
      if (!mounted) return;
      setState(() {
        _books = page.items;
        _isLoading = false;
        _errorMessage = null;
      });
    } on ShelfTxtApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred: $e';
      });
    }
  }

  List<Book> _getFilteredBooks() {
    final currentStatusFilter = _tabs[_tabController.index];
    return _books.where((book) {
      final matchesStatus = currentStatusFilter == null || book.status == currentStatusFilter;
      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  void _openAddBookDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final pagesController = TextEditingController();
    var selectedStatus = BookStatus.notStarted;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Book'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(labelText: 'Author *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pagesController,
                    decoration: const InputDecoration(labelText: 'Total Pages', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<BookStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: BookStatus.values.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStatus = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final author = authorController.text.trim();
                  if (title.isEmpty || author.isEmpty) return;

                  final newBook = Book(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    author: author,
                    totalPages: int.tryParse(pagesController.text.trim()),
                    status: selectedStatus,
                  );

                  Navigator.of(ctx).pop();
                  try {
                    await widget.apiService.addBook(newBook);
                    _loadBooks();
                  } catch (_) {
                    setState(() {
                      _books.insert(0, newBook);
                    });
                  }
                },
                child: const Text('Save Book'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openServerSettings() {
    final controller = TextEditingController(text: widget.apiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server Configuration'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ShelfTxt Base URL',
            hintText: 'http://127.0.0.1:8000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                widget.apiService.baseUrl = val;
                _loadBooks();
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save & Reconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _getFilteredBooks();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ShelfTxt Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.apiService.baseUrl, style: theme.textTheme.labelSmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Server Settings',
            onPressed: _openServerSettings,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadBooks,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Books'),
            Tab(text: 'Reading'),
            Tab(text: 'Want to Read'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBookDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
      body: _buildBody(filtered),
    );
  }

  Widget _buildBody(List<Book> filtered) {
    if (_isLoading) {
      return const LoadingView();
    }

    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _loadBooks,
        onSettings: _openServerSettings,
      );
    }

    if (_books.isEmpty) {
      return EmptyLibraryView(onAddBook: _openAddBookDialog);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search books by title, author...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No books matching filter.'))
              : RefreshIndicator(
                  onRefresh: _loadBooks,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => BookCard(book: filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }
}
