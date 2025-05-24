import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:impeller_test/curves.dart';

class Curtain extends StatefulWidget {
  final double sideOpenFactor;
  final double topOpenFactor;
  final double topSizeFactor;
  final int numSideCurtainWaves;
  final int numTopCurtainWaves;
  final LinearGradient curtainGradient;
  final Widget? child;

  Curtain({
    super.key,
    required this.sideOpenFactor,
    required this.topOpenFactor,
    double? topSizeFactor,
    int? numSideCurtainWaves,
    int? numTopCurtainWaves,
    LinearGradient? curtainGradient,
    this.child,
  })  : topSizeFactor = topSizeFactor ?? 0.3,
        numSideCurtainWaves = numSideCurtainWaves ?? 10*2,
        numTopCurtainWaves = numTopCurtainWaves ?? 11*2,
        curtainGradient = curtainGradient ?? _curtainGradient();

  @override
  State<Curtain> createState() => _CurtainState();
}

class _CurtainState extends State<Curtain> {
  final Map<String, Iterable<int>> _flexCache = {};

  Widget _buildCurtain(int numWaves, String flexCacheKey, {double Function(int numWaves, int index)? waveHeightCalculator}) {
    return LayoutBuilder(builder: (context, constraints) {
      double bottomShadowHeight = constraints.maxHeight * 0.03;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _getFlexValues(numWaves, flexCacheKey).mapIndexed(
          (index, flex) {
            double heightFactor = waveHeightCalculator != null ? waveHeightCalculator(numWaves, index) : 1;
            return Flexible(
              flex: flex,
              fit: FlexFit.tight,
              child: CustomPaint(
                size: Size(constraints.biggest.width, constraints.maxHeight * heightFactor),
                painter: _CurtainPainter(
                  gradient: widget.curtainGradient,
                  bottomShadowHeight: bottomShadowHeight,
                ),
              ),
            );
          },
        ).toList(),
      );
    });
  }

  Iterable<int> _getFlexValues(int numWaves, String flexCacheKey) {
    return _flexCache.putIfAbsent(flexCacheKey, () => List.generate(numWaves, (idx) => 100 + Random().nextInt(50)));
  }

  Widget _buildSideCurtain(BuildContext context, bool isLeft) {
    return LayoutBuilder(builder: (context, constraints) {
      int numWaves = _addWavesIfLandscape(widget.numSideCurtainWaves, constraints);
      double avoidNotchOffset = widget.sideOpenFactor == 1 ? 500 : 0;
      double x = widget.sideOpenFactor * (constraints.maxWidth + avoidNotchOffset) * (isLeft ? -1 : 1);
      Widget curtainWidget = _buildCurtain(numWaves, "sideCurtain$isLeft");
      if (widget.sideOpenFactor <= 0.5) {
        curtainWidget = Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                spreadRadius: 0,
                blurRadius: 5,
                offset: const Offset(3, 0),
              ),
            ],
          ),
          child: curtainWidget,
        );
      }
      return Transform.translate(
        offset: Offset(x, 0),
        child: curtainWidget,
      );
    });
  }

  Widget _buildTopCurtain(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double height = constraints.maxHeight * widget.topSizeFactor;
      double y = -widget.topOpenFactor * height;
      int numWaves = _addWavesIfLandscape(widget.numTopCurtainWaves, constraints);
      if (widget.topOpenFactor == 1) {
        return Container();
      }
      return Transform.translate(
        offset: Offset(0, y),
        child: SizedBox(
          height: height,
          width: constraints.maxWidth,
          child: Stack(
            children: [
              _buildCurtain(numWaves, "topCurtain", waveHeightCalculator: _calculateWaveHeightFactor),
            ],
          ),
        ),
      );
    });
  }

  double _calculateWaveHeightFactor(int numWaves, int index) {
    if (index < numWaves / 2) {
      return _calculateWaveHeightFactorLeft(numWaves, index);
    } else {
      return _calculateWaveHeightFactorRight(numWaves, index);
    }
  }

  double _calculateWaveHeightFactorRight(int numWaves, int index) {
    return _calculateWaveHeightFactorLeft(numWaves, numWaves - index - 1);
  }

  double _calculateWaveHeightFactorLeft(int numWaves, int index) {
    if (index == 0) {
      return 1;
    }
    var midHeightFactor = 0.7;
    if (index >= numWaves * midHeightFactor) {
      return 0;
    }
    return cos(index / (numWaves * midHeightFactor) * pi / 2);
  }

  int _addWavesIfLandscape(int numWaves, BoxConstraints constraints) {
    if (constraints.maxWidth <= constraints.maxHeight) {
      return numWaves;
    } else {
      return (numWaves / constraints.maxHeight * constraints.maxWidth).ceil();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        _buildSideCurtain(context, false),
        _buildSideCurtain(context, true),
        _buildTopCurtain(context),
      ],
    );
  }
}

