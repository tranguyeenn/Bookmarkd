import 'package:flutter/material.dart';
import 'screens/library_screen.dart';
import 'services/shelftxt_api_service.dart';

void main() {
  runApp(const ShelfTxtApp());
}

class ShelfTxtApp extends StatefulWidget {
  final ShelfTxtApiService? apiService;

  const ShelfTxtApp({super.key, this.apiService});

  @override
  State<ShelfTxtApp> createState() => _ShelfTxtAppState();
}

class _ShelfTxtAppState extends State<ShelfTxtApp> {
  late final ShelfTxtApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ShelfTxtApiService();
  }

  @override
  void dispose() {
    if (widget.apiService == null) {
      _apiService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShelfTxt Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: LibraryScreen(apiService: _apiService),
    );
  }
}
