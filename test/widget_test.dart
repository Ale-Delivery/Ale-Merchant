import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alee_client/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const AleeSellerApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
