import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:PPG/services/services.dart';

class GameView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameViewState>(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.play_arrow),
        onPressed: state.active ? () {} : () {},
      ),
    );
  }
}

class GameViewState with ChangeNotifier {
  bool active = false;
}
