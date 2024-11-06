import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:collection';



abstract class FloodFill<T, S> {
  final T image;
  const FloodFill(this.image);
  FutureOr<T?> fill(int startX, int startY, S newColor);
}


Future<ByteData?> imageToBytes(ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return bytes;
}

Future<ui.Image> imageFromBytes(ByteData bytes, int imageWidth, int imageHeight) {
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








class BasicFloodFill extends FloodFill<List<List<int>>, int> {
  const BasicFloodFill(List<List<int>> image) : super(image);

  @override
  List<List<int>>? fill(int startX, int startY, int newColor) {
    int originalColor = image[startX][startY];
    _floodFillUtil(startX, startY, originalColor, newColor);
    return image;
  }

  void _floodFillUtil(int x, int y, int originalColor, int newColor) {
    // Check if current node is inside the boundary and not already filled
    if (!_isInside(x, y) || image[x][y] != originalColor) return;

    // Set the node
    image[x][y] = newColor;

    // Perform flood-fill one step in each direction
    _floodFillUtil(x + 1, y, originalColor, newColor); // South
    _floodFillUtil(x - 1, y, originalColor, newColor); // North
    _floodFillUtil(x, y - 1, originalColor, newColor); // West
    _floodFillUtil(x, y + 1, originalColor, newColor); // East
  }

  bool _isInside(int x, int y) {
    return x >= 0 && x < image.length && y >= 0 && y < image[0].length;
  }
}

class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);
}

class FloodFillQueueImpl extends FloodFill<List<List<int>>, int> {
  const FloodFillQueueImpl(List<List<int>> image) : super(image);

  @override
  List<List<int>>? fill(int startX, int startY, int newColor) {
    final int oldColor = image[startX][startY];
    final int width = image[0].length;
    final int height = image.length;
    final Queue<Point> queue = Queue();
    queue.add(Point(startY, startX));

    while (queue.isNotEmpty) {
      final Point point = queue.removeFirst();
      final int x = point.x;
      final int y = point.y;

      if (image[y][x] == oldColor) {
        image[y][x] = newColor;

        if (x > 0) {
          queue.add(Point(x - 1, y));
        }
        if (x < width - 1) {
          queue.add(Point(x + 1, y));
        }
        if (y > 0) {
          queue.add(Point(x, y - 1));
        }
        if (y < height - 1) {
          queue.add(Point(x, y + 1));
        }
      }
    }
    return image;
  }
}

class FloodFillSpanImpl extends FloodFill<List<List<int>>, int> {
  const FloodFillSpanImpl(List<List<int>> image) : super(image);

  // Check if the point is inside the canvas and matches the target color
  bool _isInside(int x, int y, int targetColor) {
    return x >= 0 && y >= 0 && x < image.length && y < image[0].length && image[x][y] == targetColor;
  }

  // Set a point to the replacement color
  void _setColor(int x, int y, int replacementColor) {
    image[x][y] = replacementColor;
  }

  @override
  List<List<int>>? fill(int startX, int startY, int newColor) {
    final targetColor = image[startX][startY];

    if (!_isInside(startX, startY, targetColor)) return null;

    var s = <List<int>>[];
    s.add([startX, startX, startY, 1]);
    s.add([startX, startX, startY - 1, -1]);

    while (s.isNotEmpty) {
      var tuple = s.removeLast();
      var x1 = tuple[0];
      var x2 = tuple[1];
      var y = tuple[2];
      var dy = tuple[3];

      var nx = x1;
      if (_isInside(nx, y, targetColor)) {
        while (_isInside(nx - 1, y, targetColor)) {
          _setColor(nx - 1, y, newColor);
          nx--;
        }
        if (nx < x1) {
          s.add([nx, x1 - 1, y - dy, -dy]);
        }
      }

      while (x1 <= x2) {
        while (_isInside(x1, y, targetColor)) {
          _setColor(x1, y, newColor);
          x1++;
        }
        if (x1 > nx) {
          s.add([nx, x1 - 1, y + dy, dy]);
        }
        if (x1 - 1 > x2) {
          s.add([x2 + 1, x1 - 1, y - dy, -dy]);
        }
        x1++;
        while (x1 < x2 && !_isInside(x1, y, targetColor)) {
          x1++;
        }
        nx = x1;
      }
    }
    return image;
  }
}



class ImageFloodFill extends FloodFill<ui.Image, ui.Color> {
  ImageFloodFill(ui.Image image) : super(image);

  @override
  Future<ui.Image?> fill(int startX, int startY, ui.Color newColor) async {
    ByteData? byteData = await imageToBytes(image);
    if (byteData == null) return null;

    int width = image.width;
    int height = image.height;
    ui.Color originalColor = getPixelColor(bytes: byteData, x: startX, y: startY, imageWidth: width);

    _floodFillUtil(byteData, startX, startY, width, height, originalColor, newColor);
    
    return imageFromBytes(byteData, width, height);
  }

