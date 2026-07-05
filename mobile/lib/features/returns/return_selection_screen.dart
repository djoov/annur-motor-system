import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/button.dart';
import '../history/models/transaction_model.dart';
import 'return_provider.dart';

class ReturnSelectionScreen extends StatefulWidget {
  final TransactionModel transaction;
  const ReturnSelectionScreen({super.key, required this.transaction});

  @override
  State<ReturnSelectionScreen> createState() => _ReturnSelectionScreenState();
}

class _ReturnSelectionScreenState extends State<ReturnSelectionScreen> {
  // Map to store return quantity for each item: {itemId: quantity}
  final Map<String, int> _returnQuantities = {};

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final returnProvider = Provider.of<ReturnProvider>(context);

    // Calculate refund total
    int refundTotal = 0;
    widget.transaction.items.forEach((item) {
      int qty = _returnQuantities[item.itemId] ?? 0;
      refundTotal += qty * item.sellPrice;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Barang Retur"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.transaction.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = widget.transaction.items[index];
                final returnQty = _returnQuantities[item.itemId] ?? 0;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: returnQty > 0
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Harga: ${currencyFormat.format(item.sellPrice)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "Beli: ${item.quantity} Unit",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quantity Controller
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.minus),
                            onPressed: returnQty > 0
                                ? () {
                                    setState(() {
                                      _returnQuantities[item.itemId] =
                                          returnQty - 1;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            "$returnQty",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.plus),
                            onPressed: returnQty < item.quantity
                                ? () {
                                    setState(() {
                                      _returnQuantities[item.itemId] =
                                          returnQty + 1;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Refund:",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      currencyFormat.format(refundTotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: "Proses Retur",
                  isLoading: returnProvider.isLoading,
                  onPressed: refundTotal > 0
                      ? () async {
                          // Collect items
                          List<Map<String, dynamic>> itemsToReturn = [];
                          widget.transaction.items.forEach((item) {
                            int qty = _returnQuantities[item.itemId] ?? 0;
                            if (qty > 0) {
                              itemsToReturn.add({
                                'itemId': item.itemId,
                                'itemName': item.itemName,
                                'quantity': qty,
                                'sellPrice': item.sellPrice,
                                'buyPrice': item.buyPrice,
                              });
                            }
                          });

                          final success = await returnProvider.processReturn(
                            originalTransactionId: widget.transaction.id,
                            itemsToReturn: itemsToReturn,
                            customerId: widget.transaction.customerId,
                            customerName: widget.transaction.customerName,
                          );

                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Retur Berhasil Diproses"),
                              ),
                            );
                            Navigator.pop(context); // Close selection screen
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
