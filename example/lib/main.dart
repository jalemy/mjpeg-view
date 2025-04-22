import 'package:flutter/material.dart';
import 'package:mjpeg_view/mjpeg_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Root widget
      home: Scaffold(
        appBar: AppBar(title: const Text('mjpeg_view demo')),
        body: Center(
          child: Column(
            children: [
              MjpegView(
                uri: 'http://pendelcam.kip.uni-heidelberg.de/mjpg/video.mjpg',
              ),
              SizedBox(height: 16),
              MjpegView(
                uri: 'http://pendelcam.kip.uni-heidelberg.de/mjpg/video.mjpg',
                fps: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
