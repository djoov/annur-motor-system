import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ui/desktop_scaffold.dart';
import '../../ui/app_list.dart';
import 'suppliers_provider.dart';
import 'supplier_form_screen.dart';
import 'supplier_model.dart';
import '../../core/theme.dart';

class SuppliersListScreen extends StatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  State<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends State<SuppliersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SuppliersProvider>();
      if (provider.suppliers.isEmpty) provider.fetchSuppliers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm([SupplierModel? supplier]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormScreen(supplier: supplier)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuppliersProvider>();
    final fab = FloatingActionButton.extended(
      onPressed: _openForm,
      icon: const Icon(LucideIcons.plus),
      label: const Text("Tambah Supplier"),
    );
    final body = _buildListBody(provider);

    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(
        activeRoute: '/suppliers',
        floatingActionButton: fab,
        body: body,
      );
    }
    return Scaffold(floatingActionButton: fab, body: body);
  }

  Widget _buildListBody(SuppliersProvider provider) {
    final filtered = provider.suppliers.where((s) {
      return s.name.toLowerCase().contains(_searchQuery) ||
          s.contactPerson.toLowerCase().contains(_searchQuery);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return CustomScrollView(
      slivers: [
        AppSearchSliverAppBar(
          title: "Supplier",
          controller: _searchController,
          hint: "Cari supplier atau nama sales",
        ),
        if (provider.isLoading && provider.suppliers.isEmpty)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator.adaptive()),
          )
        else if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: provider.suppliers.isEmpty
                ? AppEmptyState(
                    icon: LucideIcons.truck,
                    title: "Belum ada supplier",
                    message: "Simpan distributor langganan untuk mencatat pembelian barang.",
                    actionLabel: "Tambah Supplier",
                    onAction: _openForm,
                  )
                : const AppEmptyState(
                    icon: LucideIcons.search,
                    title: "Supplier tidak ditemukan",
                    message: "Coba nama lain.",
                  ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: AppListPanelSliver(
              itemCount: filtered.length,
              dividerIndent: 72,
              itemBuilder: (context, index) {
                final s = filtered[index];
                final subtitle = [
                  if (s.contactPerson.isNotEmpty) s.contactPerson,
                  if (s.phone.isNotEmpty) s.phone,
                ].join(" · ");
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: InitialAvatar(s.name),
                  title: Text(
                    s.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                  onTap: () => _openForm(s),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}
