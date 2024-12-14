class MovingAverageFilter {
  final int windowSize;
  final List<double> _values = [];
  final List<double> weights;

  MovingAverageFilter(this.windowSize)
      : weights = List.generate(windowSize, (index) => 1.0 - (index * 0.1)) {
    // 가중치가 음수가 되지 않도록 조정
    for (int i = 0; i < weights.length; i++) {
      if (weights[i] < 0) weights[i] = 0.0;
    }
  }

  double filter(double newValue) {
    _values.add(newValue);
    if (_values.length > windowSize) {
      _values.removeAt(0); // 오래된 값 제거
    }

    int length = _values.length;
    List<double> currentWeights = weights.sublist(weights.length - length);

    double weightedSum = 0.0;
    double weightTotal = 0.0;
    for (int i = 0; i < length; i++) {
      weightedSum += _values[i] * currentWeights[i];
      weightTotal += currentWeights[i];
    }

    return weightTotal > 0 ? weightedSum / weightTotal : 0.0;
  }
}
