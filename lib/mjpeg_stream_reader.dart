import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:mjpeg_view/utils.dart';

/// MjpegStreamReader retrieves a motion jpeg(mjpeg) stream from the specified uri and publishes the jpeg frame.
class MjpegStreamReader {
  final String uri;
  final Client _client;
  final bool _isInnerClient;
  final Duration timeout;

  final _controller = StreamController<Uint8List>();
  StreamSubscription? _subscription;

  /// --- motion jpeg constants ---
  static const _trigger = 0xFF;
  static const _soi = 0xD8;
  static const _eoi = 0xD9;
  static const _markerLength = 2;
  static const List<int> _soiSequence = [_trigger, _soi];
  static const List<int> _eoiSequence = [_trigger, _eoi];

  final List<int> _receivedBuffer = [];
  int _soiSearchStartIndex = 0;
  int _foundSoiIndex = -1;

  /// Constructor
  /// [uri] specifies the motion jpeg(mjpeg) stream url.
  /// [client] specifies the HTTP client. If not specified, it is generated internally.
  /// [timeout] specifies the HTTP connection timeout.
  MjpegStreamReader({
    required this.uri,
    Client? client,
    this.timeout = const Duration(seconds: 5),
  })  : _client = client ?? Client(),
        _isInnerClient = client == null;

  Stream<Uint8List> get stream => _controller.stream;

  /// Connect to the specified uri, parses the chunks, and add jpeg frame to stream to view.
  Future<void> start() async {
    if (_controller.isClosed) {
      logDebug('Stream controller closed.');

      return;
    }

    /// reset status, and cancel existing subscription
    _resetState();
    _subscription?.cancel();

    logDebug('Starting connection to [$uri].');

    try {
      final request = Request('GET', Uri.parse(uri));
      final response = await _client.send(request).timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        logDebug('Connected $uri - (status code: ${response.statusCode})');

        _subscription = response.stream.listen(
          _handleChunk,
          onDone: () {
            logDebug('Done received.');

            stop(closeController: true);
          },
          onError: (e, s) {
            logDebug('Error received - (error: $e)');

            _controller.addError(e, s);
            stop(closeController: true);
          },
          cancelOnError: true, // auto cancel on error
        );
      } else {
        logDebug(
          'Connection failed $uri - (status code: ${response.statusCode})',
        );

        if (!_controller.isClosed) {
          final error = HttpException(
            'Connection failed $uri - (status code: ${response.statusCode})',
            uri: Uri.parse(uri),
          );

          _controller.addError(error, StackTrace.current);
        }

        stop(closeController: true);
      }
    } catch (e, s) {
      logDebug('Exception during connection - $e');

      if (!_controller.isClosed) {
        _controller.addError(e, s);
      }

      stop(closeController: true);
    }
  }

  void _resetState() {
    _receivedBuffer.clear();
    _soiSearchStartIndex = 0;
    _foundSoiIndex = -1;
  }

  /// Cancel the subscription to stream, and reset the internal state.
  /// [closeController] if true, close the internal streamcontroller.
  void stop({bool closeController = false}) {
    logDebug('Stopped listening.');

    _subscription?.cancel();
    _subscription = null;
    _resetState();

    if (closeController && !_controller.isClosed) {
      _controller.close();
    }
  }

  /// Cancel the subscription to stream, and reset the internal state,
  /// then close the internal stream controller.
  ///
  /// if the HTTP client is internally generated, close it.
  void dispose() {
    logDebug('Disposing stream reader.');

    stop(closeController: true);

    if (_isInnerClient) {
      _client.close();
    }
  }

  int _findIndex(List<int> bytes, List<int> sequence, {int startIndex = 0}) {
    if (sequence.isEmpty) {
      return -1;
    }

    if (bytes.length < sequence.length + startIndex) {
      return -1;
    }

    for (int i = startIndex; i <= bytes.length - sequence.length; i++) {
      bool match = true;

      for (int j = 0; j < sequence.length; j++) {
        if (bytes[i + j] != sequence[j]) {
          match = false;
          break;
        }
      }

      if (match) {
        return i;
      }
    }

    return -1;
  }

  void _handleChunk(List<int> chunk) {
    if (_controller.isClosed) {
      return;
    }

    _receivedBuffer.addAll(chunk);

    while (true) {
      if (_controller.isClosed) {
        break;
      }

      // when the SOI Marker has been found.
      if (_foundSoiIndex != -1) {
        final int eoiSearchStartIndex = _foundSoiIndex + _markerLength;

        if (_receivedBuffer.length < eoiSearchStartIndex + _markerLength) {
          break;
        }

        final int foundEoiIndex = _findIndex(
          _receivedBuffer,
          _eoiSequence,
          startIndex: eoiSearchStartIndex,
        );

        if (foundEoiIndex == -1) {
          break;
        } else {
          final frame = _receivedBuffer.sublist(
            _foundSoiIndex,
            foundEoiIndex + _markerLength,
          );

          if (frame.isNotEmpty && !_controller.isClosed) {
            _controller.add(Uint8List.fromList(frame));
          }

          _receivedBuffer.removeRange(0, foundEoiIndex + _markerLength);
          _soiSearchStartIndex = 0;
          _foundSoiIndex = -1;
        }
      } else {
        // when the SOI Marker has not been found.
        if (_receivedBuffer.length < _soiSearchStartIndex + _markerLength) {
          break;
        }

        _foundSoiIndex = _findIndex(
          _receivedBuffer,
          _soiSequence,
          startIndex: _soiSearchStartIndex,
        );

        if (_foundSoiIndex == -1) {
          _soiSearchStartIndex = max(0, _receivedBuffer.length - _markerLength);
          break;
        } else {
          final int eoiSearchStartIndex = _foundSoiIndex + _markerLength;

          if (_receivedBuffer.length < eoiSearchStartIndex + _markerLength) {
            break;
          }

          final int foundEoiIndex = _findIndex(
            _receivedBuffer,
            _eoiSequence,
            startIndex: eoiSearchStartIndex,
          );

          if (foundEoiIndex == -1) {
            break;
          } else {
            final frame = _receivedBuffer.sublist(
              _foundSoiIndex,
              foundEoiIndex + _markerLength,
            );

            if (frame.isNotEmpty) {
              _controller.add(Uint8List.fromList(frame));
            }

            _receivedBuffer.removeRange(0, foundEoiIndex + _markerLength);
            _soiSearchStartIndex = 0;
            _foundSoiIndex = -1;
          }
        }
      }
    }
  }
}
