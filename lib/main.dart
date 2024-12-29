import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:test_world/selctor.dart';

void main() => runApp(
      MaterialApp(
        theme: ThemeData(
          primaryColor: Colors.blue,
        ),
        home: MyApp(),
      ),
    );

class MyApp extends StatelessWidget {
  List<String> selected = [];
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: TeethSelector(
          initiallySelected: selected,
          onChange: (s) {
            selected.addAll(s);

            log(selected.toString());
          },
          multiSelect: false,
          colorized: {
            for (var e in selected)
              e: e == "24" ? Colors.blue : Colors.green.withOpacity(0.5),
          },
          StrokedColorized: {"24": Colors.grey.withOpacity(0.5)},
          notation: (isoString) => "Tooth ISO: $isoString",
          selectedColor: Colors.red,
          showPrimary: false,
        ),
      ),
    );
  }
}
