import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mjpeg_view/mjpeg_stream_reader.dart';

import 'mock_client.dart';

void main() {
  late StreamController<List<int>> mockStreamController;
  late MockClient mockClient;
  late MjpegStreamReader reader;
  final uri = 'http://example.com/mjpeg';

  group('http status code: 40x', () {
    tearDown(() {
      reader.dispose();

      mockClient.close();

      if (!mockStreamController.isClosed) {
        mockStreamController.close();
      }
    });

    mockStreamController = StreamController<List<int>>();
    mockClient = MockClient(controller: mockStreamController, statusCode: 400);

    reader = MjpegStreamReader(uri: uri, client: mockClient);

    test('receive 400 status code.', () async {
      reader.start();
    });
  });

  group('http staus code: 200', () {
    setUp(() {
      mockStreamController = StreamController<List<int>>();

      mockClient =
          MockClient(controller: mockStreamController, statusCode: 200);

      reader = MjpegStreamReader(uri: uri, client: mockClient);
    });

    tearDown(() {
      reader.dispose();

      mockClient.close();

      if (!mockStreamController.isClosed) {
        mockStreamController.close();
      }
    });

    test('receive chunks containing SOI, then EOI, then stream ends.',
        () async {
      expectLater(
          reader.stream,
          emitsInOrder([
            Uint8List.fromList(
                [0xFF, 0xD8, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0xFF, 0xD9]),
            emitsDone
          ]));

      await reader.start();

      mockStreamController.add([0xFF, 0xD8, 0x01, 0x02, 0x03, 0x04]);
      await Future.delayed(Duration(milliseconds: 100));
      mockStreamController.add([0x05, 0x06, 0xFF, 0xD9]);
      await Future.delayed(Duration(milliseconds: 100));

      reader.stop(closeController: true);
    });

    test(
        'receive random chunks, then SOI, then random chunks, then EOI, then stream ends.',
        () async {
      expectLater(
          reader.stream,
          emitsInOrder([
            Uint8List.fromList(
                [0xFF, 0xD8, 0x01, 0x02, 0x03, 0x04, 0xFF, 0xD9]),
            emitsDone
          ]));

      await reader.start();

      mockStreamController.add([0x33, 0x33]);
      await Future.delayed(Duration(milliseconds: 100));
      mockStreamController.add([0xFF, 0xD8, 0x01, 0x02]);
      await Future.delayed(Duration(milliseconds: 100));
      mockStreamController.add([0x03, 0x04]);
      await Future.delayed(Duration(milliseconds: 100));
      mockStreamController.add([0xFF, 0xD9]);
      await Future.delayed(Duration(milliseconds: 100));

      reader.stop(closeController: true);
    });

    test('receive chunks containing SOI and EOI.', () async {
      expectLater(
          reader.stream,
          emitsInOrder([
            Uint8List.fromList([0xFF, 0xD8, 0x01, 0x02, 0xFF, 0xD9]),
            emitsDone
          ]));

      await reader.start();

      mockStreamController.add([0xFF, 0xD8, 0x01, 0x02, 0xFF, 0xD9]);
      await Future.delayed(Duration(milliseconds: 100));

      reader.stop(closeController: true);
    });

    test('already close.', () async {
      reader.stop(closeController: true);

      reader.start();
    });

    test('stream terminates.', () {
      reader.start();

      mockStreamController.close();
    });

    test('error during stream.', () {
      reader.start();

      mockStreamController.addError(Exception());
    });
  });
}
