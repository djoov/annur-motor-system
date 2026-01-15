import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ui/button.dart';
import '../../ui/input.dart';
import 'categories_provider.dart';
import 'category_model.dart';

class CategoryFormScreen extends StatefulWidget {
  final CategoryModel? category;

  const CategoryFormScreen({Key? key, this.category}) : super(key: key);

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CategoriesProvider>(context);
    final isEditing = widget.category != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Kategori" : "Tambah Kategori"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Nama Kategori",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              CustomInput(
                placeholder: "Contoh: Oli, Ban, Sparepart...",
                controller: _nameController,
                validator: (v) =>
                    v == null || v.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: "Simpan",
                isLoading: provider.isLoading,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final name = _nameController.text;
                    bool success;
                    if (isEditing) {
                      success = await provider.updateCategory(
                        widget.category!.id,
                        name,
                      );
                    } else {
                      success = await provider.addCategory(name);
                    }

                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? "Kategori diperbarui"
                                : "Kategori ditambahkan",
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
                  text: "Hapus",
                  isDestructive: true,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Hapus Kategori?"),
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
                      await provider.deleteCategory(widget.category!.id);
                      if (context.mounted) {
                        Navigator.pop(context);
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
