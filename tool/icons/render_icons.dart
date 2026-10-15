// Renders the launcher icon artwork from DogPainter. Run via
// tool/generate_icons.sh, which then resizes it for Android and iOS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remindya/logic/dog_mood.dart';
import 'package:remindya/widgets/dog_mascot.dart';

const variants = {
  'happy': (Color(0xFF5CC9AE), DogMood.happy),
  'sad': (Color(0xFF5C7FB8), DogMood.devastated),
  'feral': (Color(0xFFC62828), DogMood.feral),
};

Future<void> render(
  String path,
  int px,
  Color? bg,
  DogMood mood,
  double dogScale,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = px.toDouble();
  if (bg != null) {
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), Paint()..color = bg);
  }
  final d = s * dogScale;
  // The face sits slightly low in the painter's box; nudge it up to centre.
  canvas.translate((s - d) / 2, (s - d) / 2 - d * 0.04);
  DogPainter(mood, 0.5).paint(canvas, Size.square(d));
  final img = await recorder.endRecording().toImage(px, px);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('render icon artwork', () async {
    final out = Platform.environment['ICON_OUT'] ?? 'build/icons';
    Directory(out).createSync(recursive: true);
    for (final MapEntry(key: name, value: (bg, mood)) in variants.entries) {
      // Full square icon (iOS, legacy Android).
      await render('$out/full_$name.png', 1024, bg, mood, 0.9);
      // Adaptive foreground: 108dp canvas, dog inside the 66dp safe zone.
      await render('$out/fg_$name.png', 432, null, mood, 0.7);
    }
  });
}
