import 'package:flutter/material.dart';

class ChainedCurve extends Curve {
  final List<Curve> curves;
  final List<double> shares;
  final List<double> cumulativeShares;

  ChainedCurve(this.curves, this.shares)
      : assert(curves.length == shares.length),
        cumulativeShares = _calculateCumulativeShares(shares);

  static List<double> _calculateCumulativeShares(List<double> shares) {
    double total = shares.reduce((a, b) => a + b);
    double sum = 0;
    return shares.map((s) {
      sum += s;
      return sum / total;
    }).toList();
  }

  @override
  double transformInternal(double t) {
    for (int i = 0; i < curves.length; i++) {
      double start = i == 0 ? 0 : cumulativeShares[i - 1];
      double end = cumulativeShares[i];
      if (t >= start && t <= end) {
        double localT = (t - start) / (end - start);
        return curves[i].transform(localT);
      }
    }
    return 0; // This should not be reached
  }
}

class ChainedCurveBuilder {
  final List<Curve> curves = [];
  final List<double> shares = [];

  ChainedCurveBuilder add({required Curve curve, required double share}) {
    curves.add(curve);
    shares.add(share);
    return this;
  }

  ChainedCurve build() {
    return ChainedCurve(curves, shares);
  }
}


class RevertedCurve extends Curve {
  final Curve curve;

  const RevertedCurve(this.curve);

  @override
  double transformInternal(double t) {
    return curve.transformInternal(1-t);
  }
}

class ConstantValueCurve extends Curve {
  final double value;

  const ConstantValueCurve(this.value);

  @override
  double transformInternal(double t) {
    return value;
  }
}
