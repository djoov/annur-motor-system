import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ui/desktop_scaffold.dart';
import '../../ui/app_list.dart';
import 'customers_provider.dart';
import 'customer_form_screen.dart';
import '../../core/theme.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CustomersProvider>();
      if (provider.customers.isEmpty) provider.fetchCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm([dynamic customer]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerFormScreen(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton.extended(
      onPressed: _openForm,
      icon: const Icon(LucideIcons.plus),
      label: const Text("Tambah Pelanggan"),
    );

    return Consumer<CustomersProvider>(
      builder: (context, provider, _) {
        final body = _buildListBody(provider);
        if (DesktopScaffold.isDesktop) {
          return DesktopScaffold(
            activeRoute: '/customers',
            floatingActionButton: fab,
            body: body,
          );
        }
        return Scaffold(floatingActionButton: fab, body: body);
      },
    );
  }

  Widget _buildListBody(CustomersProvider provider) {
    final filtered = provider.customers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery) ||
          c.phone.contains(_searchQuery);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return CustomScrollView(
      slivers: [
        AppSearchSliverAppBar(
          title: "Pelanggan",
          controller: _searchController,
          hint: "Cari nama atau nomor HP",
        ),
        if (provider.isLoading && provider.customers.isEmpty)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator.adaptive()),
          )
        else if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: provider.customers.isEmpty
                ? AppEmptyState(
                    icon: LucideIcons.users,
                    title: "Belum ada pelanggan",
                    message:
                        "Simpan pelanggan tetap atau bengkel langganan agar bisa dicatat hutangnya.",
                    actionLabel: "Tambah Pelanggan",
                    onAction: _openForm,
                  )
                : const AppEmptyState(
                    icon: LucideIcons.search,
                    title: "Pelanggan tidak ditemukan",
                    message: "Coba nama atau nomor lain.",
                  ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: AppListPanelSliver(
              itemCount: filtered.length,
              dividerIndent: 72,
              itemBuilder: (context, index) {
                final customer = filtered[index];
                final subtitle = [
                  if (customer.phone.isNotEmpty) customer.phone,
                  if (customer.address.isNotEmpty) customer.address,
                ].join(" · ");
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: InitialAvatar(customer.name),
                  title: Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: subtitle.isEmpty
                      ? null
                      : Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                  onTap: () => _openForm(customer),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}
