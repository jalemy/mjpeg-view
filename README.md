# mjpeg_view

Provide a viewer to play motion jpeg as a Flutter widget.

## Usage

```dart
MjpegView(
  uri: 'http://192.168.0.1:8000/video.mjpg',
)
```

There is a repository that compiles links to publicly available motion jpegs.
These sources are good to try as well.(Be careful not to overload them.)
[https://github.com/AzwadFawadHasan/Public_MotionJPEG_Sources?tab=readme-ov-file](https://github.com/AzwadFawadHasan/Public_MotionJPEG_Sources?tab=readme-ov-file)

## API

Parameter | Required | Description
--- | --- | ---
uri | ⚪︎ | uri for mjepg stream
fit | | `boxFit` of the image
width | | `width` of the image
height | | `height` of the image
timeout | | HTTP request timeout time. default is 5 seconds.
client | | HTTP client used to retrieve mjpeg stream
fps | | number of frames updated per second
loadingWidget | | widget to display while loading
onError | | callback on error
errorWidget | | widgetbuilder to build a widget to display when an error occurs
doneWidget | | widgetbuilder to build a widget to stream terminated

## License

[MIT License](LICENSE)

## Credits

This library is inspired by the following repository

* [flutter_mjpeg](https://github.com/mylisabox/flutter_mjpeg) by [jaumard](https://github.com/jaumard)

Thank you for your great work<3
