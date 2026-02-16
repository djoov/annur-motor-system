import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../ui/button.dart';
import '../../ui/input.dart';
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

  const ItemFormScreen({Key? key, this.item}) : super(key: key);

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _sellPriceController; // Harga Umum
  late TextEditingController _priceWorkshopController; // Harga Bengkel
  late TextEditingController _buyPriceController; // Harga Beli/Modal
  late TextEditingController _stockDisplayController; // Stok Toko
  late TextEditingController _stockWarehouseController; // Stok Gudang
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;
  late TextEditingController _locationDisplayController;
  late TextEditingController _locationWarehouseController;
  late TextEditingController _descriptionController;

  XFile? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _codeController = TextEditingController(text: widget.item?.code ?? '');
    _sellPriceController = TextEditingController(
      text: widget.item?.sellPrice.toString() ?? '0',
    );
    _priceWorkshopController = TextEditingController(
      text: widget.item?.priceWorkshop.toString() ?? '0',
    );
    _buyPriceController = TextEditingController(
      text: widget.item?.buyPrice.toString() ?? '0',
    );
    _stockDisplayController = TextEditingController(
      text: widget.item?.stockDisplay.toString() ?? '0',
    );
    _stockWarehouseController = TextEditingController(
      text: widget.item?.stockWarehouse.toString() ?? '0',
    );
    _categoryController = TextEditingController(
      text: widget.item?.category ?? 'Umum',
    );
    _tagsController = TextEditingController(
      text: widget.item?.tags.join(', ') ?? '',
    );
    _locationDisplayController = TextEditingController(
      text: widget.item?.locationDisplay ?? '',
    );
    _locationWarehouseController = TextEditingController(
      text: widget.item?.locationWarehouse ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.item?.description ?? '',
    );
    _imageUrl = widget.item?.imageUrl;

    // Add listeners for real-time margin calculation
    _sellPriceController.addListener(_onPriceChanged);
    _buyPriceController.addListener(_onPriceChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoriesProvider>(context, listen: false).fetchCategories();
    });
  }

  void _onPriceChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    // Remove listeners
    _sellPriceController.removeListener(_onPriceChanged);
    _buyPriceController.removeListener(_onPriceChanged);

    _nameController.dispose();
    _codeController.dispose();
    _sellPriceController.dispose();
    _priceWorkshopController.dispose();
    _buyPriceController.dispose();
    _stockDisplayController.dispose();
    _stockWarehouseController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _locationDisplayController.dispose();
    _locationWarehouseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemsProvider>(context);
    final isEditing = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Barang" : "Tambah Barang"),
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Image Picker ---
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 2),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: kIsWeb
                                      ? NetworkImage(_imageFile!.path)
                                      : FileImage(File(_imageFile!.path))
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : (_imageUrl != null && _imageUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(_imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                        ),
                        child:
                            (_imageFile == null &&
                                (_imageUrl == null || _imageUrl!.isEmpty))
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.camera,
                                    color: AppColors.mutedForeground,
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Upload Foto",
                                    style: TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    if (_imageFile != null ||
                        (_imageUrl != null && _imageUrl!.isNotEmpty))
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.edit2,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // Delete button
                    if (_imageFile != null ||
                        (_imageUrl != null && _imageUrl!.isNotEmpty))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _deleteImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Upload status text
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _uploadStatus.isEmpty
                            ? "Memproses gambar..."
                            : _uploadStatus,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // --- Product Info Section ---
              _buildSectionCard(
                title: "Informasi Utama",
                icon: LucideIcons.package,
                children: [
                  CustomInput(
                    label: "Nama Barang",
                    placeholder: "Contoh: Oli Yamalube",
                    controller: _nameController,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Nama wajib diisi" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomInput(
                          label: "Kode / SKU",
                          placeholder: "Scan atau ketik kode",
                          controller: _codeController,
                          validator: (v) =>
                              v!.isEmpty ? "Kode wajib diisi" : null,
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.scanLine, size: 18),
                            onPressed: () async {
                              final code = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ScanScreen(returnCodeOnly: true),
                                ),
                              );
                              if (code != null && code is String) {
                                setState(() {
                                  _codeController.text = code;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<CategoriesProvider>(
                    builder: (context, catProvider, child) {
                      final currentCat = _categoryController.text.isEmpty
                          ? 'Umum'
                          : _categoryController.text;
                      final options = {
                        'Umum',
                        ...catProvider.categories.map((e) => e.name),
                      }.toList();

                      return DropdownButtonFormField<String>(
                        value: options.contains(currentCat)
                            ? currentCat
                            : 'Umum',
                        decoration: InputDecoration(
                          labelText: "Kategori",
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.input,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.input,
                            ),
                          ),
                        ),
                        items: options.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _categoryController.text = newValue);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomInput(
                    label: "Tags (Pencarian)",
                    placeholder: "Contoh: oli, yamaha, matic (pisahkan koma)",
                    controller: _tagsController,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- Pricing Section ---
              _buildSectionCard(
                title: "Informasi Harga",
                icon: LucideIcons.banknote,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomInput(
                          label: "Harga Jual Umum",
                          placeholder: "0",
                          controller: _sellPriceController,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomInput(
                          label: "Harga Jual Bengkel",
                          placeholder: "0",
                          controller: _priceWorkshopController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  if (Provider.of<AuthProvider>(context).isAdmin) ...[
                    const SizedBox(height: 16),
                    CustomInput(
                      label: "Harga Beli (Modal)",
                      placeholder: "0",
                      controller: _buyPriceController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    // Profit Margin Display
                    Builder(
                      builder: (context) {
                        final sellPrice =
                            int.tryParse(_sellPriceController.text) ?? 0;
                        final buyPrice =
                            int.tryParse(_buyPriceController.text) ?? 0;
                        final profit = sellPrice - buyPrice;
                        final margin = buyPrice > 0
                            ? (profit / buyPrice * 100)
                            : 0.0;
                        final isProfit = profit > 0;
                        final isLoss = profit < 0;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isProfit
                                ? Colors.green.withOpacity(0.1)
                                : (isLoss
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isProfit
                                  ? Colors.green.withOpacity(0.3)
                                  : (isLoss
                                        ? Colors.red.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.3)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isProfit
                                    ? LucideIcons.trendingUp
                                    : (isLoss
                                          ? LucideIcons.trendingDown
                                          : LucideIcons.minus),
                                color: isProfit
                                    ? Colors.green
                                    : (isLoss ? Colors.red : Colors.grey),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Estimasi Margin",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      buyPrice > 0
                                          ? "Rp ${_formatNumber(profit)} (${margin.toStringAsFixed(1)}%)"
                                          : "Masukkan harga beli",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isProfit
                                            ? Colors.green[700]
                                            : (isLoss
                                                  ? Colors.red[700]
                                                  : Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // --- Stock & Location Section ---
              _buildSectionCard(
                title: "Stok & Lokasi",
                icon: LucideIcons.warehouse,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomInput(
                          label: "Stok Toko (Display)",
                          placeholder: "0",
                          controller: _stockDisplayController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomInput(
                          label: "Stok Gudang",
                          placeholder: "0",
                          controller: _stockWarehouseController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomInput(
                          label: "Lokasi Rak (Toko)",
                          placeholder: "Contoh: A1-05",
                          controller: _locationDisplayController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomInput(
                          label: "Lokasi Rak (Gudang)",
                          placeholder: "Contoh: G-B3",
                          controller: _locationWarehouseController,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- Description Section ---
              _buildSectionCard(
                title: "Deskripsi Produk",
                icon: LucideIcons.fileText,
                children: [
                  CustomInput(
                    label: "Deskripsi",
                    placeholder: "Tambahkan detail produk...",
                    controller: _descriptionController,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // --- Actions ---
              CustomButton(
                text: "Simpan Barang",
                icon: LucideIcons.save,
                isLoading: provider.isLoading || _isUploading,
                onPressed: _submitForm,
              ),

              if (isEditing) ...[
                const SizedBox(height: 16),
                CustomButton(
                  text: "Hapus Barang",
                  icon: LucideIcons.trash2,
                  isDestructive: true,
                  isOutline: true,
                  onPressed: _deleteItem,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ItemsProvider>(context, listen: false);
      final isEditing = widget.item != null;

      final name = _nameController.text;
      final code = _codeController.text;
      final sellPrice = int.tryParse(_sellPriceController.text) ?? 0;
      final priceWorkshop = int.tryParse(_priceWorkshopController.text) ?? 0;
      final buyPrice = int.tryParse(_buyPriceController.text) ?? 0;
      final stockDisplay = int.tryParse(_stockDisplayController.text) ?? 0;
      final stockWarehouse = int.tryParse(_stockWarehouseController.text) ?? 0;
      final category = _categoryController.text.isEmpty
          ? 'Umum'
          : _categoryController.text;
      final locationDisplay = _locationDisplayController.text;
      final locationWarehouse = _locationWarehouseController.text;
      final description = _descriptionController.text; // Get description

      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();

      // Upload Image if selected
      if (_imageFile != null) {
        setState(() => _isUploading = true);
        _imageUrl = await _uploadImage();
        setState(() => _isUploading = false);
      }

      try {
        bool success;
        if (isEditing) {
          success = await provider.updateItem(
            widget.item!.id,
            name,
            code,
            sellPrice,
            buyPrice,
            stockDisplay,
            stockWarehouse,
            priceWorkshop,
            tags,
            category,
            _imageUrl,
            locationDisplay,
            locationWarehouse,
            description, // Added
          );
        } else {
          success = await provider.addItem(
            name,
            code,
            sellPrice,
            buyPrice,
            stockDisplay,
            stockWarehouse,
            priceWorkshop,
            tags,
            category,
            _imageUrl,
            locationDisplay,
            locationWarehouse,
            description, // Added
          );
        }

        if (success && context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing ? "Barang diperbarui!" : "Barang ditambahkan!",
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gagal menyimpan barang. Coba lagi."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle Specific Duplicate Error
        // Since we import exceptions via a file not yet imported here, we might need dynamic check or ensure import.
        // Ideally we expect `DuplicateItemException`, let's just use `e.toString()` which we overrode.
        // Or cleaner: check runtime type if we import it.
        // Let's check string content for now to be safe if import is tricky, OR better: add the import.

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.toString())),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteItem() async {
    final provider = Provider.of<ItemsProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Barang?"),
        content: const Text("Tindakan ini tidak bisa dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await provider.deleteItem(widget.item!.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Barang dihapus.")));
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  void _deleteImage() {
    setState(() {
      _imageFile = null;
      _imageUrl = null;
    });
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    setState(() {
      _isUploading = true;
      _uploadStatus = "Mengompres gambar...";
    });

    print("Starting Cloudinary upload...");

    setState(() {
      _uploadStatus = "Mengupload ke server...";
    });

    final url = await CloudinaryService.uploadImage(_imageFile!);

    setState(() {
      _isUploading = false;
      _uploadStatus = '';
    });

    if (url == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Gagal upload gambar. Pastikan Cloudinary sudah dikonfigurasi.",
          ),
        ),
      );
    }

    return url;
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
