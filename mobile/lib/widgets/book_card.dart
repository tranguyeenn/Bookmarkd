import 'package:flutter/material.dart';
import '../models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
  });

  Color _getStatusColor(BuildContext context, BookStatus status) {
    switch (status) {
      case BookStatus.reading:
        return Colors.blue.shade700;
      case BookStatus.completed:
        return Colors.green.shade700;
      case BookStatus.dnf:
        return Colors.red.shade700;
      case BookStatus.notStarted:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(context, book.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover thumbnail
              Container(
                width: 54,
                height: 78,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(Icons.book_rounded, color: colorScheme.primary),
                      )
                    : Icon(Icons.book_rounded, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Progress Bar if reading
                    if (book.status == BookStatus.reading && book.totalPages != null) ...[
                      LinearProgressIndicator(
                        value: book.progressFraction,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${book.currentPage ?? 0} of ${book.totalPages} pages (${(book.progressFraction * 100).toInt()}%)',
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          book.status.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
