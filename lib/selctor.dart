import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:svg_path_parser/svg_path_parser.dart';
import 'package:test_world/main.dart';
import 'package:xml/xml.dart';
import 'dart:ui' as ui;
typedef PictureData = ({Size size, Map<String, PicturePathModel> teeth});

class ColorTheSvgWidget extends StatefulWidget {
  final bool multiSelect;
  final Color selectedColor;
  final Color unselectedColor;
  final Color tooltipColor;
  final List<String> initiallySelected;
  final Map<String, Color> colorized;
  final Map<String, Color> strokedColorized;
  final Color defaultStrokeColor;
  final Map<String, double> strokeWidth;
  final double defaultStrokeWidth;
  final String leftString;
  final String rightString;
  final bool showPrimary;
  final bool showPermanent;
  final void Function(List<String> selected) onChange;

  final String Function(String isoString)? notation;
  final TextStyle? textStyle;
  final TextStyle? tooltipTextStyle;

final void Function() onWrongAnswer;

final void Function() onRightAnswer;


  const ColorTheSvgWidget({
    super.key,

 required   this.onWrongAnswer ,
   required this.onRightAnswer ,


    this.multiSelect = false,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
    this.tooltipColor = Colors.black,
    this.initiallySelected = const [],
    this.colorized = const {},
    this.strokedColorized = const {},
    this.defaultStrokeColor = Colors.transparent,
    this.strokeWidth = const {},
    this.defaultStrokeWidth = 1,
    this.notation,
    this.showPrimary = false,
    this.showPermanent = true,
    this.leftString = "Left",
    this.rightString = "Right",
    this.textStyle = null,
    this.tooltipTextStyle = null,
    required this.onChange,
  });

  @override
  State<ColorTheSvgWidget> createState() => _ColorTheSvgWidgetState();
}

class _ColorTheSvgWidgetState extends State<ColorTheSvgWidget> {
  Offset? tapPosition; // Holds the last tap position
  final GlobalKey _painterKey = GlobalKey();
List<Offset> dropPositions = [];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PictureData>(
      future: loadPictures(initiallySelected: widget.initiallySelected),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: Colors.amber);
        }

        final PictureData = snapshot.data!;

        return FittedBox(
          child: DragTarget<ui.Color>(
            onAcceptWithDetails: (details) {
  final RenderBox renderBox = _painterKey.currentContext!.findRenderObject() as RenderBox;
  final localPosition = renderBox.globalToLocal(details.offset);

  setState(() {
    dropPositions.add(localPosition); // Add new drop position
    tapPosition = localPosition; // Update tap position to local
  });

  log('/// drag target localPosition: $tapPosition');
  _detectAndColorPicturePathModel(details.data, tapPosition!, snapshot.data!.teeth);

            },
            builder: (context, candidateData, rejectedData) =>
            SizedBox.fromSize(
                              key: _painterKey,

                size: PictureData.size,
                child: Stack(
                  children: [
                    for (final entry in PictureData.teeth.entries)
                      Positioned.fromRect(
                        rect: entry.value.rect,
                        child: CustomPaint(
                          painter: _PicturePathModelPainter(
                            picturePathModel: entry.value,
                            isSelected: entry.value.selected,
                            selectedColor: widget.colorized[entry.key] ?? widget.selectedColor,
                            unselectedColor: widget.unselectedColor,
                            strokeColor: widget.strokedColorized[entry.key] ?? widget.defaultStrokeColor,
                            strokeWidth: widget.strokeWidth[entry.key] ?? widget.defaultStrokeWidth,
                          ),
                        ),
                      ),


                        CustomPaint(
        painter: _TapPainter(positions: dropPositions),
      ),
                  ],
                ),
              
            ),
          ),
        );
      },
    );
  }

  
void _detectAndColorPicturePathModel(
  ui.Color color,
    Offset off, Map<String, PicturePathModel> pictures) async {
  final tapOffset = off; // Position of the tap

  bool hasSelectionChanged = false;
  String? tappedPicturePathModelId;

  for (final entry in pictures.entries) {
    final picturePathModel = entry.value;

    // Adjust the tap offset for the PicturePathModel's bounding box
    final adjustedTapOffset = tapOffset - picturePathModel.rect.topLeft;

    if (picturePathModel.path.contains(adjustedTapOffset)) {
      tappedPicturePathModelId = picturePathModel.id; // Store the tapped PicturePathModel's ID

      if (picturePathModel.selected) {
        // If already selected, log and exit
        log("Picture already selected");
        return;
      }

log(picturePathModel.color.toString());
      if (picturePathModel.color == color) {
        // If colors match
       widget.onRightAnswer();
        picturePathModel.selected = true;
        hasSelectionChanged = true;
      } else {
        // If colors don't match
       widget.onWrongAnswer();
        return;
      }
    }
  }

  if (hasSelectionChanged) {
    // Notify about changes in selected teeth
    widget.onChange(
      pictures.entries
          .where((entry) => entry.value.selected)
          .map((e) => e.key)
          .toList(),
    );

    // Trigger a UI update
    setState(() {});
  }
}

}

class _TapPainter extends CustomPainter {
  final List<Offset> positions;

  _TapPainter({required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Draw circles at each drop position
    for (var position in positions) {
      canvas.drawCircle(position, 20.0, paint); // You can adjust the radius here
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PicturePathModelPainter extends CustomPainter {
  final PicturePathModel picturePathModel;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color strokeColor;
  final double strokeWidth;

  _PicturePathModelPainter({
    required this.picturePathModel,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = isSelected ? selectedColor : unselectedColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(picturePathModel.path, fillPaint);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawPath(picturePathModel.path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Future<PictureData> loadPictures(
    {required List<String> initiallySelected}) async {
  final rawSvg = await rootBundle.loadString('assets/leaf_modified22.svg');
  final doc = XmlDocument.parse(rawSvg);
  final viewBox = doc.rootElement.getAttribute('viewBox')!.split(' ');
  final width = double.parse(viewBox[2]);
  final height = double.parse(viewBox[3]);

  final teethPaths = doc.rootElement.findAllElements('path');

  final teeth = {
    for (final pathElement in teethPaths)
      pathElement.getAttribute('class')!: PicturePathModel(
          parseSvgPath(pathElement.getAttribute('d')!),
          pathElement.getAttribute('id') ?? '',
          
        colorFromHex(  pathElement.getAttribute('myColor') ??'#F58220')
          ),
  };



  for (var id in initiallySelected) {
    if (teeth.containsKey(id)) {
      teeth[id]!.selected = true;
    }
  }

  return (size: Size(width, height), teeth: teeth);
}

class PicturePathModel {
  late String id;
  PicturePathModel(Path originalPath, String name,Color picColor) {
    rect = originalPath.getBounds();
    path = originalPath.shift(-rect.topLeft);
    id = name;
    color=picColor;
  }
    late final Color color;


  late final Path path;
  late final Rect rect;
  bool selected = false;
}
