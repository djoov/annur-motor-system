import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ui/desktop_scaffold.dart';
import 'categories_provider.dart';
import 'category_form_screen.dart';

import '../../core/theme.dart';

class CategoriesListScreen extends StatelessWidget {
  const CategoriesListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CategoriesProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.categories.isEmpty) provider.fetchCategories();
    });

    // Desktop Layout
    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(
        activeRoute: '/categories',
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryFormScreen(),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
        body: Consumer<CategoriesProvider>(
          builder: (context, provider, child) {
            return _buildListBody(context, provider);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kategori Barang"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CategoriesProvider>(
        builder: (context, provider, child) {
          return _buildListBody(context, provider);
        },
      ),
    );
  }

  Widget _buildListBody(BuildContext context, CategoriesProvider provider) {
    if (provider.isLoading && provider.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.categories.isEmpty) {
      return const Center(child: Text("Belum ada kategori"));
    }

    return RefreshIndicator(
      onRefresh: provider.fetchCategories,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final category = provider.categories[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              title: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(LucideIcons.chevronRight, size: 20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CategoryFormScreen(category: category),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
