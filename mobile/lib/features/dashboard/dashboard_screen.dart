import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dashboard_provider.dart';
import '../../ui/responsive_layout.dart';
import 'dashboard_mobile.dart';
import 'dashboard_desktop.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    // On Android (phones & tablets), always use DashboardMobile
    // because DashboardDesktop requires DesktopScaffold which only works on Windows/Mac/Linux
    if (Platform.isAndroid || Platform.isIOS) {
      return const DashboardMobile();
    }

    // On desktop platforms, use ResponsiveLayout
    return const ResponsiveLayout(
      mobileBody: DashboardMobile(),
      desktopBody: DashboardDesktop(),
    );
  }
}
