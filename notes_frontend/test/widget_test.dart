import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_frontend/main.dart';

void main() {
  testWidgets('App bar has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());

    // Will match the appbar title defined in NotesListPage
    expect(find.text('Notes'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Empty state message shown when no notes', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());

    // Wait for possible async loads
    await tester.pumpAndSettle();

    expect(find.textContaining('No notes yet.'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
