import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    Key? key,
    required this.mobileBody,
    required this.desktopBody,
  }) : super(key: key);

  // dart:io Platform throws on web, so check via defaultTargetPlatform.
  static bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool isDesktop(BuildContext context) {
    // If on Windows, always consider it "Desktop-class" capability,
    // though we might still adapt internal grids based on width.
    // But for High-Level layout (Sidebar vs BottomNav), we prefer Desktop.
    if (_isWindows) return true;
    return MediaQuery.of(context).size.width >= 900;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On Windows, strictly prevent MobileBody unless window is absurdly small (<400)
        // or user specifically requested this behavior.
        // The user wants "Native PC Look", so we force desktopBody on Windows.
        if (_isWindows) {
          return desktopBody;
        }

        // Only true phones (<600px) use mobileBody, tablets/desktops use desktopBody
        if (constraints.maxWidth < 900) {
          return mobileBody;
        } else {
          return desktopBody;
        }
      },
    );
  }
}
