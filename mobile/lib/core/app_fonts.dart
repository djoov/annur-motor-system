import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'fonts/plus_jakarta_sans_data.dart';

/// Registers Plus Jakarta Sans (400/500/600/700) under ONE family name so every
/// `FontWeight` renders with its real face.
///
/// google_fonts names each weight as its own family (`PlusJakartaSans_regular`,
/// `PlusJakartaSans_700`, ...); using `GoogleFonts.x().fontFamily` app-wide
/// therefore pinned all text to the regular face and bold was faked. The faces
/// are embedded as Dart data so this works offline and ships in Shorebird
/// patches (pubspec font assets would need a new release).
class AppFonts {
  AppFonts._();

  static const String family = 'PlusJakartaSans';

  static Future<void> load() async {
    final loader = FontLoader(family);
    for (final face in plusJakartaSansFaces) {
      loader.addFont(Future.value(ByteData.sublistView(base64Decode(face))));
    }
    await loader.load();
  }
}
