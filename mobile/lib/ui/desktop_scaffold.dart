import 'package:flutter/material.dart';
import 'desktop_sidebar.dart';
import 'app_drawer.dart'; // Import AppDrawer for mobile
import '../core/theme.dart';
import 'dart:io'; // For Platform check
import 'package:flutter/foundation.dart'; // For kIsWeb

class DesktopScaffold extends StatelessWidget {
  final Widget body;
  final String activeRoute;
  final String? title; // Optional title for desktop header if needed
  final bool isScanner; // To handle scanner specific logic if needed
  final Widget? floatingActionButton;

  const DesktopScaffold({
    super.key,
    required this.body,
    required this.activeRoute,
    this.title,
    this.isScanner = false,
    this.floatingActionButton,
  });

  static bool get isDesktop {
    if (kIsWeb) return false; // Or check width
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) {
      // On Mobile: Return a standard Scaffold with AppBar & Drawer
      // This ensures Material widgets are present and structure is correct.
      return Scaffold(
        appBar: title != null
            ? AppBar(title: Text(title!))
            : null,
        drawer: const AppDrawer(),
        body: body,
        floatingActionButton: floatingActionButton,
      );
    }

    // On Desktop: Return the responsive Sidebar layout
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopSidebar(activeRoute: activeRoute),
          Expanded(
            child: Column(
              children: [
                if (title != null)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
