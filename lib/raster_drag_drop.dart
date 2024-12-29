import 'dart:developer';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_world/flood_fill.dart';

// Main screen with flood fill and raster drag-and-drop functionality
class FloodFillRasterDragAndDropScreen extends StatelessWidget {
  const FloodFillRasterDragAndDropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber,
      height: 260,
      width: 260,
      child: const Center(child: FloodFillRaster()),
    );
  }
}

class FloodFillRaster extends StatefulWidget {
  const FloodFillRaster({super.key});

  @override
  State<FloodFillRaster> createState() => _FloodFillRasterState();
}

class _FloodFillRasterState extends State<FloodFillRaster> {
  final List<Map<int, MaterialColor>> data = [
    {
      342: Colors.green,
    },
    {
      4532: Colors.green,
    },
    {
      6436: Colors.green,
    },
    {
      16230: Colors.blue,
    },
  ];

  ui.Image? _image;
  final GlobalKey<ImageWidgetState> _imageKey = GlobalKey<ImageWidgetState>();

  @override
  void initState() {
    super.initState();
    _loadImage().then((image) {
      setState(() {
        _image = image;
      });
    });
  }

  // Load image from assets
  Future<ui.Image> _loadImage() async {
    ByteData byteData = await rootBundle.load('assets/leaf.png');
    final Uint8List data = byteData.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(data);
    final ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  Future<void> _onColorDropped(Offset position, Color color) async {
    if (_image != null) {
      final int x = position.dx.toInt();
      final int y = position.dy.toInt();

      // Perform flood fill with the selected color
      final size = await ImageFloodFill(_image!).calculateFillAreaSize(x, y);
      log(size.toString());
      // Check if color exists in the map and if the size is valid
      bool colorExists = true;
      bool sizeMatches = true;

      // // Loop through the data map to check if the color and size exist
      // for (var entry in data) {
      //   entry.forEach((key, value) {
      //     if (value == color) {
      //       colorExists = true;
      //       // Check if size corresponds to the key
      //       if (key == size) {
      //         sizeMatches = true;
      //       }
      //     }
      //   });
      // }

      // if (colorExists && sizeMatches) {
      log('True: Color and size are correct');
      // Color is correct, perform flood fill and update the image
      final image = await ImageFloodFill(_image!).fill(x, y, color);
      setState(() {
        _image = image;
      });
      // } else {
      //   log('False: Color or size is incorrect');
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      color: Colors.red,
      height: 260,
      width: 260,
      child: FittedBox(
        child: Column(
          children: [
            // Draggable color selectors (for flood fill)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildColorDraggable(Colors.blue),
                const SizedBox(width: 10),
                _buildColorDraggable(Colors.yellow),
                const SizedBox(width: 10),
                _buildColorDraggable(Colors.green),
              ],
            ),
            const SizedBox(height: 20),

            // Image with drag-and-drop functionality
            DragTarget<ui.Color>(
              onAcceptWithDetails: (details) {
                final BuildContext? widgetContext = _imageKey.currentContext;
                if (widgetContext != null) {
                  final RenderBox box =
                      widgetContext.findRenderObject() as RenderBox;
                  var localPosition = box.globalToLocal(details.offset);
                  log('Drag Update at: $localPosition');
                  _onColorDropped(localPosition, details.data);
                }
              },
              builder: (context, candidateData, rejectedData) {
                return ImageWidget(
                  key: _imageKey,
                  image: _image!,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build draggable color box
  Widget _buildColorDraggable(Color color) {
    return Draggable<ui.Color>(
      data: color,
      feedback: _buildColorBox(color, isDragging: true),
      child: _buildColorBox(color),
      childWhenDragging: _buildColorBox(color, opacity: 0.5),
    );
  }

  // Widget to build color box
  Widget _buildColorBox(Color color,
      {bool isDragging = false, double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 10,
        height: 10,
        color: color,
        child: isDragging ? const Icon(Icons.brush, color: Colors.white) : null,
      ),
    );
  }
}

// Image widget with drag functionality
class ImageWidget extends StatefulWidget {
  final ui.Image image;

  const ImageWidget({
    super.key,
    required this.image,
  });

  @override
  ImageWidgetState createState() => ImageWidgetState();
}

class ImageWidgetState extends State<ImageWidget> {
  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: CustomPaint(
        size: Size(260, 260),
        painter: ImagePainter(widget.image),
      ),
    );
  }
}

// Custom painter to display the image
class ImagePainter extends CustomPainter {
  final ui.Image image;

  const ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(
        image, Offset.zero, Paint()..filterQuality = FilterQuality.high);
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) => false;
}
