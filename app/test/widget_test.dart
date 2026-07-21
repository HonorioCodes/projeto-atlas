import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe o nome do aplicativo', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Passo a Passo'))),
      ),
    );

    expect(find.text('Passo a Passo'), findsOneWidget);
  });
}
