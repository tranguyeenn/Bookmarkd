import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/shelftxt_api_service.dart';
import '../viewmodels/library_viewmodel.dart';
import '../widgets/book_card.dart';
import '../widgets/state_views.dart';

/// Main library screen representing the View in the MVVM pattern.
///
/// Reactively binds to [LibraryViewModel] using [ListenableBuilder].
class LibraryScreen extends StatefulWidget {
  final ShelfTxtApiService? apiService;
  final LibraryViewModel? viewModel;

  const LibraryScreen({
    super.key,
    this.apiService,
    this.viewModel,
  }) : assert(apiService != null || viewModel != null,
            'Either apiService or viewModel must be provided');

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final LibraryViewModel _viewModel;
  late final bool _ownsViewModel;
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<BookStatus?> _tabs = [
    null, // All
    BookStatus.reading,
    BookStatus.notStarted,
    BookStatus.completed,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _ownsViewModel = false;
    } else {
      _viewModel = LibraryViewModel(apiService: widget.apiService!);
      _ownsViewModel = true;
    }

    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _viewModel.setStatusFilter(_tabs[_tabController.index]);
      }
    });

    if (_viewModel.state == LibraryViewState.initial) {
      _viewModel.loadBooks();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
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
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pagesController,
                    decoration: const InputDecoration(
                      labelText: 'Total Pages',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<BookStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
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
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
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
                  await _viewModel.addBook(newBook);
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
    final controller = TextEditingController(text: _viewModel.apiService.baseUrl);
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                _viewModel.apiService.baseUrl = val;
                _viewModel.loadBooks();
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

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final filtered = _viewModel.filteredBooks;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ShelfTxt Library',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(_viewModel.apiService.baseUrl, style: theme.textTheme.labelSmall),
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
                onPressed: _viewModel.isLoading ? null : _viewModel.refresh,
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
      },
    );
  }

  Widget _buildBody(List<Book> filtered) {
    if (_viewModel.isLoading) {
      return const LoadingView();
    }

    if (_viewModel.hasError) {
      return ErrorView(
        message: _viewModel.errorMessage ?? 'An error occurred',
        onRetry: _viewModel.loadBooks,
        onSettings: _openServerSettings,
      );
    }

    if (_viewModel.isEmpty) {
      return EmptyLibraryView(onAddBook: _openAddBookDialog);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search books by title, author...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.zero,
              suffixIcon: _viewModel.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _viewModel.setSearchQuery('');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => _viewModel.setSearchQuery(val),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No books matching filter.'))
              : RefreshIndicator(
                  onRefresh: _viewModel.refresh,
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
