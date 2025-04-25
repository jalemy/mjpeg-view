import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjpeg_view/mjpeg_view.dart';

import 'mock_client.dart';
import 'mock_image.dart';

void main() {
  testWidgets(
      'Loading UI is displayed, then image stream received, then image widget is displayed.',
      (WidgetTester tester) async {
    final controller = StreamController<Uint8List>();
    final client = MockClient(controller: controller, statusCode: 200);

    await tester.pumpWidget(MaterialApp(
        home: MjpegView(uri: 'http://example.com', client: client)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.add(blue);

    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('400 status code received, and error widget is displayed.',
      (WidgetTester tester) async {
    final controller = StreamController<Uint8List>();
    final client = MockClient(controller: controller, statusCode: 400);

    await tester.pumpWidget(MaterialApp(
        home: MjpegView(
      uri: 'http://example.com',
      client: client,
      errorWidget: (context) => Text('error widget!'),
    )));

    await tester.pumpAndSettle();

    expect(find.text('error widget!'), findsOneWidget);
  });

  testWidgets(
      '400 status code received, and default error widget is displayed.',
      (WidgetTester tester) async {
    final controller = StreamController<Uint8List>();
    final client = MockClient(controller: controller, statusCode: 400);

    await tester.pumpWidget(MaterialApp(
        home: MjpegView(uri: 'http://example.com', client: client)));

    await tester.pumpAndSettle();

    expect(find.text('Reconnect'), findsOneWidget);
  });
}
