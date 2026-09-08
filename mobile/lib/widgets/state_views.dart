import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  final String message;
  const LoadingView({super.key, this.message = 'Loading your library...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onSettings;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 48, color: colorScheme.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Connection Error',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Connection'),
                ),
                if (onSettings != null)
                  OutlinedButton.icon(
                    onPressed: onSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Server Settings'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyLibraryView extends StatelessWidget {
  final String message;
  final VoidCallback onAddBook;

  const EmptyLibraryView({
    super.key,
    this.message = 'Your library is empty. Add your first book to get started!',
    required this.onAddBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: colorScheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 20),
            Text(
              'No Books Yet',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddBook,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Book'),
            ),
          ],
        ),
      ),
    );
  }
}