class AnimatedCurtain extends StatefulWidget {
  final bool isOpen;
  final Duration duration;
  final int? numSideCurtainWaves;
  final int? numTopCurtainWaves;
  final double? topSizeFactor;
  final Curve curve;
  final LinearGradient? curtainGradient;
  final Widget? child;

  const AnimatedCurtain({
    super.key,
    required this.isOpen,
    this.duration = const Duration(milliseconds: 5000),
    this.numSideCurtainWaves,
    this.numTopCurtainWaves,
    this.topSizeFactor,
    this.curve = Curves.linear,
    this.curtainGradient,
    this.child,
  });

  @override
  State<AnimatedCurtain> createState() => _AnimatedCurtainState();
}

class _AnimatedCurtainState extends State<AnimatedCurtain> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _sideAnimation;
  late Animation<double> _topAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _sideAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _topAnimation = CurvedAnimation(
      parent: _controller,
      curve: ChainedCurveBuilder().add(curve: ConstantValueCurve(0), share: 1).add(curve: Curves.easeIn, share: 1).build(),
    );

    if (widget.isOpen) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCurtain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            if (widget.child != null) widget.child!,
            if (_controller.value != 1.0) Curtain(
              sideOpenFactor: _sideAnimation.value,
              topOpenFactor: _topAnimation.value,
              topSizeFactor: widget.topSizeFactor,
              numSideCurtainWaves: widget.numSideCurtainWaves,
              numTopCurtainWaves: widget.numTopCurtainWaves,
              curtainGradient: widget.curtainGradient,
            ),
          ],
        );
      },
    );
  }
}

class _CurtainPainter extends CustomPainter {
  final LinearGradient _gradient;
  final double bottomShadowHeight;

  _CurtainPainter({
    required LinearGradient gradient,
    required this.bottomShadowHeight,
  }) : _gradient = gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: Radius.zero,
      topRight: Radius.zero,
      bottomLeft: Radius.elliptical(size.width, size.width / 2),
      bottomRight: Radius.elliptical(size.width, size.width / 2),
    );
    final path = Path()..addRRect(rrect);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, size.height - bottomShadowHeight, size.width, size.height));
    for (int i = 0; i < 2; i++) {
      canvas.drawShadow(path, Colors.black, bottomShadowHeight * 0.5, false);
    }
    canvas.restore();

    final rect = Offset.zero & size;
    final paint = Paint()..shader = _gradient.createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
LinearGradient _curtainGradient({
  Color darkColor = const Color(0xFF4B0000),
  Color lightColor = const Color(0xFF6B2A2A),
  int steps = 16,
  Alignment begin = Alignment.centerLeft,
  Alignment end = Alignment.centerRight,
}) {
  assert(steps >= 2 && steps % 2 == 0, 'Steps must be even and >= 2');

  List<Color> half = List.generate(steps ~/ 2, (i) {
    double t = i / ((steps ~/ 2) - 1);
    return Color.lerp(darkColor, lightColor, t)!;
  });

  List<Color> full = [...half, ...half.reversed];
  final stops = List<double>.generate(full.length, (index) => index / (full.length - 1));

  return LinearGradient(
    colors: full,
    stops: stops,
    begin: begin,
    end: end,
  );
}
