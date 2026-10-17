import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';

/// Search field used at the top of list screens.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(LucideIcons.search, size: 20),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: "Hapus pencarian",
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: controller.clear,
                ),
        ),
      ),
    );
  }
}

/// Pinned white app bar area holding a search field (for CustomScrollView).
class AppSearchSliverAppBar extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hint;
  final List<Widget>? actions;

  const AppSearchSliverAppBar({
    super.key,
    required this.title,
    required this.controller,
    required this.hint,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      title: Text(title),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: AppSearchField(controller: controller, hint: hint),
        ),
      ),
    );
  }
}

/// Icon + title + one sentence + optional action.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lazily built rows inside one bordered white panel, separated by dividers.
class AppListPanelSliver extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double dividerIndent;

  const AppListPanelSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.dividerIndent = 16,
  });

  /// Rows stop growing past this width and the panel centers (tablets).
  static const double maxWidth = 760;

  @override
  Widget build(BuildContext context) {
    final panel = DecoratedSliver(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      sliver: SliverList.separated(
        itemCount: itemCount,
        separatorBuilder: (_, __) =>
            Divider(indent: dividerIndent, endIndent: 16),
        itemBuilder: itemBuilder,
      ),
    );

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final extra = constraints.crossAxisExtent - maxWidth;
        if (extra <= 0) return panel;
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: extra / 2),
          sliver: panel,
        );
      },
    );
  }
}

/// Round initial avatar used for people (customers, suppliers, users).
class InitialAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const InitialAvatar(this.name, {super.key, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
