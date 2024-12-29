import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:svg_path_parser/svg_path_parser.dart';
import 'package:xml/xml.dart';

typedef Data = ({Size size, Map<String, Tooth> teeth});

class TeethSelector extends StatefulWidget {
  final bool multiSelect;
  final Color selectedColor;
  final Color unselectedColor;
  final Color tooltipColor;
  final List<String> initiallySelected;
  final Map<String, Color> colorized;
  final Map<String, Color> StrokedColorized;
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

  const TeethSelector({
    super.key,
    this.multiSelect = false,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
    this.tooltipColor = Colors.black,
    this.initiallySelected = const [],
    this.colorized = const {},
    this.StrokedColorized = const {},
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
  State<TeethSelector> createState() => _TeethSelectorState();
}

class _TeethSelectorState extends State<TeethSelector> {
  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return FutureBuilder(
        future: loadTeeth(initiallySelected: widget.initiallySelected),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              color: Colors.amber,
            );
          }

          if (snapshot.data!.size == Size.zero) return const UnconstrainedBox();

          return FittedBox(
            child: SizedBox.fromSize(
              size: snapshot.data!.size,
              child: Stack(
                children: [
                  Positioned(
                    left: 10,
                    top: snapshot.data!.size.height * 0.5 - 11,
                    child: Text(widget.rightString, style: widget.textStyle),
                  ),
                  Positioned(
                    right: 10,
                    top: snapshot.data!.size.height * 0.5 - 11,
                    child: Text(widget.leftString, style: widget.textStyle),
                  ),
                  // teeth
                  for (final MapEntry(key: key, value: tooth)
                      in snapshot.data!.teeth.entries)
                    if ((widget.showPrimary || int.parse(key) < 50) &&
                        (widget.showPermanent || int.parse(key) > 50))
                      Positioned.fromRect(
                        rect: tooth.rect,
                        child: GestureDetector(
                          key: Key(
                              "tooth-iso-$key-${tooth.selected ? "selected" : "not-selected"}"),
                          onTap: () {
                            setState(() {
                              if (widget.multiSelect == false) {
                                for (final tooth
                                    in snapshot.data!.teeth.entries) {
                                  if (tooth.key != key) {
                                    tooth.value.selected = false;
                                  }
                                }
                              }
                              tooth.selected = !tooth.selected;
                              widget.onChange(snapshot.data!.teeth.entries
                                  .where((tooth) => tooth.value.selected)
                                  .map((tooth) => tooth.key)
                                  .toList());
                            });
                          },
                          child: Tooltip(
                            triggerMode: TooltipTriggerMode.manual,
                            message: widget.notation == null
                                ? key
                                : widget.notation!(key),
                            textAlign: TextAlign.center,
                            textStyle: widget.tooltipTextStyle,
                            preferBelow: false,
                            decoration: BoxDecoration(
                                color: widget.tooltipColor,
                                boxShadow: kElevationToShadow[6]),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              clipBehavior: Clip.antiAlias,
                              decoration: ShapeDecoration(
                                color: tooth.selected
                                    ? widget.selectedColor
                                    : widget.colorized[key] ??
                                        widget.unselectedColor,
                                shape: ToothBorder(
                                  tooth.path,
                                  strokeColor: widget.StrokedColorized[key] ??
                                      widget.defaultStrokeColor,
                                  strokeWidth: widget.strokeWidth[key] ??
                                      widget.defaultStrokeWidth,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          );
        });
  }
}

Future<Data> loadTeeth({required List<String> initiallySelected}) async {
  final String rawSvg = await rootBundle.loadString('assets/teeth.svg');
  final doc = XmlDocument.parse(rawSvg);
  final viewBox = doc.rootElement.getAttribute('viewBox')!.split(' ');
  final w = double.parse(viewBox[2]);
  final h = double.parse(viewBox[3]);

  final teeth = doc.rootElement.findAllElements('path');

  final d = (
    size: Size(w, h),
    teeth: <String, Tooth>{
      for (final tooth in teeth)
        tooth.getAttribute('id')!:
            Tooth(parseSvgPath(tooth.getAttribute('d')!)),
    },
  );

  for (var element in initiallySelected) {
    if (d.teeth[element] != null) {
      d.teeth[element]!.selected = true;
    }
  }
  return d;
}

class Tooth {
  Tooth(Path originalPath) {
    rect = originalPath.getBounds();
    path = originalPath.shift(-rect.topLeft);
  }

  late final Path path;
  late final Rect rect;
  bool selected = false;
}

class ToothBorder extends ShapeBorder {
  final Path path;
  final double strokeWidth;
  final Color strokeColor;

  const ToothBorder(
    this.path, {
    required this.strokeWidth,
    required this.strokeColor,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return rect.topLeft == Offset.zero ? path : path.shift(rect.topLeft);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = strokeColor;
    canvas.drawPath(getOuterPath(rect), paint);
  }

  @override
  ShapeBorder scale(double t) => this;
}