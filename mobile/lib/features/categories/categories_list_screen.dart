import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ui/desktop_scaffold.dart';
import '../../ui/app_list.dart';
import '../items/items_provider.dart';
import 'categories_provider.dart';
import 'category_form_screen.dart';
import 'category_model.dart';

import '../../core/theme.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CategoriesProvider>();
      if (provider.categories.isEmpty) provider.fetchCategories();
    });
  }

  void _openForm([CategoryModel? category]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryFormScreen(category: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton.extended(
      onPressed: _openForm,
      icon: const Icon(LucideIcons.plus),
      label: const Text("Tambah Kategori"),
    );
    final body = Consumer2<CategoriesProvider, ItemsProvider>(
      builder: (context, provider, items, _) => _buildListBody(provider, items),
    );

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(
        activeRoute: '/categories',
        floatingActionButton: fab,
        body: body,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Kategori")),
      floatingActionButton: fab,
      body: body,
    );
  }

  Widget _buildListBody(CategoriesProvider provider, ItemsProvider items) {
    if (provider.isLoading && provider.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (provider.categories.isEmpty) {
      return AppEmptyState(
        icon: LucideIcons.folderTree,
        title: "Belum ada kategori",
        message: "Kelompokkan barang (Oli, Ban, Rem, ...) agar mudah dicari di Kasir.",
        actionLabel: "Tambah Kategori",
        onAction: _openForm,
      );
    }

    // Item count per category name
    final counts = <String, int>{};
    for (final item in items.items) {
      final c = item.category ?? 'Umum';
      counts[c] = (counts[c] ?? 0) + 1;
    }
    final categories = [...provider.categories]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return RefreshIndicator(
      onRefresh: provider.fetchCategories,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: AppListPanelSliver(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final n = counts[category.name] ?? 0;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(n == 0 ? "Belum ada barang" : "$n barang"),
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                  onTap: () => _openForm(category),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}