  void _floodFillUtil(ByteData bytes, int x, int y, int width, int height, ui.Color originalColor, ui.Color newColor) {
    // Check if current node is inside the boundary and not already filled
    if (!_isInside(x, y, width, height) || !isAlmostSameColor(pixelColor: getPixelColor(bytes: bytes, x: x, y: y, imageWidth: width), checkColor: originalColor, imageWidth: width)) return;

    // Set the node
    setPixelColor(x: x, y: y, bytes: bytes, imageWidth: width, newColor: newColor);

    // Perform flood-fill one step in each direction
    _floodFillUtil(bytes, x + 1, y, width, height, originalColor, newColor); // East
    _floodFillUtil(bytes, x - 1, y, width, height, originalColor, newColor); // West
    _floodFillUtil(bytes, x, y - 1, width, height, originalColor, newColor); // North
    _floodFillUtil(bytes, x, y + 1, width, height, originalColor, newColor); // South
  }

  bool _isInside(int x, int y, int width, int height) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }
}



class ImageFloodFillQueueImpl extends FloodFill<ui.Image, ui.Color> {
  ImageFloodFillQueueImpl(ui.Image image) : super(image);

  @override
  Future<ui.Image?> fill(int startX, int startY, ui.Color newColor) async {
    ByteData? byteData = await imageToBytes(image);
    if (byteData == null) return null;

    int width = image.width;
    int height = image.height;
    ui.Color oldColor = getPixelColor(bytes: byteData, x: startX, y: startY, imageWidth: width);

    final Queue<Point> queue = Queue();
    queue.add(Point(startX, startY));

    while (queue.isNotEmpty) {
      final Point point = queue.removeFirst();
      final int x = point.x;
      final int y = point.y;

      if (isAlmostSameColor(pixelColor: getPixelColor(bytes: byteData, x: x, y: y, imageWidth: width), checkColor: oldColor, imageWidth: width)) {
        setPixelColor(x: x, y: y, bytes: byteData, imageWidth: width, newColor: newColor);

        if (x > 0) queue.add(Point(x - 1, y));
        if (x < width - 1) queue.add(Point(x + 1, y));
        if (y > 0) queue.add(Point(x, y - 1));
        if (y < height - 1) queue.add(Point(x, y + 1));
      }
    }

    return imageFromBytes(byteData, width, height);
  }
}




class ImageFloodFillSpanImpl extends FloodFill<ui.Image, ui.Color> {
  ImageFloodFillSpanImpl(ui.Image image) : super(image);

  @override
  Future<ui.Image?> fill(int startX, int startY, ui.Color newColor) async {
    ByteData? byteData = await imageToBytes(image);
    if (byteData == null) return null;

    int width = image.width;
    int height = image.height;
    ui.Color targetColor = getPixelColor(bytes: byteData, x: startX, y: startY, imageWidth: width);

    var s = <List<int>>[];
    s.add([startX, startX, startY, 1]);
    s.add([startX, startX, startY - 1, -1]);

    while (s.isNotEmpty) {
      var tuple = s.removeLast();
      var x1 = tuple[0];
      var x2 = tuple[1];
      var y = tuple[2];
      var dy = tuple[3];

      var nx = x1;
      if (_isInside(nx, y, width, height, byteData, targetColor)) {
        while (_isInside(nx - 1, y, width, height, byteData, targetColor)) {
          setPixelColor(x: nx - 1, y: y, bytes: byteData, imageWidth: width, newColor: newColor);
          nx--;
        }
        if (nx < x1) {
          s.add([nx, x1 - 1, y - dy, -dy]);
        }
      }

      while (x1 <= x2) {
        while (_isInside(x1, y, width, height, byteData, targetColor)) {
          setPixelColor(x: x1, y: y, bytes: byteData, imageWidth: width, newColor: newColor);
          x1++;
        }
        if (x1 > nx) {
          s.add([nx, x1 - 1, y + dy, dy]);
        }
        if (x1 - 1 > x2) {
          s.add([x2 + 1, x1 - 1, y - dy, -dy]);
        }
        x1++;
        while (x1 < x2 && !_isInside(x1, y, width, height, byteData, targetColor)) {
          x1++;
        }
        nx = x1;
      }
    }

    return imageFromBytes(byteData, width, height);
  }

  bool _isInside(int x, int y, int width, int height, ByteData bytes, ui.Color targetColor) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return isAlmostSameColor(pixelColor: getPixelColor(bytes: bytes, x: x, y: y, imageWidth: width), checkColor: targetColor, imageWidth: width);
  }
}