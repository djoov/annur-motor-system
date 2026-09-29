import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';

import '../stock_request/stock_request_provider.dart';
import '../auth/auth_provider.dart';
import 'package:intl/intl.dart';

class StockRequestsScreen extends StatefulWidget {
  const StockRequestsScreen({Key? key}) : super(key: key);

  @override
  State<StockRequestsScreen> createState() => _StockRequestsScreenState();
}

class _StockRequestsScreenState extends State<StockRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StockRequestProvider>(context, listen: false).fetchRequests();
    });
  }

  void _confirmApprove(BuildContext context, dynamic request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Setujui Permintaan?"),
        content: Text(
          "Stok gudang akan dikurangi ${request.requestQty} dan stok toko ditambah sejumlah yang sama.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(context);
              final auth = Provider.of<AuthProvider>(context, listen: false);

              final error =
                  await Provider.of<StockRequestProvider>(
                    context,
                    listen: false,
                  ).approveRequest(request);

              if (mounted) {
                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Permintaan disetujui. Stok dipindahkan."),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal: $error"),
                      backgroundColor: AppColors.destructive,
                    ),
                  );
                }
              }
            },
            child: const Text("Setujui"),
          ),
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context, dynamic request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tolak Permintaan?"),
        content: const Text("Permintaan akan ditandai sebagai ditolak."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final auth = Provider.of<AuthProvider>(context, listen: false);

              await Provider.of<StockRequestProvider>(
                context,
                listen: false,
              ).rejectRequest(request);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Permintaan ditolak.")),
                );
              }
            },
            child: const Text("Tolak", style: TextStyle(color: AppColors.destructiveStrong)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StockRequestProvider>(context);
    final requests = provider.requests.where((r) => r.status == 'pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Permintaan Stok Restock"),
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: requests.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.checkCircle, size: 64, color: AppColors.mutedForeground),
                  SizedBox(height: 16),
                  Text(
                    "Tidak ada permintaan tertunda.",
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = requests[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              req.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Minta: ${req.requestQty}",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Kode: ${req.itemId}",
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "Oleh: ${req.requesterName} • ${DateFormat('dd MMM HH:mm').format(req.createdAt)}",
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _confirmReject(context, req),
                                icon: const Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: AppColors.destructive,
                                ),
                                label: const Text(
                                  "Tolak",
                                  style: TextStyle(color: AppColors.destructiveStrong),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.destructiveStrong),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _confirmApprove(context, req),
                                icon: const Icon(
                                  LucideIcons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Setujui",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
