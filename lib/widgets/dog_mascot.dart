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

  static const _fur = Color(0xFFF6CB8B);
  static const _furShade = Color(0xFFE2AC66);
  static const _ear = Color(0xFFC98A4B);
  static const _patch = Color(0xFFE0A15E);
  static const _muzzle = Color(0xFFFFF4E2);
  static const _ink = Color(0xFF3B2A20);
  static const _blush = Color(0xFFFF8FA3);
  static const _tongue = Color(0xFFFF7A93);
  static const _tear = Color(0xFF7CC8FF);

  late double _s;

  Offset _p(double x, double y) => Offset(x * _s, y * _s);

  Rect _oval(double cx, double cy, double w, double h) =>
      Rect.fromCenter(center: _p(cx, cy), width: w * _s, height: h * _s);

  Paint _fill(Color c) => Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true
    ..color = c;

  Paint _line(Color c, double w) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true
    ..strokeWidth = w * _s
    ..color = c;

  @override
  void paint(Canvas canvas, Size size) {
    _s = size.width;
    _ears(canvas);
    _head(canvas);
    _eyes(canvas);
    _brows(canvas);
    _muzzleAndMouth(canvas);
    _extras(canvas);
  }

  void _ears(Canvas canvas) {
    // Floppy ears hang beside the head. Positive angle swings them out,
    // negative tucks them down and back.
    final angle = switch (mood) {
      DogMood.ecstatic => 0.55 + phase * 0.2,
      DogMood.happy => 0.3,
      DogMood.bored => 0.05,
      DogMood.sad => -0.15,
      DogMood.devastated => -0.25,
      DogMood.feral => 0.85,
    };
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(_s * (0.5 + side * 0.27), _s * 0.34);
      canvas.rotate(-side * angle);
      final ear = Path()
        ..moveTo(side * -0.04 * _s, 0)
        ..cubicTo(
          side * 0.12 * _s,
          -0.04 * _s,
          side * 0.17 * _s,
          0.2 * _s,
          side * 0.1 * _s,
          0.3 * _s,
        )
        ..cubicTo(
          side * 0.05 * _s,
          0.36 * _s,
          side * -0.05 * _s,
          0.3 * _s,
          side * -0.05 * _s,
          0.18 * _s,
        )
        ..close();
      canvas.drawPath(ear, _fill(_ear));
      canvas.restore();
    }
  }

  void _head(Canvas canvas) {
    final head = _oval(0.5, 0.55, 0.7, 0.6);
    canvas.drawOval(head, _fill(_fur));
    // Soft shading along the bottom of the head.
    canvas.save();
    canvas.clipPath(Path()..addOval(head));
    canvas.drawOval(
      _oval(0.5, 0.92, 0.8, 0.3),
      _fill(_furShade.withValues(alpha: 0.35)),
    );
    canvas.restore();
    canvas.drawOval(head, _line(_furShade, 0.012));
    // Caramel patch over the right eye.
    canvas.save();
    canvas.clipPath(Path()..addOval(head));
    canvas.drawOval(_oval(0.66, 0.47, 0.22, 0.2), _fill(_patch));
    canvas.restore();
    // Little tuft on top.
    final tuft = Path()
      ..moveTo(_s * 0.46, _s * 0.27)
      ..quadraticBezierTo(_s * 0.47, _s * 0.19, _s * 0.53, _s * 0.2)
      ..quadraticBezierTo(_s * 0.5, _s * 0.23, _s * 0.54, _s * 0.27)
      ..close();
    canvas.drawPath(tuft, _fill(_fur));
    canvas.drawPath(tuft, _line(_furShade, 0.008));
  }

  void _sparklyEye(
    Canvas canvas,
    double x,
    double y,
    double r, {
    bool watery = false,
  }) {
    canvas.drawOval(_oval(x, y, r * 2, r * 2.2), _fill(_ink));
    canvas.drawCircle(
      _p(x + r * 0.35, y - r * 0.45),
      _s * r * 0.42,
      _fill(Colors.white),
    );
    canvas.drawCircle(
      _p(x - r * 0.4, y + r * 0.4),
      _s * r * 0.2,
      _fill(Colors.white),
    );
    if (watery) {
      canvas.drawArc(
        _oval(x, y + r * 0.1, r * 1.6, r * 1.7),
        0.35,
        2.4,
        false,
        _line(_tear.withValues(alpha: 0.9), 0.012),
      );
    }
  }

  void _eyes(Canvas canvas) {
    const lx = 0.37, rx = 0.63, y = 0.53;
    switch (mood) {
      case DogMood.happy:
        for (final x in [lx, rx]) {
          _sparklyEye(canvas, x, y, 0.058);
        }
      case DogMood.ecstatic:
        for (final x in [lx, rx]) {
          canvas.drawArc(
            _oval(x, y + 0.015, 0.1, 0.09),
            pi * 1.1,
            pi * 0.8,
            false,
            _line(_ink, 0.024),
          );
        }
      case DogMood.bored:
        for (final x in [lx, rx]) {
          final r = 0.052;
          canvas.drawArc(_oval(x, y, r * 2, r * 2.2), 0, pi, true, _fill(_ink));
          canvas.drawLine(
            _p(x - r * 1.1, y),
            _p(x + r * 1.1, y),
            _line(_ink, 0.016),
          );
          canvas.drawCircle(
            _p(x + r * 0.35, y + r * 0.45),
            _s * r * 0.22,
            _fill(Colors.white),
          );
        }
      case DogMood.sad:
        for (final x in [lx, rx]) {
          _sparklyEye(canvas, x, y + 0.01, 0.068, watery: true);
        }
      case DogMood.devastated:
        for (final x in [lx, rx]) {
          _sparklyEye(canvas, x, y + 0.01, 0.076, watery: true);
        }
      case DogMood.feral:
        for (final (x, side) in [(lx, -1.0), (rx, 1.0)]) {
          _sparklyEye(canvas, x, y + 0.01, 0.055);
          // Furious eyelids: cut the inner top of each eye.
          final lid = Path()
            ..moveTo(_s * (x - side * 0.075), _s * (y - 0.075))
            ..lineTo(_s * (x + side * 0.075), _s * (y - 0.075))
            ..lineTo(_s * (x + side * 0.075), _s * (y - 0.03))
            ..lineTo(_s * (x - side * 0.075), _s * (y + 0.005))
            ..close();
          canvas.drawPath(lid, _fill(x > 0.5 ? _patch : _fur));
        }
    }
  }

  void _brows(Canvas canvas) {
    final brow = _line(_ink, 0.016);
    switch (mood) {
      case DogMood.sad || DogMood.devastated:
        canvas.drawLine(_p(0.32, 0.44), _p(0.4, 0.42), brow);
        canvas.drawLine(_p(0.68, 0.44), _p(0.6, 0.42), brow);
      case DogMood.feral:
        final thick = _line(_ink, 0.022);
        canvas.drawLine(_p(0.3, 0.43), _p(0.43, 0.48), thick);
        canvas.drawLine(_p(0.7, 0.43), _p(0.57, 0.48), thick);
      default:
        break;
    }
  }

  void _muzzleAndMouth(Canvas canvas) {
    // Blush.
    final blushAlpha = switch (mood) {
      DogMood.feral => 0.85,
      DogMood.ecstatic => 0.7,
      DogMood.bored => 0.25,
      _ => 0.5,
    };
    final blush = _fill(
      (mood == DogMood.feral ? const Color(0xFFFF5A5A) : _blush).withValues(
        alpha: blushAlpha,
      ),
    );
    canvas.drawOval(_oval(0.27, 0.64, 0.1, 0.055), blush);
    canvas.drawOval(_oval(0.73, 0.64, 0.1, 0.055), blush);

    canvas.drawOval(_oval(0.5, 0.69, 0.3, 0.2), _fill(_muzzle));

    // Nose with a tiny shine.
    final nose = Path()
      ..moveTo(_s * 0.465, _s * 0.635)
      ..quadraticBezierTo(_s * 0.5, _s * 0.62, _s * 0.535, _s * 0.635)
      ..quadraticBezierTo(_s * 0.54, _s * 0.66, _s * 0.5, _s * 0.675)
      ..quadraticBezierTo(_s * 0.46, _s * 0.66, _s * 0.465, _s * 0.635)
      ..close();
    canvas.drawPath(nose, _fill(_ink));
    canvas.drawOval(
      _oval(0.488, 0.637, 0.018, 0.009),
      _fill(Colors.white.withValues(alpha: 0.7)),
    );

    final mouth = _line(_ink, 0.014);
    switch (mood) {
      case DogMood.happy:
        // ω mouth with a little tongue.
        canvas.drawOval(_oval(0.5, 0.725, 0.045, 0.045), _fill(_tongue));
        canvas.drawArc(_oval(0.47, 0.69, 0.06, 0.05), 0, pi, false, mouth);
        canvas.drawArc(_oval(0.53, 0.69, 0.06, 0.05), 0, pi, false, mouth);
      case DogMood.ecstatic:
        final open = Path()
          ..moveTo(_s * 0.44, _s * 0.695)
          ..quadraticBezierTo(_s * 0.5, _s * 0.71, _s * 0.56, _s * 0.695)
          ..quadraticBezierTo(_s * 0.555, _s * 0.78, _s * 0.5, _s * 0.78)
          ..quadraticBezierTo(_s * 0.445, _s * 0.78, _s * 0.44, _s * 0.695)
          ..close();
        canvas.drawPath(open, _fill(_ink));
        canvas.save();
        canvas.clipPath(open);
        canvas.drawOval(_oval(0.5, 0.78, 0.08, 0.07), _fill(_tongue));
        canvas.restore();
      case DogMood.bored:
        canvas.drawArc(_oval(0.47, 0.69, 0.06, 0.035), 0, pi, false, mouth);
        canvas.drawArc(_oval(0.53, 0.69, 0.06, 0.035), 0, pi, false, mouth);
      case DogMood.sad || DogMood.devastated:
        final w = mood == DogMood.devastated ? 0.1 : 0.08;
        canvas.drawArc(
          _oval(0.5, 0.74, w, 0.05),
          pi * 1.1,
          pi * 0.8,
          false,
          mouth,
        );
      case DogMood.feral:
        final snarl = Path()
          ..moveTo(_s * 0.43, _s * 0.71)
          ..quadraticBezierTo(_s * 0.5, _s * 0.69, _s * 0.57, _s * 0.71)
          ..quadraticBezierTo(_s * 0.56, _s * 0.765, _s * 0.5, _s * 0.765)
          ..quadraticBezierTo(_s * 0.44, _s * 0.765, _s * 0.43, _s * 0.71)
          ..close();
        canvas.drawPath(snarl, _fill(_ink));
        // Two tiny fangs.
        for (final x in [0.46, 0.54]) {
          final fang = Path()
            ..moveTo(_s * (x - 0.014), _s * 0.705)
            ..lineTo(_s * (x + 0.014), _s * 0.705)
            ..lineTo(_s * x, _s * 0.735)
            ..close();
          canvas.drawPath(fang, _fill(Colors.white));
        }
    }
  }

  void _extras(Canvas canvas) {
    switch (mood) {
      case DogMood.sad:
        _drop(canvas, 0.31, 0.63 + phase * 0.04, 0.022);
      case DogMood.devastated:
        // Streams of tears.
        for (final x in [0.33, 0.67]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                _s * (x - 0.012),
                _s * 0.58,
                _s * 0.024,
                _s * (0.08 + phase * 0.04),
              ),
              Radius.circular(_s * 0.012),
            ),
            _fill(_tear.withValues(alpha: 0.85)),
          );
          _drop(canvas, x, 0.69 + phase * 0.08, 0.02);
        }
      case DogMood.ecstatic:
        for (final (x, y, r) in [
          (0.14, 0.2, 0.05),
          (0.86, 0.24, 0.04),
          (0.8, 0.1, 0.028),
        ]) {
          _sparkle(canvas, x, y, r * (0.75 + phase * 0.4));
        }
      case DogMood.feral:
        // Anger mark.
        final mark = _line(const Color(0xFFE53935), 0.018);
        final c = _p(0.7, 0.33);
        for (var i = 0; i < 4; i++) {
          final a = i * pi / 2 + pi / 4;
          final o = Offset(cos(a), sin(a)) * _s * 0.035;
          canvas.drawArc(
            Rect.fromCircle(center: c + o * 1.5, radius: _s * 0.028),
            a + pi * 0.75,
            pi / 2,
            false,
            mark,
          );
        }
      case DogMood.bored:
        // A drifting "z".
        final z = _line(_ink.withValues(alpha: 0.3 + phase * 0.4), 0.014);
        final o = _p(0.8, 0.22 - phase * 0.04);
        final w = _s * 0.06;
        canvas.drawPath(
          Path()
            ..moveTo(o.dx, o.dy)
            ..lineTo(o.dx + w, o.dy)
            ..lineTo(o.dx, o.dy + w)
            ..lineTo(o.dx + w, o.dy + w),
          z,
        );
      case DogMood.happy:
        break;
    }
  }

  void _drop(Canvas canvas, double x, double y, double r) {
    final path = Path()
      ..moveTo(_s * x, _s * (y - r * 1.6))
      ..quadraticBezierTo(_s * (x + r * 1.1), _s * y, _s * x, _s * (y + r))
      ..quadraticBezierTo(
        _s * (x - r * 1.1),
        _s * y,
        _s * x,
        _s * (y - r * 1.6),
      )
      ..close();
    canvas.drawPath(path, _fill(_tear));
  }

  void _sparkle(Canvas canvas, double x, double y, double r) {
    final c = _p(x, y);
    final rr = r * _s;
    final star = Path()
      ..moveTo(c.dx, c.dy - rr)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + rr, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + rr)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - rr, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - rr)
      ..close();
    canvas.drawPath(star, _fill(const Color(0xFFFFD54F)));
  }

  @override
  bool shouldRepaint(DogPainter old) => old.mood != mood || old.phase != phase;
}
