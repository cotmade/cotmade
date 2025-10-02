// tflite_stub.dart
// Stub implementation of TFLite for Flutter Web

class InterpreterOptions {
  int threads = 1;
}

class Interpreter {
  Interpreter._();

  static Future<Interpreter> fromAsset(String asset, {InterpreterOptions? options}) async {
    // Stub: just return an empty interpreter
    return Interpreter._();
  }

  dynamic getOutputTensor(int index) {
    return StubTensor();
  }

  void run(dynamic input, dynamic output) {
    // Stub: do nothing
  }
}

class StubTensor {
  List<int> shape = [1, 1000]; // example output shape

  int get length => shape.reduce((a, b) => a * b);
}

extension ListReshape on List {
  dynamic reshape(List<int> newShape) {
    return this; // Stub: return the same list
  }
}
