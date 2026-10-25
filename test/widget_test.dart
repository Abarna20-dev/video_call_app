import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:video_call_ap/main.dart';

void main() {
  testWidgets('JoinPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: JoinPage()));
    expect(find.text('Join'), findsOneWidget);
  });
}
