import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ui/desktop_scaffold.dart';
import 'suppliers_provider.dart';
import 'supplier_form_screen.dart';
import '../../core/theme.dart';
import '../../ui/input.dart';

class SuppliersListScreen extends StatefulWidget {
  const SuppliersListScreen({Key? key}) : super(key: key);

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
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SuppliersProvider>(context, listen: false);
      if (provider.suppliers.isEmpty) {
        provider.fetchSuppliers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SuppliersProvider>(
      context,
    ); // Listen to changes

    // Desktop Layout
    if (DesktopScaffold.isDesktop) {
      return DesktopScaffold(
        activeRoute: '/suppliers',
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupplierFormScreen(),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
        body: _buildListBody(context, provider, _searchQuery),
      );
    }

    // Mobile Layout
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SupplierFormScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: _buildListBody(context, provider, _searchQuery),
    );
  }

  Widget _buildListBody(
    BuildContext context,
    SuppliersProvider provider,
    String searchQuery,
  ) {
    final filtered = provider.suppliers.where((s) {
      return s.name.toLowerCase().contains(searchQuery) ||
          s.contactPerson.toLowerCase().contains(searchQuery);
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          snap: false,
          title: const Text("Data Supplier"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CustomInput(
                placeholder: "Cari Supplier / Sales...",
                controller: _searchController,
                suffixIcon: const Icon(LucideIcons.search, size: 20),
              ),
            ),
          ),
        ),

        if (provider.isLoading && provider.suppliers.isEmpty)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filtered.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.truck,
                    size: 64,
                    color: AppColors.mutedForeground,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Tidak ada supplier ditemukan",
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final supplier = filtered[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SupplierFormScreen(supplier: supplier),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal.withOpacity(0.1),
                            foregroundColor: Colors.teal,
                            radius: 24,
                            child: const Icon(LucideIcons.truck, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  supplier.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.user,
                                      size: 14,
                                      color: AppColors.mutedForeground,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      supplier.contactPerson.isNotEmpty
                                          ? supplier.contactPerson
                                          : "Tanpa Sales",
                                      style: const TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                if (supplier.phone.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    supplier.phone,
                                    style: const TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            color: AppColors.mutedForeground,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: filtered.length),
            ),
          ),
      ],
    );
  }
}
