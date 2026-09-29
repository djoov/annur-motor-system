import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import '../pos/models/pos_models.dart';
import 'items_provider.dart';
import '../categories/categories_provider.dart';
import '../auth/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/cloudinary_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../scan/scan_screen.dart';

class ItemFormScreen extends StatefulWidget {
  final Item? item; // If null, it's Add mode. If exists, Edit mode.
  final String? initialCode; // Pre-filled barcode from smart scanner

  const ItemFormScreen({super.key, this.item, this.initialCode});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _sellPriceController; // Harga Jual
  late TextEditingController _buyPriceController; // Harga Beli/Modal
  late TextEditingController _stockController; // Unified Stock
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;
  late TextEditingController _locationController; // Unified Location/Rak
  late TextEditingController _descriptionController;

  XFile? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  static final _digitsOnly = FilteringTextInputFormatter.digitsOnly;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _codeController = TextEditingController(
      text: widget.item?.code ?? widget.initialCode ?? '',
    );
    _sellPriceController = TextEditingController(
      text: _initialNumber(widget.item?.sellPrice),
    );
    _buyPriceController = TextEditingController(
      text: _initialNumber(widget.item?.buyPrice),
    );
    _stockController = TextEditingController(
      text: widget.item?.stockDisplay.toString() ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.item?.category ?? 'Umum',
    );
    _tagsController = TextEditingController(
      text: widget.item?.tags.join(', ') ?? '',
    );
    _locationController = TextEditingController(
      text: widget.item?.locationDisplay ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.item?.description ?? '',
    );
    _imageUrl = widget.item?.imageUrl;

