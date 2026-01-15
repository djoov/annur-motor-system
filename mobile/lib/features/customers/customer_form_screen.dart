import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/button.dart';
import '../../ui/input.dart';
import 'customers_provider.dart';
import 'customer_model.dart';

class CustomerFormScreen extends StatefulWidget {
  final CustomerModel? customer;

  const CustomerFormScreen({Key? key, this.customer}) : super(key: key);

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customer?.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomersProvider>(context);
    final isEditing = widget.customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Pelanggan" : "Tambah Pelanggan"),
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Informasi Pelanggan",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              CustomInput(
                placeholder: "Nama Lengkap",
                controller: _nameController,
                validator: (v) =>
                    v == null || v.isEmpty ? "Nama wajib diisi" : null,
                suffixIcon: const Icon(LucideIcons.user, size: 18),
              ),
              const SizedBox(height: 16),

              CustomInput(
                placeholder: "Nomor Telepon (08xxxx)",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                suffixIcon: const Icon(LucideIcons.phone, size: 18),
              ),
              const SizedBox(height: 16),

              CustomInput(
                placeholder: "Alamat Lengkap",
                controller: _addressController,
                keyboardType: TextInputType.multiline,
                suffixIcon: const Icon(LucideIcons.mapPin, size: 18),
              ),
              const SizedBox(height: 48),

              CustomButton(
                text: "Simpan Pelanggan",
                icon: LucideIcons.save,
                isLoading: provider.isLoading,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final name = _nameController.text;
                    final phone = _phoneController.text;
                    final address = _addressController.text;

                    bool success;
                    if (isEditing) {
                      success = await provider.updateCustomer(
                        widget.customer!.id,
                        name,
                        phone,
                        address,
                      );
                    } else {
                      success = await provider.addCustomer(
                        name,
                        phone,
                        address,
                      );
                    }

                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? "Pelanggan diperbarui"
                                : "Pelanggan ditambahkan",
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                CustomButton(
                  text: "Hapus Pelanggan",
                  icon: LucideIcons.trash2,
                  isDestructive: true,
                  isOutline: true,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Hapus Pelanggan?"),
                        content: const Text(
                          "Tindakan ini tidak bisa dibatalkan.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Hapus",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await provider.deleteCustomer(widget.customer!.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Pelanggan dihapus")),
                        );
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
