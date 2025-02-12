class WeightedAverageFilter {
  final List<double?> _queue;
  final List<double> _weights;
  int _front = 0;
  int _rear = 0;
  int _size = 0;

  WeightedAverageFilter(int capacity, List<double> weights)
      : _queue = List<double?>.filled(capacity, null),
        _weights = List<double>.from(weights);

  bool get isEmpty => _size == 0;

  bool get isFull => _size == _queue.length;

  void enqueue(double element) {
    if (isFull) {
      dequeue();
    }
    _queue[_rear] = element;
    _rear = (_rear + 1) % _queue.length;
    _size++;
  }

  double? dequeue() {
    if (isEmpty) throw Exception("Queue is empty");
    double? element = _queue[_front];
    _queue[_front] = null;
    _front = (_front + 1) % _queue.length;
    _size--;
    return element;
  }

  double? peek() {
    if (isEmpty) return null;
    return _queue[_front];
  }

  void clear() {
    while (!isEmpty) {
      dequeue();
    }
  }

  double calculateWeightedAverage() {
    if (isEmpty) return 0.0;
    double weightedSum = 0.0, weightSum = 0.0;
    for (int i = 0; i < _queue.length; i++) {
      double? element = _queue[(_front + i) % _queue.length];
      if (element != null) {
        weightedSum += element * _weights[i];
        weightSum += _weights[i];
      }
    }
    return weightSum == 0.0 ? 0.0 : weightedSum / weightSum;
  }
}