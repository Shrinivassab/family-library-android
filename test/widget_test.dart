import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_library_app/main.dart';

void main() {
  testWidgets('App launches and shows the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FamilyLibraryApp());

    expect(find.text('📚 Family Library AI Companion'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
