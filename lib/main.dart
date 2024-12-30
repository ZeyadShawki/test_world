import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:test_world/selctor.dart';
import 'dart:ui' as ui;

void main() => runApp(
      MaterialApp(
        theme: ThemeData(
          primaryColor: Colors.blue,
        ),
        home: MyApp(),
      ),
    );

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> selected = [];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
          
          //  SvgPicture.asset('assets/leaf_modified22.svg')

           Row(
             children: [

   Padding(
     padding: const EdgeInsets.only(left: 100.0),
     child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildColorDraggable(colorFromHex('#F58220')),
                  const SizedBox(width: 10),
                  _buildColorDraggable(Colors.yellow),
                  const SizedBox(width: 10),
                  _buildColorDraggable(Colors.green),
                ],
              ),
   ),

               FittedBox(
                 child: Container(
                  height: 400,
                  width: 200,
                   child: ColorTheSvgWidget(
                    onRightAnswer: (){

                    },
                    onWrongAnswer:(){

                    },
                    defaultStrokeColor: Colors.black,
                    unselectedColor:Colors.white ,
                    initiallySelected: selected,
                    onChange: (s) {
                      selected.addAll(s);
            setState(() {
              
            });
                
                    },
                    multiSelect: false,
                    colorized: {
                          for (var e in selected)
                        e:e.contains('blade') ? Colors.blue : Colors.green.withOpacity(0.5),
                    },
                    // StrokedColorized: {"24": Colors.grey.withOpacity(0.5)},
                    notation: (isoString) => "Tooth ISO: $isoString",
                    selectedColor: Colors.amber,
                    showPrimary: false,
                             ),
                 ),
               ),
             ],
           ),
          ),
    );
  }

  // Widget to build color box
  Widget _buildColorBox(Color color,
      {bool isDragging = false, double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 50,
        height: 50,
        color: color,
        child: isDragging ? const Icon(Icons.brush, color: Colors.white) : null,
      ),
    );
  }

  // Widget to build draggable color box
  Widget _buildColorDraggable(Color color) {
    return Draggable<ui.Color>(
      dragAnchorStrategy: (draggable, context, position) => Offset.zero,
      data: color,
      onDragEnd: (details) {
        log('///');
        log(details.offset.toString());
      },
      feedback: _buildColorBox(color, isDragging: true),
      child: _buildColorBox(color),
      childWhenDragging: _buildColorBox(color, opacity: 0.5),
    );
  }
}
Color colorFromHex(String hexColor) {
  final hexCode = hexColor.replaceAll("#", "");
  return Color(int.parse("FF$hexCode", radix: 16));
}