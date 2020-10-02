import 'package:flutter/material.dart';
import 'pages/pages.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'MediRate', theme: ThemeData(), home: GameView());
  }
}
