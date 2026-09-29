import 'package:flutter/widgets.dart';

/// Geometry of the floating bottom nav in `HomeScreen`, so tab screens can
/// keep content (and their own floating bars) clear of it.
class BottomNavMetrics {
  BottomNavMetrics._();

  /// Height of the nav pill itself.
  static const double height = 74;

  /// Distance from the screen bottom to the nav's bottom edge.
  static double bottomOffset(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    return inset > 0 ? inset + 8 : 16;
  }

  /// Distance from the screen bottom to the nav's top edge.
  static double top(BuildContext context) => bottomOffset(context) + height;
}
