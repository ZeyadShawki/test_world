import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

abstract class FloodFill<T, S> {
  final T image;
  const FloodFill(this.image);
  FutureOr<T?> fill(int startX, int startY, S newColor);
}

Future<ByteData?> imageToBytes(ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return bytes;
}

Future<ui.Image> imageFromBytes(
    ByteData bytes, int imageWidth, int imageHeight) {
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromPixels(
    bytes.buffer.asUint8List(),
    imageWidth,
    imageHeight,
    ui.PixelFormat.rgba8888,
    (img) {
      completer.complete(img);
    },
  );
  return completer.future;
}

void setPixelColor({
  required int x,
  required int y,
  required ByteData bytes,

  // for correct representation of color bytes' coordinates
  // in an array of image bytes
  required int imageWidth,
  required ui.Color newColor,
}) {
  bytes.setUint32(
    (x + y * imageWidth) * 4, // offset
    colorToIntRGBA(newColor), // value
  );
}

ui.Color getPixelColor({
  required ByteData bytes,
  required int x,
  required int y,
  required int imageWidth,
}) {
  final uint32 = bytes.getUint32((x + y * imageWidth) * 4);
  return colorFromIntRGBA(uint32);
}

int colorToIntRGBA(ui.Color color) {
  // Extract ARGB components
  int a = (color.value >> 24) & 0xFF;
  int r = (color.value >> 16) & 0xFF;
  int g = (color.value >> 8) & 0xFF;
  int b = color.value & 0xFF;

  // Convert to RGBA and combine into a single integer
  return (r << 24) | (g << 16) | (b << 8) | a;
}

ui.Color colorFromIntRGBA(int uint32Rgba) {
  // Extract RGBA components
  int r = (uint32Rgba >> 24) & 0xFF;
  int g = (uint32Rgba >> 16) & 0xFF;
  int b = (uint32Rgba >> 8) & 0xFF;
  int a = uint32Rgba & 0xFF;

  // Convert to ARGB format and create a Color object
  return ui.Color.fromARGB(a, r, g, b);
}

bool isAlmostSameColor({
  required ui.Color pixelColor,
  required ui.Color checkColor,
  required int imageWidth,
}) {
  const int threshold = 50;
  final int rDiff = (pixelColor.red - checkColor.red).abs();
  final int gDiff = (pixelColor.green - checkColor.green).abs();
  final int bDiff = (pixelColor.blue - checkColor.blue).abs();
  return rDiff < threshold && gDiff < threshold && bDiff < threshold;
}

class ImageFloodFill extends FloodFill<ui.Image, ui.Color> {
  ImageFloodFill(ui.Image image) : super(image);

  @override
  Future<ui.Image?> fill(int startX, int startY, ui.Color newColor) async {
    ByteData? byteData = await imageToBytes(image);
    if (byteData == null) return null;

    int width = image.width;
    int height = image.height;
    ui.Color originalColor = getPixelColor(
      bytes: byteData,
      x: startX,
      y: startY,
      imageWidth: width,
    );

    if (!isAlmostSameColor(
        pixelColor: originalColor, checkColor: newColor, imageWidth: width)) {
      _floodFillIterative(
          byteData, startX, startY, width, height, originalColor, newColor);
    }

    return imageFromBytes(byteData, width, height);
  }

  // Function to calculate the fill area size without modifying the image
  Future<int> calculateFillAreaSize(int startX, int startY) async {
    ByteData? byteData = await imageToBytes(image);
    if (byteData == null) return 0;

    int width = image.width;
    int height = image.height;
    ui.Color originalColor = getPixelColor(
      bytes: byteData,
      x: startX,
      y: startY,
      imageWidth: width,
    );

    return _calculateFillAreaSize(
        byteData, startX, startY, width, height, originalColor);
  }

  int _calculateFillAreaSize(ByteData bytes, int startX, int startY, int width,
      int height, ui.Color originalColor) {
    Queue<Point> queue = Queue();
    queue.add(Point(startX, startY));

    List<bool> visited = List.filled(width * height, false);
    int areaSize = 0;

    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      final px = point.x;
      final py = point.y;
      final idx = px + py * width;

      if (!_isInside(px, py, width, height) ||
          visited[idx] ||
          !isAlmostSameColor(
            pixelColor:
                getPixelColor(bytes: bytes, x: px, y: py, imageWidth: width),
            checkColor: originalColor,
            imageWidth: width,
          )) {
        continue;
      }

      visited[idx] = true;
      areaSize++;

      queue.add(Point(px + 1, py)); // East
      queue.add(Point(px - 1, py)); // West
      queue.add(Point(px, py + 1)); // South
      queue.add(Point(px, py - 1)); // North
    }

    return areaSize;
  }

  void _floodFillIterative(
    ByteData bytes,
    int x,
    int y,
    int width,
    int height,
    ui.Color originalColor,
    ui.Color newColor,
  ) {
    Queue<Point> queue = Queue();
    queue.add(Point(x, y));

    List<bool> visited = List.filled(width * height, false);

    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      final px = point.x;
      final py = point.y;
      final idx = px + py * width;

      if (!_isInside(px, py, width, height) ||
          visited[idx] ||
          !isAlmostSameColor(
            pixelColor:
                getPixelColor(bytes: bytes, x: px, y: py, imageWidth: width),
            checkColor: originalColor,
            imageWidth: width,
          )) {
        continue;
      }

      visited[idx] = true;
      setPixelColor(
          x: px, y: py, bytes: bytes, imageWidth: width, newColor: newColor);

      queue.add(Point(px + 1, py)); // East
      queue.add(Point(px - 1, py)); // West
      queue.add(Point(px, py + 1)); // South
      queue.add(Point(px, py - 1)); // North
    }
  }

  bool _isInside(int x, int y, int width, int height) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }
}

class Point {
  final int x, y;
  Point(this.x, this.y);
}
