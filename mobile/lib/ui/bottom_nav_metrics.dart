import 'package:flutter/widgets.dart';

import 'desktop_scaffold.dart';

/// Geometry of HomeScreen's navigation, so tab screens can keep content (and
/// their own floating bars/FABs) clear of it.
///
/// Phones and portrait tablets get a floating bottom nav. Wide screens
/// (landscape tablets, wide browser windows) get a side rail instead, so
/// nothing at the bottom (e.g. the Kasir pay panel) is covered.
class BottomNavMetrics {
  BottomNavMetrics._();

  /// Width from which HomeScreen switches to the side rail.
  static const double railBreakpoint = 840;

  /// Height of the floating nav pill.
  static const double height = 74;

  /// True when HomeScreen shows the side rail instead of the bottom nav.
  /// Windows keeps its own desktop layout (DesktopScaffold sidebar).
  static bool usesRail(BuildContext context) =>
      !DesktopScaffold.isDesktop &&
      MediaQuery.sizeOf(context).width >= railBreakpoint;

  /// Distance from the screen bottom to the nav's bottom edge.
  static double bottomOffset(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    return inset > 0 ? inset + 8 : 16;
  }

  /// Space a tab screen must leave at the bottom so its last content isn't
  /// hidden behind the floating nav (small margin when the rail is used).
  static double top(BuildContext context) => usesRail(context)
      ? 16
      : bottomOffset(context) + height;

  /// Extra lift for a tab screen's FAB so it sits above the floating nav.
  static double fabLift(BuildContext context) =>
      usesRail(context) ? 0 : height + 8;
}
