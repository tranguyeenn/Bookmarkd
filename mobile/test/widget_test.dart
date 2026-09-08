import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelftxt_mobile/main.dart';
import 'package:shelftxt_mobile/services/shelftxt_api_service.dart';
import 'package:shelftxt_mobile/widgets/book_card.dart';

void main() {
  testWidgets('ShelfTxtApp smoke test', (WidgetTester tester) async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'books': [
            {
              'id': '1',
              'title': 'Test Driven Development',
              'author': 'Kent Beck',
              'total_pages': 220,
              'current_page': 110,
              'status': 'reading',
            }
          ],
          'total': 1,
        }),
        200,
      );
    });

    final service = ShelfTxtApiService(client: client);

    await tester.pumpWidget(ShelfTxtApp(apiService: service));
    await tester.pumpAndSettle();

    expect(find.text('ShelfTxt Library'), findsOneWidget);
    expect(find.byType(BookCard), findsOneWidget);
    expect(find.text('Test Driven Development'), findsOneWidget);
  });
}
