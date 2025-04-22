import 'package:flutter/foundation.dart';

void logDebug(String message) {
  if (kDebugMode) {
    print('mjpeg_view: $message');
  }
}
