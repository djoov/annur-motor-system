import 'package:flutter/material.dart';
import 'dart:io'; // For Platform check

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    Key? key,
    required this.mobileBody,
    required this.desktopBody,
  }) : super(key: key);

  static bool isDesktop(BuildContext context) {
    // If on Windows, always consider it "Desktop-class" capability,
    // though we might still adapt internal grids based on width.
    // But for High-Level layout (Sidebar vs BottomNav), we prefer Desktop.
    if (Platform.isWindows) return true;
    return MediaQuery.of(context).size.width >= 900;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On Windows, strictly prevent MobileBody unless window is absurdly small (<400)
        // or user specifically requested this behavior.
        // The user wants "Native PC Look", so we force desktopBody on Windows.
        if (Platform.isWindows) {
          return desktopBody;
        }

        if (constraints.maxWidth < 900) {
          return mobileBody;
        } else {
          return desktopBody;
        }
      },
    );
  }
}
