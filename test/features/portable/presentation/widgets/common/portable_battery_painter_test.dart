import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln/features/portable/presentation/widgets/common/portable_battery_painter.dart';

void main() {
  const outline = Color(0xFF9CA3AF);
  const fill = Color(0xFF3D8BFF);

  void Function(Canvas) paintAt(double level, {bool charging = false}) =>
      (canvas) => PortableBatteryPainter(
        level: level,
        charging: charging,
        outline: outline,
        fill: fill,
      ).paint(canvas, const Size(24, 12));

  /// A drawRRect of the inner fill, which starts at x 3 on the 24×12 grid.
  bool Function(Symbol, List<dynamic>) fillOf(double width) => (method, args) {
    if (method != #drawRRect) return false;
    final r = args[0] as RRect;
    return (args[1] as Paint).color.toARGB32() == fill.toARGB32() &&
        (r.left - 3).abs() < 1e-9 &&
        (r.width - width).abs() < 1e-9;
  };

  test('outline, nub, then the fill up to the level', () {
    expect(
      paintAt(0.5),
      paints
        ..rrect(color: outline)
        ..rrect(color: outline)
        ..something(fillOf(7.5)),
    );
  });

  test('no fill at 0%', () {
    expect(
      paintAt(0),
      paints
        ..rrect(color: outline)
        ..rrect(color: outline)
        ..everything(
          (method, args) =>
              args.isEmpty ||
              args.last is! Paint ||
              (args.last as Paint).color.toARGB32() != fill.toARGB32(),
        ),
    );
  });

  test('a sliver stays visible just above 0%, and above 100% is full', () {
    expect(paintAt(0.01), paints..something(fillOf(1.6)));
    expect(paintAt(1.5), paints..something(fillOf(15)));
  });

  test('cuts the bolt into the fill and draws it while charging', () {
    expect(
      paintAt(0.5, charging: true),
      paints
        ..rrect(color: outline)
        ..rrect(color: outline)
        ..rrect(color: fill)
        ..path(style: PaintingStyle.stroke)
        ..path(color: outline),
    );
    expect(paintAt(0.5), isNot(paints..path()));
  });
}
