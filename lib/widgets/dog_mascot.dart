import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/dog_mood.dart';

/// The Remindya dog. Its face and body language follow [mood].
class DogMascot extends StatefulWidget {
  const DogMascot({super.key, required this.mood, this.size = 180});

  final DogMood mood;
  final double size;

  @override
  State<DogMascot> createState() => _DogMascotState();
}

class _DogMascotState extends State<DogMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  Duration get _period => switch (widget.mood) {
    DogMood.feral => const Duration(milliseconds: 180),
    DogMood.ecstatic => const Duration(milliseconds: 450),
    DogMood.happy => const Duration(milliseconds: 900),
    DogMood.bored => const Duration(milliseconds: 2400),
    DogMood.sad || DogMood.devastated => const Duration(milliseconds: 2800),
  };

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _period)
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(DogMascot old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _c
        ..duration = _period
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Remindya dog, feeling ${widget.mood.name}',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_c.value);
          final (dx, dy, angle) = switch (widget.mood) {
            DogMood.feral => ((t - 0.5) * 8, 0.0, (t - 0.5) * 0.08),
            DogMood.ecstatic => (0.0, -t * 14, (t - 0.5) * 0.25),
            DogMood.happy => (0.0, -t * 6, (t - 0.5) * 0.12),
            DogMood.bored => (0.0, t * 2, 0.0),
            DogMood.sad || DogMood.devastated => (0.0, t * 4, 0.0),
          };
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: angle,
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: DogPainter(widget.mood, _c.value),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DogPainter extends CustomPainter {
  DogPainter(this.mood, this.phase);

  final DogMood mood;
  final double phase;

  static const _fur = Color(0xFFE8B77D);
  static const _muzzle = Color(0xFFF8E3C4);
  static const _ear = Color(0xFF8B5A2B);
  static const _ink = Color(0xFF2B1D14);
  static const _tongue = Color(0xFFF2788F);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.022
      ..color = _ink;

    // Ears: perky when happy, flat when sad, pinned back when feral.
    final earAngle = switch (mood) {
      DogMood.ecstatic => -0.55 + phase * 0.25,
      DogMood.happy => -0.35,
      DogMood.bored => 0.15,
      DogMood.sad => 0.45,
      DogMood.devastated => 0.7,
      DogMood.feral => -0.6,
    };
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(s * (0.5 + side * 0.24), s * 0.32);
      canvas.rotate(side * earAngle);
      fill.color = _ear;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(side * s * 0.06, s * 0.13),
          width: s * 0.18,
          height: s * 0.32,
        ),
        fill,
      );
      canvas.restore();
    }

    // Head and muzzle.
    fill.color = _fur;
    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.55), width: s * 0.62, height: s * 0.56),
      fill,
    );
    fill.color = _muzzle;
    canvas.drawOval(
      Rect.fromCenter(center: p(0.5, 0.7), width: s * 0.36, height: s * 0.25),
      fill,
    );

    // Cheeks: rosy when happy, angry red when feral.
    if (mood == DogMood.ecstatic ||
        mood == DogMood.happy ||
        mood == DogMood.feral) {
      fill.color = (mood == DogMood.feral ? Colors.red : Colors.pink)
          .withValues(alpha: mood == DogMood.feral ? 0.45 : 0.25);
      canvas.drawCircle(p(0.3, 0.64), s * 0.05, fill);
      canvas.drawCircle(p(0.7, 0.64), s * 0.05, fill);
    }

    _eyes(canvas, s, p, fill, stroke);
    _brows(canvas, p, stroke);

    // Nose.
    fill.color = _ink;
    final nose = Path()
      ..moveTo(s * 0.45, s * 0.615)
      ..quadraticBezierTo(s * 0.5, s * 0.6, s * 0.55, s * 0.615)
      ..quadraticBezierTo(s * 0.5, s * 0.68, s * 0.45, s * 0.615);
    canvas.drawPath(nose, fill);

    _mouth(canvas, s, p, fill, stroke);

    if (mood == DogMood.devastated || mood == DogMood.sad) {
      // Tears, falling with the animation.
      fill.color = const Color(0xFF6EC1F5);
      final drop = 0.6 + phase * (mood == DogMood.devastated ? 0.12 : 0.06);
      for (final x in mood == DogMood.devastated ? [0.37, 0.63] : [0.37]) {
        final path = Path()
          ..moveTo(s * x, s * (drop - 0.035))
          ..quadraticBezierTo(
            s * (x + 0.025),
            s * drop,
            s * x,
            s * (drop + 0.02),
          )
          ..quadraticBezierTo(
            s * (x - 0.025),
            s * drop,
            s * x,
            s * (drop - 0.035),
          );
        canvas.drawPath(path, fill);
      }
    }

    if (mood == DogMood.feral) {
      // Anger mark.
      final mark = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018
        ..strokeCap = StrokeCap.round
        ..color = Colors.red;
      final c = p(0.78, 0.3);
      for (var i = 0; i < 4; i++) {
        final a = i * pi / 2 + pi / 4;
        final o = Offset(cos(a), sin(a)) * s * 0.035;
        canvas.drawArc(
          Rect.fromCircle(center: c + o * 1.6, radius: s * 0.03),
          a + pi * 0.75,
          pi / 2,
          false,
          mark,
        );
      }
    }
  }

  void _eyes(
    Canvas canvas,
    double s,
    Offset Function(double, double) p,
    Paint fill,
    Paint stroke,
  ) {
    const left = 0.38, right = 0.62, y = 0.5;
    switch (mood) {
      case DogMood.ecstatic:
        // Happy closed eyes: ^ ^
        for (final x in [left, right]) {
          canvas.drawArc(
            Rect.fromCenter(
              center: p(x, y + 0.02),
              width: s * 0.1,
              height: s * 0.08,
            ),
            pi,
            pi,
            false,
            stroke,
          );
        }
      case DogMood.bored:
        for (final x in [left, right]) {
          fill.color = _ink;
          canvas.drawCircle(p(x, y), s * 0.04, fill);
          // Heavy eyelids.
          fill.color = _fur;
          canvas.drawRect(
            Rect.fromLTWH(s * (x - 0.05), s * (y - 0.06), s * 0.1, s * 0.055),
            fill,
          );
          canvas.drawLine(
            p(x - 0.045, y - 0.005),
            p(x + 0.045, y - 0.005),
            stroke,
          );
        }
      case DogMood.feral:
        for (final x in [left, right]) {
          fill.color = Colors.white;
          canvas.drawCircle(p(x, y), s * 0.05, fill);
          fill.color = _ink;
          canvas.drawCircle(p(x, y), s * 0.02, fill);
        }
      case DogMood.happy || DogMood.sad || DogMood.devastated:
        // Puppy eyes get bigger and shinier the sadder it is.
        final r = switch (mood) {
          DogMood.happy => 0.045,
          DogMood.sad => 0.06,
          _ => 0.068,
        };
        for (final x in [left, right]) {
          fill.color = _ink;
          canvas.drawCircle(p(x, y), s * r, fill);
          fill.color = Colors.white;
          canvas.drawCircle(p(x + r * 0.35, y - r * 0.35), s * r * 0.38, fill);
          if (mood != DogMood.happy) {
            canvas.drawCircle(p(x - r * 0.3, y + r * 0.35), s * r * 0.18, fill);
          }
        }
    }
  }

  void _brows(Canvas canvas, Offset Function(double, double) p, Paint stroke) {
    switch (mood) {
      case DogMood.sad || DogMood.devastated:
        // Inner ends raised: worried.
        canvas.drawLine(p(0.32, 0.41), p(0.42, 0.38), stroke);
        canvas.drawLine(p(0.68, 0.41), p(0.58, 0.38), stroke);
      case DogMood.feral:
        // Inner ends lowered: furious.
        canvas.drawLine(p(0.31, 0.38), p(0.44, 0.43), stroke);
        canvas.drawLine(p(0.69, 0.38), p(0.56, 0.43), stroke);
      default:
        break;
    }
  }

  void _mouth(
    Canvas canvas,
    double s,
    Offset Function(double, double) p,
    Paint fill,
    Paint stroke,
  ) {
    switch (mood) {
      case DogMood.ecstatic || DogMood.happy:
        final open = mood == DogMood.ecstatic ? 0.1 : 0.07;
        fill.color = _tongue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: p(0.5, 0.72 + open / 2),
              width: s * 0.09,
              height: s * open,
            ),
            Radius.circular(s * 0.045),
          ),
          fill,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: p(0.45, 0.68),
            width: s * 0.1,
            height: s * 0.08,
          ),
          0,
          pi,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: p(0.55, 0.68),
            width: s * 0.1,
            height: s * 0.08,
          ),
          0,
          pi,
          false,
          stroke,
        );
      case DogMood.bored:
        canvas.drawLine(p(0.45, 0.73), p(0.55, 0.73), stroke);
      case DogMood.sad || DogMood.devastated:
        canvas.drawArc(
          Rect.fromCenter(
            center: p(0.5, 0.76),
            width: s * 0.14,
            height: s * 0.07,
          ),
          pi,
          pi,
          false,
          stroke,
        );
      case DogMood.feral:
        // Snarl with teeth.
        final mouth = Rect.fromCenter(
          center: p(0.5, 0.75),
          width: s * 0.2,
          height: s * 0.08,
        );
        fill.color = _ink;
        canvas.drawRRect(
          RRect.fromRectAndRadius(mouth, Radius.circular(s * 0.03)),
          fill,
        );
        fill.color = Colors.white;
        final teeth = Path()..moveTo(mouth.left + s * 0.01, mouth.top);
        const n = 5;
        final w = (mouth.width - s * 0.02) / n;
        for (var i = 0; i < n; i++) {
          final x0 = mouth.left + s * 0.01 + i * w;
          teeth
            ..lineTo(x0 + w / 2, mouth.top + s * 0.035)
            ..lineTo(x0 + w, mouth.top);
        }
        teeth.close();
        canvas.drawPath(teeth, fill);
    }
  }

  @override
  bool shouldRepaint(DogPainter old) => old.mood != mood || old.phase != phase;
}
