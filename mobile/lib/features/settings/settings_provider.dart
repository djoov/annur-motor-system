import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:flutter_pos_printer_platform/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart'
    as legacy; // Aliased to avoid conflict
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class SettingsProvider with ChangeNotifier {
  late final PrinterManager _printerManager;
  final legacy.BlueThermalPrinter _legacyPrinter =
      legacy.BlueThermalPrinter.instance; // Legacy Instance

  List<PrinterDevice> _devices = [];
  PrinterDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isLoading = false;
  StreamSubscription<PrinterDevice>? _subscription;
  StreamSubscription<BTStatus>? _subscriptionBk;

  // Receipt Settings
  String _shopName = "Annur Motor";
  String _shopAddress = "Jl. Contoh No. 123";
  String _shopPhone = "0812-3456-7890";
  String _receiptFooter = "Terima Kasih atas Kunjungan Anda";

  // Profile Settings
  String _adminName = "Admin";

  // Advanced Settings
  bool _useBle = false;
  bool _useLegacy = true; // Default to true, but check Platform later

  // Custom Logo
  File? _customLogoFile;

  List<PrinterDevice> get devices => _devices;
  PrinterDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String get shopName => _shopName;
  String get shopAddress => _shopAddress;
  String get shopPhone => _shopPhone;
  String get receiptFooter => _receiptFooter;
  String get adminName => _adminName;
  bool get useBle => _useBle;
  bool get useLegacy => _useLegacy;
  File? get customLogoFile => _customLogoFile;

  SettingsProvider() {
    // initialize safely
    try {
      _printerManager = PrinterManager.instance;
    } catch (e) {
      print("PrinterManager init error: $e");
    }

    _loadSettings();
    if (!kIsWeb) {
      _scanListeners();
    }
  }

  void setLegacyMode(bool value) {
    _useLegacy = value;
    if (value) _useBle = false; // Exclusive
    notifyListeners();
    disconnect();
    scanDevices();
  }

  void setBleMode(bool value) {
    _useBle = value;
    if (value) _useLegacy = false; // Exclusive
    notifyListeners();
    // Re-scan if mode changes
    disconnect();
    scanDevices();
  }

  void _scanListeners() async {
    // Auto-Turn On Bluetooth (Android Only)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        // We use FlutterBluePlus just for this handy utility
        if (await FlutterBluePlus.adapterState.first ==
            BluetoothAdapterState.off) {
          print("Bluetooth is OFF. Requesting to turn ON...");
          await FlutterBluePlus.turnOn();
        }
      } catch (e) {
        print("Error turning on bluetooth: $e");
      }
    }

    // Optional: Monitor connection state if supported
    try {
      _printerManager.stateBluetooth.listen((status) {
        _isConnected = status == BTStatus.connected;
        notifyListeners();
      });
    } catch (e) {
      print("Error listening to bluetooth state: $e");
    }
  }

  Future<void> saveSettings(
    String name,
    String address,
    String phone,
    String footer,
    String adminName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    _shopName = name;
    _shopAddress = address;
    _shopPhone = phone;
    _receiptFooter = footer;
    _adminName = adminName;

    await prefs.setString('shop_name', name);
    await prefs.setString('shop_address', address);
    await prefs.setString('shop_phone', phone);
    await prefs.setString('receipt_footer', footer);
    await prefs.setString('admin_name', adminName);
    notifyListeners();
  }

  // Pick and Save Custom Logo
  Future<void> pickLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String path = directory.path;
        final String fileName =
            'custom_logo_${DateTime.now().millisecondsSinceEpoch}.png';
        final File localImage = await File(image.path).copy('$path/$fileName');

        _customLogoFile = localImage;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('receipt_logo_path', localImage.path);

        notifyListeners();
      }
    } catch (e) {
      print("Error picking logo: $e");
    }
  }

  // Remove Custom Logo
  Future<void> removeLogo() async {
    _customLogoFile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('receipt_logo_path');
    notifyListeners();
  }

  List<PrinterDevice> _knownDevices = [];

  // Update scanDevices to include known devices
  Future<void> scanDevices() async {
    if (kIsWeb) return;

    print("Starting Scan Devices (BLE: $_useBle)...");
    _isLoading = true;
    notifyListeners();

    try {
      // Request all relevant permissions
      List<Permission> permissions = [
        Permission.bluetooth, // Legacy
        Permission.bluetoothScan, // Android 12+
        Permission.bluetoothConnect, // Android 12+
        Permission.location, // General
        Permission.locationWhenInUse, // often required
      ];

      await permissions.request();
    } catch (e) {
      print("Error requesting permissions: $e");
    }

    // 1. Load History (Known Devices)
    _devices = List.from(_knownDevices);

    // LEGACY SCAN (Classic Bluetooth)
    // Only run on Android
    if (_useLegacy && !kIsWeb && Platform.isAndroid) {
      print("Scanning Legacy (BlueThermal)...");
      try {
        // Legacy lib only gets Bonded items usually
        List<legacy.BluetoothDevice> legacyBonded = await _legacyPrinter
            .getBondedDevices();
        for (var d in legacyBonded) {
          _devices.add(
            PrinterDevice(name: d.name ?? "Unknown", address: d.address),
          );
        }
      } catch (e) {
        print("Legacy Scan Error: $e");
      }
      _isLoading = false;
      notifyListeners();
      return; // Legacy mode relies mostly on bonded
    }

    // 2. Load System Bonded Devices (Crucial for many users)
    if (!_useBle) {
      try {
        final bonded = await BluetoothPrinterConnector.getBondedDevices();
        for (var device in bonded) {
          if (!_devices.any((d) => d.address == device.address)) {
            print("Found Bonded (Connector): ${device.name}");
            _devices.add(device);
          }
        }
      } catch (e) {
        print("Connector Bonded Error: $e");
      }
    }

    // Method B: flutter_blue_plus (Bonded BLE/Classic sometimes show up)
    try {
      final bondedBlue = await FlutterBluePlus.bondedDevices;
      for (var d in bondedBlue) {
        final address = d.remoteId.str;
        final name = d.platformName.isNotEmpty ? d.platformName : d.advName;

        if (!_devices.any((dv) => dv.address == address)) {
          print("Found Bonded (BluePlus): $name");
          _devices.add(PrinterDevice(name: name, address: address));
        }
      }
    } catch (e) {
      print("BluePlus Bonded Error: $e");
    }

    notifyListeners();
    // 3. Start Discovery
    try {
      _subscription = _printerManager
          .discovery(type: PrinterType.bluetooth, isBle: _useBle)
          .listen(
            (device) {
              print("Found device: ${device.name} (${device.address})");
              final index = _devices.indexWhere(
                (element) => element.address == device.address,
              );
              if (index != -1) {
                _devices[index] = device;
              } else {
                _devices.add(device);
              }
              notifyListeners();
            },
            onError: (e) {
              print("Discovery Error: $e");
            },
          );
    } catch (e) {
      print("Error starting discovery: $e");
      _isLoading = false;
      notifyListeners();
    }

    // Extended Timeout
    Timer(const Duration(seconds: 10), () {
      print("Scan finished.");
      _subscription?.cancel();
      _isLoading = false;
      notifyListeners();
    });
  }

  // Load Settings and Known Devices
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _shopName = prefs.getString('shop_name') ?? "Annur Motor";
    _shopAddress = prefs.getString('shop_address') ?? "Jl. Contoh No. 123";
    _shopPhone = prefs.getString('shop_phone') ?? "0812-3456-7890";
    _receiptFooter = prefs.getString('receipt_footer') ?? "Terima Kasih";
    _adminName = prefs.getString('admin_name') ?? "Admin";

    // Load Custom Logo
    final logoPath = prefs.getString('receipt_logo_path');
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        _customLogoFile = file;
      }
    }

    // Load Known Devices
    final historyString = prefs.getString('printer_history');
    if (historyString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyString);
        _knownDevices = decoded
            .map((e) => PrinterDevice(name: e['name'], address: e['address']))
            .toList();
        _devices = List.from(_knownDevices);
      } catch (e) {
        print("Error loading printer history: $e");
      }
    }

    notifyListeners();

    // Auto-Connect if saved MAC exists
    final savedMac = prefs.getString('printer_mac');
    if (savedMac != null && savedMac.isNotEmpty) {
      try {
        final device = _knownDevices.firstWhere(
          (d) => d.address == savedMac,
          orElse: () => PrinterDevice(name: 'Unknown', address: savedMac),
        );
        // Delay slightly to ensure UI is ready if needed, though provider init is usually safe
        Future.delayed(const Duration(seconds: 1), () {
          print("Attempting auto-connect to: ${device.name} ($savedMac)");
          connect(device);
        });
      } catch (e) {
        print("Auto-connect failed: $e");
      }
    }
  }

  // Save Known Device
  Future<void> _saveKnownDevice(PrinterDevice device) async {
    if (!_knownDevices.any((d) => d.address == device.address)) {
      _knownDevices.add(device);

      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        _knownDevices
            .map((d) => {'name': d.name, 'address': d.address})
            .toList(),
      );

      await prefs.setString('printer_history', encoded);
    }
  }

  Future<void> connect(PrinterDevice device) async {
    if (kIsWeb) return;

    _isLoading = true;
    notifyListeners();

    if (_useLegacy && !kIsWeb && Platform.isAndroid) {
      try {
        // Connection Check
        // isConnected can be nullable
        if ((await _legacyPrinter.isConnected) == true) {
          await _legacyPrinter.disconnect();
        }

        // Connect using Legacy Device Object
        legacy.BluetoothDevice legacyDevice = legacy.BluetoothDevice(
          device.name,
          device.address,
        );
        await _legacyPrinter.connect(legacyDevice);

        _selectedDevice = device;
        _isConnected = true;

        // Save
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('printer_mac', device.address ?? '');
        await _saveKnownDevice(device);
      } catch (e) {
        print("Legacy Connect Error: $e");
        _isConnected = false;
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      print("Connecting to ${device.name} (BLE: $_useBle)...");
      await _printerManager.connect(
        type: PrinterType.bluetooth,
        model: BluetoothPrinterInput(
          name: device.name,
          address: device.address!,
          isBle: _useBle, // Use the flag
          autoConnect: false, // Turn off lib auto-connect to avoid conflicts
        ),
      );
      _selectedDevice = device;
      _isConnected = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('printer_mac', device.address ?? '');
      await _saveKnownDevice(device);
    } catch (e) {
      print("Error connecting: $e");
      _isConnected = false;
      _selectedDevice = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (kIsWeb) return;
    try {
      if (!kIsWeb &&
          Platform.isAndroid &&
          (await _legacyPrinter.isConnected) == true) {
        await _legacyPrinter.disconnect();
      }
    } catch (e) {}

    try {
      await _printerManager.disconnect(type: PrinterType.bluetooth);
    } catch (e) {
      print("Error disconnecting: $e");
    }
    _selectedDevice = null;
    _isConnected = false;
    notifyListeners();
  }

  Future<bool> _sendBuffered(List<int> bytes) async {
    // BLE standard packet size is often 20 bytes. Classic is higher.
    int chunkSize = _useBle ? 20 : 100;

    for (var i = 0; i < bytes.length; i += chunkSize) {
      var end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      var chunk = bytes.sublist(i, end);

      try {
        final result = await _printerManager.send(
          type: PrinterType.bluetooth,
          bytes: chunk,
        );
        // Note: Some drivers return false but actually print.
        // We will ignore false if useBle is true, unless it throws exception.
        if (result == false) {
          print("Chunk send returned false. Continuing anyway...");
        }

        // Delay is crucial for BLE
        int delay = _useBle ? 50 : 10;
        await Future.delayed(Duration(milliseconds: delay));
      } catch (e) {
        print("Error sending chunk: $e");
        return false;
      }
    }
    return true;
  }

  Future<String?> testPrint() async {
    if (kIsWeb) return "Fitur ini tidak tersedia di Web";
    if (!_isConnected && _selectedDevice == null)
      return "Printer belum dipilih";

    // --- LEGACY MODE ---
    if (_useLegacy && !kIsWeb && Platform.isAndroid) {
      if ((await _legacyPrinter.isConnected) != true)
        return "Printer belum terhubung";
      try {
        // Legacy Print
        _legacyPrinter.printNewLine();
        _legacyPrinter.printCustom(_shopName, 3, 1); // 3=Bold+Center
        _legacyPrinter.printNewLine();
        _legacyPrinter.printCustom("TEST PRINT LEGACY", 1, 1);
        _legacyPrinter.printNewLine();
        _legacyPrinter.printCustom("Mode: BlueThermal (SPP)", 0, 1);
        _legacyPrinter.printNewLine();
        _legacyPrinter.printCustom("----------------", 1, 1);
        _legacyPrinter.printNewLine();
        _legacyPrinter.printNewLine();
        _legacyPrinter.paperCut();
        return null;
      } catch (e) {
        return "Legacy Error: $e";
      }
    }
    // -------------------

    // Auto-reconnect if needed
    if (!_isConnected && _selectedDevice != null) {
      await connect(_selectedDevice!);
    }

    // RAW MODE STRATEGY
    // Basic ESC/POS commands that work on 99% of printers
    List<int> bytes = [
      0x1B, 0x40, // Initialize Printer
      0x0A, // Line Feed
      ...utf8.encode("TEST PRINT OK\n"),
      ...utf8.encode("MODE: ${_useBle ? 'BLE' : 'Classic'}\n"),
      ...utf8.encode("----------------\n"),
      0x0A, 0x0A, 0x0A, // Feed 3 lines
    ];
    if (!_useBle) {
      bytes.addAll([0x1D, 0x56, 0x42, 0x00]); // Cut Paper (Classic only safety)
    }

    try {
      // Attempt 1: Buffered Send
      var result = await _sendBuffered(bytes);

      // Retry Logic if failed
      if (result == false) {
        print("First attempt failed. Reconnecting...");
        if (_selectedDevice != null) {
          // Force disconnect and reconnect
          await _printerManager.disconnect(type: PrinterType.bluetooth);
          await Future.delayed(const Duration(seconds: 2));
          if (!_useLegacy)
            await connect(_selectedDevice!); // Only reconnect if not legacy
          await Future.delayed(const Duration(seconds: 2));

          // Attempt 2
          result = await _sendBuffered(bytes);
        }
      }

      if (result == false) return "Gagal mengirim data. Cek koneksi printer.";

      return null; // Success
    } catch (e) {
      print("Error printing: $e");
      return "Error: $e";
    }
  }

  // DIRECT BLE TEST (Bypassing Library)
  Future<String?> testDirectBleConnection() async {
    if (_selectedDevice == null || _selectedDevice!.address == null)
      return "Pilih printer dulu";

    final String remoteId = _selectedDevice!.address!;
    print("Direct BLE Test to: $remoteId");

    try {
      final device = BluetoothDevice(remoteId: DeviceIdentifier(remoteId));

      // 1. Connect
      await device.connect(autoConnect: false);
      print("Direct Connected");

      // 2. Discover Services
      List<BluetoothService> services = await device.discoverServices();
      print("Found ${services.length} services");

      BluetoothCharacteristic? targetChar;

      // 3. Find Write Characteristic
      for (var service in services) {
        for (var c in service.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            targetChar = c;
            print("Found Write Characteristic: ${c.uuid}");
            break;
          }
        }
        if (targetChar != null) break;
      }

      if (targetChar == null) {
        await device.disconnect();
        return "Tidak ada Characteristic Write";
      }

      // 4. Send Payload
      String testText = "\n\nDIRECT BLE TEST OK\n\n\n";
      List<int> bytes = utf8.encode(testText);

      // Split if needed (20 bytes for safety)
      int chunkSize = 20;
      for (var i = 0; i < bytes.length; i += chunkSize) {
        var end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        var slice = bytes.sublist(i, end);
        await targetChar.write(
          slice,
          withoutResponse: targetChar.properties.writeWithoutResponse,
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 5. Cleanup
      // Don't disconnect immediately to let buffer flush
      await Future.delayed(const Duration(seconds: 2));
      await device.disconnect();

      return null; // Success
    } catch (e) {
      print("Direct BLE Error: $e");
      return "Direct BLE Error: $e";
    }
  }

  // FORCE UPDATE PRINT TRANSACTION LEGACY
  Future<void> printTransaction(
    String transactionId,
    String customerName,
    List<dynamic> items,
    int totalAmount,
  ) async {
    if (kIsWeb || !_isConnected) return;

    // --- LEGACY MODE ---
    // --- LEGACY MODE ---
    if (_useLegacy && !kIsWeb && Platform.isAndroid) {
      try {
        final currency = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );
        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

        _legacyPrinter.printNewLine();

        // Print Logo (Legacy)
        try {
          Uint8List? imgBytes;

          if (_customLogoFile != null && _customLogoFile!.existsSync()) {
            imgBytes = await _customLogoFile!.readAsBytes();
          } else {
            final ByteData data = await rootBundle.load(
              'assets/icon/app_icon.png',
            );
            imgBytes = data.buffer.asUint8List();
          }

          final img.Image? image = img.decodeImage(imgBytes);

          if (image != null) {
            // Resize & Flatten Transparency
            final img.Image processed = _processLogo(image, width: 150);

            final Uint8List resizedBytes = Uint8List.fromList(
              img.encodePng(processed),
            );

            await _legacyPrinter.printImageBytes(resizedBytes);
          }
        } catch (e) {
          print("Legacy Logo Error: $e");
        }

        _legacyPrinter.printNewLine();
        _legacyPrinter.printCustom(_shopName, 4, 1); // 4 = Extra Large
        _legacyPrinter.printCustom(_shopAddress, 0, 1); // 0 = Normal
        _legacyPrinter.printCustom(_shopPhone, 0, 1);
        _legacyPrinter.printNewLine();
        _legacyPrinter.printLeftRight(
          "Tanggal",
          dateFormat.format(DateTime.now()),
          0,
        );
        _legacyPrinter.printLeftRight("Pelanggan", customerName, 0);
        _legacyPrinter.printCustom("--------------------------------", 1, 1);

        for (var item in items) {
          String name = item['name'] ?? item['itemName'] ?? 'Item';
          int qty = item['quantity'] ?? 0;
          int price = item['sellPrice'] ?? 0;

          _legacyPrinter.printCustom(name, 1, 0); // 1 = Left + Bold
          _legacyPrinter.printLeftRight(
            "$qty x ${currency.format(price)}",
            currency.format(qty * price),
            0, // Keep normal to fit
          );
        }

        _legacyPrinter.printCustom("--------------------------------", 1, 1);
        _legacyPrinter.printLeftRight(
          "TOTAL",
          currency.format(totalAmount),
          1, // 1 = Bold (Standard Size)
        );
        _legacyPrinter.printNewLine();
        _legacyPrinter.printCustom(_receiptFooter, 0, 1); // 0 = Normal
        _legacyPrinter.printNewLine();
        _legacyPrinter.printNewLine();
        _legacyPrinter.paperCut();
      } catch (e) {
        print("Legacy Print Error: $e");
      }
      return;
    }
    // -------------------

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      final currency = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      // Header
      bytes += generator.reset();

      // Print Logo
      try {
        Uint8List? imgBytes;

        if (_customLogoFile != null && _customLogoFile!.existsSync()) {
          imgBytes = await _customLogoFile!.readAsBytes();
        } else {
          final ByteData data = await rootBundle.load(
            'assets/icon/app_icon.png',
          );
          imgBytes = data.buffer.asUint8List();
        }

        final img.Image? image = img.decodeImage(imgBytes);

        if (image != null) {
          // Resize & Flatten Transparency
          final img.Image processed = _processLogo(image, width: 120);
          bytes += generator.image(processed, align: PosAlign.center);
          bytes += generator.feed(1);
        }
      } catch (e) {
        print("Error printing logo: $e");
      }

      // ... (Rest of existing logic)
      bytes += generator.text(
        _shopName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size3, // Increased to Size 3
          width: PosTextSize.size3,
        ),
      );
      bytes += generator.text(
        _shopAddress,
        styles: const PosStyles(align: PosAlign.center), // Unbold
      );
      bytes += generator.text(
        _shopPhone,
        styles: const PosStyles(align: PosAlign.center), // Unbold
      );
      bytes += generator.feed(1);

      // Info
      bytes += generator.row([
        PosColumn(text: 'Tanggal', width: 4),
        PosColumn(
          text: dateFormat.format(DateTime.now()),
          width: 8,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Pelanggan', width: 4),
        PosColumn(
          text: customerName,
          width: 8,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.hr();

      // Items
      for (var item in items) {
        // Safe item name
        String name = item['name'] ?? item['itemName'] ?? 'Item';
        bytes += generator.text(name, styles: const PosStyles(bold: true));

        // Qty x Price = Total
        int qty = item['quantity'] ?? 0;
        int price = item['sellPrice'] ?? 0;

        String qtyPrice = "$qty x ${currency.format(price)}";
        String totalItem = currency.format(qty * price);
        bytes += generator.row([
          PosColumn(text: qtyPrice, width: 8),
          PosColumn(
            text: totalItem,
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.hr();

      // Total
      bytes += generator.row([
        PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: currency.format(totalAmount),
          width: 6,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);

      // Footer
      bytes += generator.feed(1);
      bytes += generator.text(
        _receiptFooter,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(2);
      bytes += generator.cut();

      // Use Buffered Send
      await _sendBuffered(bytes);
    } catch (e) {
      print("Error printing transaction: $e");
    }
  }

  // Helper to ensure logo has white background (fixes black box on thermal printers)
  img.Image _processLogo(img.Image source, {required int width}) {
    // 1. Resize
    final img.Image resized = img.copyResize(source, width: width);

    // 2. Create White Background (Opacity 100%)
    final img.Image whiteBg = img.Image(
      width: resized.width,
      height: resized.height,
    );

    // Fill with White (R=255, G=255, B=255)
    // Using explicit loop to be safe across library versions or `fill`.
    // Or just use `fill` with `ColorRgb8`.
    // Let's assume standard API availability.
    img.fill(whiteBg, color: img.ColorRgb8(255, 255, 255));

    // 3. Composite (Source over White)
    img.compositeImage(whiteBg, resized);

    return whiteBg;
  }

  Future<void> resetData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Collections to clear
      final collections = [
        'transactions',
        'stock_moves',
        'debts',
        'return_transactions',
        'notifications',
        'stock_opname',
      ];

      for (var col in collections) {
        bool hasMore = true;
        while (hasMore) {
          // Fetch simple batch
          final snapshot = await FirebaseFirestore.instance
              .collection(col)
              .limit(400) // Safety margin below 500
              .get();

          if (snapshot.docs.isEmpty) {
            hasMore = false;
            continue;
          }

          final batch = FirebaseFirestore.instance.batch();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();

          // If we got fewer than limit, we are likely done, but loop checks isEmpty to be sure
          if (snapshot.docs.length < 400) {
            hasMore = false;
          }
        }
      }

      // Note: We are NOT resetting Item Stock to 0 because that would require re-entry.
      // We only clear history as requested.
    } catch (e) {
      print("Error resetting data: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscriptionBk?.cancel();
    super.dispose();
  }
}