    // Rebuild for live margin calculation and name-based suggestions
    _nameController.addListener(_rebuild);
    _sellPriceController.addListener(_rebuild);
    _buyPriceController.addListener(_rebuild);
    _tagsController.addListener(_rebuild);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoriesProvider>(context, listen: false).fetchCategories();
    });
  }

  static String _initialNumber(int? v) => (v == null || v == 0) ? '' : '$v';

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_rebuild);
    _sellPriceController.removeListener(_rebuild);
    _buyPriceController.removeListener(_rebuild);
    _tagsController.removeListener(_rebuild);

    _nameController.dispose();
    _codeController.dispose();
    _sellPriceController.dispose();
    _buyPriceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final busy = _isSaving || _isUploading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Barang" : "Tambah Barang"),
        actions: [
          if (isEditing && isAdmin)
            IconButton(
              tooltip: "Hapus barang",
              icon: const Icon(LucideIcons.trash2,
                  color: AppColors.destructiveStrong),
              onPressed: busy ? null : _deleteItem,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildPhotoPicker(),
                const SizedBox(height: 24),

                // --- Barang ---
                _Section(
                  title: "Barang",
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: "Nama barang",
                        hintText: "Contoh: Oli Yamalube Matic 0.8L",
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? "Nama barang wajib diisi"
                          : null,
                    ),
                    if (_nameController.text.trim().length >= 3)
                      _buildNameSuggestions(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: "Kode / barcode",
                        hintText: "Scan atau ketik kode",
                        suffixIcon: IconButton(
                          tooltip: "Scan barcode",
                          icon: const Icon(LucideIcons.scanLine, size: 20),
                          onPressed: _scanCode,
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? "Kode wajib diisi"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tagsController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: "Tag pencarian",
                        hintText: "oli, yamaha, matic",
                        helperText: "Pisahkan dengan koma. Membantu kasir mencari.",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Harga ---
                _Section(
                  title: "Harga",
                  children: [
                    if (isAdmin) ...[
                      _moneyField(
                        controller: _buyPriceController,
                        label: "Harga modal",
                      ),
                      _buildMarginPresets(),
                      const SizedBox(height: 16),
                    ],
                    _moneyField(
                      controller: _sellPriceController,
                      label: "Harga jual",
                      validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                          ? "Harga jual wajib diisi"
                          : null,
                    ),
                    if (isAdmin) _buildMarginSummary(),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Stok ---
                _Section(
                  title: "Stok & lokasi",
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [_digitsOnly],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: "Jumlah stok",
                              hintText: "0",
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _locationController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: "Rak",
                              hintText: "A1-05",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Deskripsi ---
                _Section(
                  title: "Catatan",
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      minLines: 2,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        labelText: "Deskripsi (opsional)",
                        hintText: "Ukuran, cocok untuk motor apa, dll.",
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: busy ? null : _submitForm,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save, size: 20),
            label: Text(
              _isUploading
                  ? "Mengunggah foto..."
                  : (_isSaving ? "Menyimpan..." : "Simpan Barang"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildPhotoPicker() {
    final hasPhoto =
        _imageFile != null || (_imageUrl != null && _imageUrl!.isNotEmpty);

    ImageProvider? image;
    if (_imageFile != null) {
      image = kIsWeb
          ? NetworkImage(_imageFile!.path)
          : FileImage(File(_imageFile!.path)) as ImageProvider;
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      image = NetworkImage(_imageUrl!);
    }

    return Row(
      children: [
        Material(
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: _pickImage,
            child: Ink(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                image: image == null
                    ? null
                    : DecorationImage(image: image, fit: BoxFit.cover),
              ),
              child: image == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.camera,
                            size: 28, color: AppColors.mutedForeground),
                        SizedBox(height: 6),
                        Text(
                          "Tambah foto",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Foto barang",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                "Membantu kasir mengenali barang di layar Kasir.",
                style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _pickImage,
                    child: Text(hasPhoto ? "Ganti" : "Pilih foto"),
                  ),
                  if (hasPhoto)
                    TextButton(
                      onPressed: _deleteImage,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.destructiveStrong,
                      ),
                      child: const Text("Hapus"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Consumer<CategoriesProvider>(
      builder: (context, catProvider, _) {
        final current = _categoryController.text.trim().isEmpty
            ? 'Umum'
            : _categoryController.text.trim();
        // Keep the current value selectable even if it isn't a saved category
        // (e.g. picked from a name suggestion), so what you see is what's saved.
        final options = <String>{
          'Umum',
          ...catProvider.categories.map((e) => e.name),
          current,
        }.toList();

        return DropdownButtonFormField<String>(
          initialValue: current,
          key: ValueKey(current),
          isExpanded: true,
          decoration: const InputDecoration(labelText: "Kategori"),
          items: [
            for (final v in options)
              DropdownMenuItem(value: v, child: Text(v)),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _categoryController.text = v);
          },
        );
      },
    );
  }

  Widget _moneyField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [_digitsOnly],
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: "Rp ",
        hintText: "0",
      ),
      validator: validator,
    );
  }

  Widget _buildMarginPresets() {
    final buyPrice = int.tryParse(_buyPriceController.text) ?? 0;
    if (buyPrice <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Isi harga jual dari modal + untung:",
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pct in const [0.15, 0.20, 0.25, 0.30, 0.35])
                _marginChip(buyPrice, pct),
            ],
          ),
        ],
      ),
    );
  }

  Widget _marginChip(int buyPrice, double percentage) {
    // Round to nearest Rp 500
    final rounded = ((buyPrice * (1 + percentage) + 250) ~/ 500) * 500;
    final selected = _sellPriceController.text == '$rounded';

    return ChoiceChip(
      label: Text("+${(percentage * 100).round()}% · Rp ${_formatNumber(rounded)}"),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) =>
          setState(() => _sellPriceController.text = rounded.toString()),
    );
  }

  Widget _buildMarginSummary() {
    final sell = int.tryParse(_sellPriceController.text) ?? 0;
    final buy = int.tryParse(_buyPriceController.text) ?? 0;
    if (sell <= 0 || buy <= 0) return const SizedBox.shrink();

    final profit = sell - buy;
    final pct = profit / buy * 100;
    final isLoss = profit < 0;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLoss ? AppColors.destructiveSoft : AppColors.successSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLoss ? AppColors.destructiveBorder : AppColors.successBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLoss ? LucideIcons.triangleAlert : LucideIcons.trendingUp,
            size: 20,
            color: isLoss ? AppColors.destructiveStrong : AppColors.successStrong,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLoss
                  ? "Jual rugi Rp ${_formatNumber(-profit)} per barang"
                  : "Untung Rp ${_formatNumber(profit)} per barang (${pct.toStringAsFixed(1)}%)",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isLoss
                    ? AppColors.destructiveStrong
                    : AppColors.successStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSuggestions() {
    final name = _nameController.text.trim();
    final suggestedCategory = _inferCategoryFromName(name);
    final isCategoryDifferent =
        _categoryController.text != suggestedCategory;

    final currentTags = _tagsController.text
        .split(',')
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet();
    final unaddedTags = _inferTagsFromName(name)
        .where((t) => !currentTags.contains(t))
        .toList();

    if (!isCategoryDifferent && unaddedTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Saran dari nama barang:",
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isCategoryDifferent)
                ActionChip(
                  avatar: const Icon(LucideIcons.folderTree,
                      size: 16, color: AppColors.primary),
                  label: Text("Kategori: $suggestedCategory"),
                  onPressed: () => setState(
                      () => _categoryController.text = suggestedCategory),
                ),
              for (final tag in unaddedTags)
                ActionChip(
                  avatar: const Icon(LucideIcons.plus,
                      size: 16, color: AppColors.primary),
                  label: Text(tag),
                  onPressed: () {
                    final tags = _tagsController.text.trim();
                    _tagsController.text = tags.isEmpty ? tag : "$tags, $tag";
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _scanCode() async {
    final code = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanScreen(returnCodeOnly: true),
      ),
    );
    if (code is String) setState(() => _codeController.text = code);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ItemsProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final isEditing = widget.item != null;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final sellPrice = int.tryParse(_sellPriceController.text) ?? 0;
    final buyPrice = int.tryParse(_buyPriceController.text) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final category = _categoryController.text.trim().isEmpty
        ? 'Umum'
        : _categoryController.text.trim();
    final location = _locationController.text.trim();
    final description = _descriptionController.text.trim();
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    // Upload a newly picked photo first. If it fails, stop — saving now would
    // silently drop the photo (or erase the existing one).
    String? imageUrl = _imageUrl;
    if (_imageFile != null) {
      setState(() => _isUploading = true);
      final uploaded = await CloudinaryService.uploadImage(_imageFile!);
      if (!mounted) return;
      setState(() => _isUploading = false);
      if (uploaded == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Foto gagal diunggah. Periksa internet lalu coba lagi."),
            backgroundColor: AppColors.destructiveStrong,
          ),
        );
        return;
      }
      imageUrl = uploaded;
      _imageUrl = uploaded;
      _imageFile = null;
    }

    setState(() => _isSaving = true);
    try {
      final success = isEditing
          ? await provider.updateItem(
              widget.item!.id,
              name,
              code,
              sellPrice,
              buyPrice,
              stock,
              tags,
              category,
              imageUrl,
              location,
              description,
            )
          : await provider.addItem(
              name,
              code,
              sellPrice,
              buyPrice,
              stock,
              tags,
              category,
              imageUrl,
              location,
              description,
            );

      if (success) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(isEditing ? "$name diperbarui" : "$name ditambahkan"),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Barang gagal disimpan. Coba lagi."),
            backgroundColor: AppColors.destructiveStrong,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.destructiveStrong,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteItem() async {
    final provider = Provider.of<ItemsProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus barang?"),
        content: Text(
          "${widget.item!.name} akan dihapus permanen. Riwayat transaksinya tetap ada.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      await provider.deleteItem(widget.item!.id);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text("${widget.item!.name} dihapus")),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) setState(() => _imageFile = image);
  }

  void _deleteImage() {
    setState(() {
      _imageFile = null;
      _imageUrl = null;
    });
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  // ---------------------------------------------------------------------------
  // Name-based suggestions (keyword rules)
  // ---------------------------------------------------------------------------

  String _inferCategoryFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('oli') || lower.contains('oil') || lower.contains('mpx') || lower.contains('yamalube') || lower.contains('federal') || lower.contains('castrol')) return 'Oli & Pelumas';
    if (lower.contains('ban') || lower.contains('irc') || lower.contains('fdr') || lower.contains('tubeless') || lower.contains('corsa') || lower.contains('maxxis')) return 'Ban';
    if (lower.contains('busi') || lower.contains('ngk') || lower.contains('denso')) return 'Kelistrikan';
    if (lower.contains('rem') || lower.contains('kampas') || lower.contains('disc') || lower.contains('pad')) return 'Sistem Rem';
    if (lower.contains('aki') || lower.contains('accu') || lower.contains('yuasa') || lower.contains('gs')) return 'Aki & Baterai';
    if (lower.contains('rantai') || lower.contains('gir') || lower.contains('gear') || lower.contains('vanbelt') || lower.contains('roller')) return 'Transmisi';
    if (lower.contains('lampu') || lower.contains('bohlam') || lower.contains('led')) return 'Lampu & Penerangan';
    if (lower.contains('filter') || lower.contains('saringan')) return 'Filter';
    if (lower.contains('shock') || lower.contains('skok') || lower.contains('suspensi')) return 'Suspensi';
    if (lower.contains('baut') || lower.contains('mur') || lower.contains('seal') || lower.contains('ring')) return 'Baut & Fastener';
    return 'Sparepart';
  }

  List<String> _inferTagsFromName(String name) {
    final lower = name.toLowerCase();
    final Set<String> tags = {};

    if (lower.contains('honda')) tags.add('honda');
    if (lower.contains('yamaha')) tags.add('yamaha');
    if (lower.contains('suzuki')) tags.add('suzuki');
    if (lower.contains('kawasaki')) tags.add('kawasaki');

    if (lower.contains('vario')) tags.add('vario');
    if (lower.contains('beat')) tags.add('beat');
    if (lower.contains('scoopy')) tags.add('scoopy');
    if (lower.contains('nmax')) tags.add('nmax');
    if (lower.contains('pcx')) tags.add('pcx');
    if (lower.contains('aerox')) tags.add('aerox');
    if (lower.contains('mio')) tags.add('mio');

    if (lower.contains('matic')) tags.add('matic');
    if (lower.contains('injeksi') || lower.contains('fi')) tags.add('injeksi');
    if (lower.contains('tubeless')) tags.add('tubeless');
    if (lower.contains('depan')) tags.add('depan');
    if (lower.contains('belakang')) tags.add('belakang');

    return tags.toList();
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
