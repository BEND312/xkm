import 'dart:math';

extension ListExtension<T> on List<T> {
  T? get randomElement => length >= 1 ? this[Random().nextInt(length)] : null;

  T? safeGet(int index) => index >= length ? null : this[index];
}
