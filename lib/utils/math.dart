import 'dart:math';

T sum<T extends num>(Iterable<T> numbers) =>
    numbers.isEmpty ? 0 as T : numbers.reduce((v, e) => (v + e) as T);

/// 生成一个随机数
///
/// 范围是 [0, max)
int randomInt(int max) {
  int seed = DateTime.now().millisecondsSinceEpoch;
  return Random(seed).nextInt(max);
}

/// 生成一个随机数
///
/// 范围是 [[min, max]]
int randomBetween(int min, int max) {
  return min + randomInt(max - min + 1);
}

int? tryParseInt(String? value) => value == null ? null : int.tryParse(value);

double? tryParseDouble(String? value) =>
    value == null ? null : double.tryParse(value);

extension DoubleExtension on double? {
  String? get intOrDouble => this == null
      ? null
      : (this!.toInt() - this!) == 0
          ? this!.toInt().toString()
          : toString();
}
