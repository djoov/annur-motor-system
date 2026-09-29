import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../ui/app_form.dart';
import 'categories_provider.dart';
import 'category_model.dart';

class CategoryFormScreen extends StatefulWidget {
  final CategoryModel? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;

  bool get _isEditing => widget.category != null;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<CategoriesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _nameController.text.trim();

    setState(() => _isSaving = true);
    final success = _isEditing
        ? await provider.updateCategory(widget.category!.id, name)
        : await provider.addCategory(name);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(_isEditing ? "Kategori diperbarui" : "Kategori $name ditambahkan"),
      ));
    } else {
      showErrorSnack(context, "Kategori gagal disimpan. Coba lagi.");
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDestructive(
      context,
      title: "Hapus kategori?",
      message:
          "Kategori ${widget.category!.name} akan dihapus. Barang di dalamnya tidak ikut terhapus.",
    );
    if (!ok || !mounted) return;
    final navigator = Navigator.of(context);
    await context.read<CategoriesProvider>().deleteCategory(widget.category!.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormScaffold(
      title: _isEditing ? "Edit Kategori" : "Tambah Kategori",
      formKey: _formKey,
      saveLabel: "Simpan Kategori",
      isSaving: _isSaving,
      onSave: _save,
      onDelete: _isEditing ? _delete : null,
      deleteTooltip: "Hapus kategori",
      children: [
        TextFormField(
          controller: _nameController,
          autofocus: !_isEditing,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _save(),
          decoration: const InputDecoration(
            labelText: "Nama kategori",
            hintText: "Contoh: Oli & Pelumas, Ban, Sistem Rem",
            prefixIcon: Icon(LucideIcons.folderTree, size: 20),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? "Nama wajib diisi" : null,
        ),
      ],
    );
  }
}
