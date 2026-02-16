import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../ui/desktop_scaffold.dart';
import 'customers_provider.dart';
import 'customer_form_screen.dart';
import '../../core/theme.dart';
import '../../ui/input.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({Key? key}) : super(key: key);

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
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CustomersProvider>(context, listen: false);
      if (provider.customers.isEmpty) {
        provider.fetchCustomers();
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
    return Consumer<CustomersProvider>(
      builder: (context, provider, child) {
        // Desktop Layout
        if (DesktopScaffold.isDesktop) {
          return DesktopScaffold(
            activeRoute: '/customers',
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerFormScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(LucideIcons.plus, color: Colors.white),
            ),
            body: _buildListBody(context, provider, _searchQuery),
          );
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerFormScreen(),
                ),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(LucideIcons.plus, color: Colors.white),
          ),
          body: _buildListBody(context, provider, _searchQuery),
        );
      },
    );
  }

  Widget _buildListBody(
    BuildContext context,
    CustomersProvider provider,
    String searchQuery,
  ) {
    final filtered = provider.customers.where((c) {
      return c.name.toLowerCase().contains(searchQuery) ||
          c.phone.contains(searchQuery);
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          snap: false,
          title: const Text("Data Pelanggan"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CustomInput(
                placeholder: "Cari Nama / No. HP...",
                controller: _searchController,
                suffixIcon: const Icon(LucideIcons.search, size: 20),
              ),
            ),
          ),
        ),

        if (provider.isLoading && provider.customers.isEmpty)
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
                    LucideIcons.users,
                    size: 64,
                    color: AppColors.mutedForeground,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Tidak ada pelanggan ditemukan",
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
                final customer = filtered[index];
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
                              CustomerFormScreen(customer: customer),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            foregroundColor: AppColors.primary,
                            radius: 24,
                            child: Text(
                              customer.name.isNotEmpty
                                  ? customer.name[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
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
                                      LucideIcons.phone,
                                      size: 14,
                                      color: AppColors.mutedForeground,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      customer.phone.isNotEmpty
                                          ? customer.phone
                                          : "-",
                                      style: const TextStyle(
                                        color: AppColors.mutedForeground,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                if (customer.address.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
