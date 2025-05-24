// DartStringReplacer-ignore
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FpsCounter extends StatefulWidget {
  const FpsCounter({super.key});

  @override
  FpsCounterState createState() => FpsCounterState();
}

class FpsCounterState extends State<FpsCounter> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final Stopwatch _stopwatch;

  int _frames = 0;
  double _fps = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _stopwatch = Stopwatch()..start();
  }

  void _onTick(Duration elapsed) {
    _frames += 1;
    if (_stopwatch.elapsedMilliseconds > 1000) {
      _fps = _frames / _stopwatch.elapsed.inSeconds;
      _frames = 0;
      _stopwatch.reset();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.stop();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('FPS: ${_fps.toStringAsFixed(1)}', style: TextStyle(fontSize: 36, color: Colors.orangeAccent));
  }
}
