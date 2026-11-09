import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  LineChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minV = data.reduce((a, b) => a < b ? a : b) - 4;
    final maxV = data.reduce((a, b) => a > b ? a : b) + 4;
    final range = maxV - minV;
    const pad = 8.0;

    final grid = Paint()
      ..color = Colors.white.o(0.08)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final pts = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(
          pad + (size.width - 2 * pad) * i / (data.length - 1),
          size.height * (1 - (data[i] - minV) / range),
        ),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final p = pts[i - 1];
      final c = pts[i];
      final mx = (p.dx + c.dx) / 2;
      line.cubicTo(mx, p.dy, mx, c.dy, c.dx, c.dy);
    }

    final fill = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.o(0.38), color.o(0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(pts.last, 8, Paint()..color = Colors.white);
    canvas.drawCircle(pts.last, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(LineChartPainter old) =>
      old.data != data || old.color != color;
}
