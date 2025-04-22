import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart';
import 'package:mjpeg_view/mjpeg_stream_reader.dart';
import 'package:mjpeg_view/utils.dart';
import 'package:rxdart/rxdart.dart';

class MjpegView extends HookWidget {
  const MjpegView({
    required this.uri,
    this.fit,
    this.width,
    this.height,
    this.timeout = const Duration(seconds: 5),
    this.loadingWidget,
    this.client,
    this.fps = 30,
    this.onError,
    this.errorWidget,
    this.doneWidget,
    super.key,
  });

  final String uri;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Duration timeout;
  final WidgetBuilder? loadingWidget;
  final Client? client;
  final double fps;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final WidgetBuilder? errorWidget;
  final WidgetBuilder? doneWidget;

  @override
  Widget build(BuildContext context) {
    final activeStream = useState<Stream<Uint8List>?>(null);

    // state of reconnecting
    final reconnectTrigger = useState(0);

    // Generate and start a MjpgStreamReader.
    useEffect(() {
      final newReader = MjpegStreamReader(
        uri: uri,
        client: client,
        timeout: timeout,
      );

      // NOTE: calculate frame update time. ex: for 30 fps, 33.333... ≒ 33ms
      final frameDuration = (fps > 0)
          ? Duration(milliseconds: (1000 / fps).round())
          : Duration.zero;

      /**
       * NOTE: frame control is performed using rxdart.
       *       if fps is less than 0, frame control is not preformed.
       */
      final streamToUse = (frameDuration > Duration.zero)
          ? newReader.stream.throttleTime(
              frameDuration,
              leading: false,
              trailing: true,
            )
          : newReader.stream;

      activeStream.value = streamToUse;
      newReader.start();

      return () {
        newReader.dispose();
      };
    }, [uri, client, timeout, fps, reconnectTrigger.value]);

    // Subscribe to MjpegStreamReader.
    final snapshot = useStream(activeStream.value, initialData: null);

    // ↓--- Building UI ---↓

    // Error occurred.
    if (snapshot.hasError) {
      logDebug('Displaying error widget.');

      Future.microtask(() {
        onError?.call(snapshot.error!, StackTrace.current);
      });

      return errorWidget != null
          ? errorWidget!(context)
          : _buildErrorWidget(
              width,
              height,
              'Connection Failed.',
              () => reconnectTrigger.value++,
            );
    }

    // Stream Done.
    if (snapshot.connectionState == ConnectionState.done) {
      logDebug('Displaying stream done widget.');

      return doneWidget != null
          ? doneWidget!(context)
          : _buildDoneWidget(width, height, 'Stream ended.');
    }

    // Connection is active, normal.
    if (snapshot.hasData &&
        snapshot.connectionState == ConnectionState.active) {
      final imageBytes = snapshot.data!;

      return Image.memory(
        imageBytes,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true, // suppress flickering
      );
    }

    // loading.
    logDebug(
      'Displaying loading widget. (connectionState: ${snapshot.connectionState})',
    );
    return SizedBox(
      width: width,
      height: height,
      child: loadingWidget != null
          ? loadingWidget!(context)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorWidget(
    double? width,
    double? height,
    String message,
    VoidCallback onReconnect,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Reconnect'),
              onPressed: onReconnect,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneWidget(double? width, double? height, String message) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.done_outline, color: Colors.blue, size: 40),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}
