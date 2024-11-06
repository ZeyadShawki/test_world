import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:test_world/flood_fill.dart';

class FloodFillRasterScreen extends StatelessWidget {
  const FloodFillRasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flood Fill Raster'),
      ),
      body: const Center(child: FloodFillRaster()),
    );
  }
}

class FloodFillRaster extends StatefulWidget {
  const FloodFillRaster({super.key});

  @override
  State<FloodFillRaster> createState() => _FloodFillRasterState();
}

class _FloodFillRasterState extends State<FloodFillRaster> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage().then((image) {
      setState(() {
        _image = image;
      });
    });
  }

  Future<ui.Image> _loadImage() async {
    const url =
        'https://sun9-77.userapi.com/impg/BiGYCxYxSuZgeILSzA0dtPcNC7935fdhpW36rg/e3jk6CqTwkw.jpg?size=1372x1372&quality=95&sign=2afb3d42765f8777879e06c314345303&type=album';

    final response = await http.get(Uri.parse(url));

    // Load the image as byte data
    ByteData byteData = await rootBundle.load('assets/world2.png');

    final Uint8List data = byteData.buffer.asUint8List();

    final ui.Codec codec =
        await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  void _onTapDown(TapDownDetails details) async {
    final Offset localPosition = details.localPosition;
    log(details.localPosition.toString());
    final int x = localPosition.dx.toInt();
    final int y = localPosition.dy.toInt();

    const ui.Color newColor = Colors.red;
    final image = await ImageFloodFill(_image!).fill(x, y, newColor);
    log(image.toString());
    setState(() {
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return FittedBox(
      child: GestureDetector(
        onTapDown: _onTapDown,
        child: CustomPaint(
          size: Size(_image!.width.toDouble(), _image!.height.toDouble()),
          painter: ImagePainter(_image!),
        ),
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;

  const ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(
        image, Offset.zero, Paint()..filterQuality = FilterQuality.high);
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) => true;
}
