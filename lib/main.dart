import 'package:PPG/services/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/pages.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediRate',
      theme: ThemeData(),
      home: MultiProvider(providers: [
        Provider(create: (_) => GameViewState()),
      ], child: GameView()),
    );
  }
}
