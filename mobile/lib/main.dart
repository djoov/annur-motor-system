import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'core/app_fonts.dart';
import 'core/services/notification_service.dart';
import 'features/auth/auth_provider.dart';
import 'features/pos/pos_provider.dart';
import 'features/history/history_provider.dart';
import 'features/items/items_provider.dart';
import 'features/categories/categories_provider.dart';
import 'features/customers/customers_provider.dart';
import 'features/suppliers/suppliers_provider.dart';
import 'features/purchases/purchases_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/dashboard/dashboard_provider.dart';
import 'features/reports/daily_sales/daily_sales_provider.dart';
import 'features/debts/debt_provider.dart';
import 'features/auth/user_provider.dart';
import 'features/stock_request/stock_request_provider.dart';
import 'features/returns/return_provider.dart';
import 'features/stock_opname/stock_opname_provider.dart';
import 'features/splash/splash_screen.dart';

import 'package:flutter/foundation.dart'; // for kIsWeb
import 'dart:io'; // for Platform
import 'package:device_preview/device_preview.dart';
import 'package:window_manager/window_manager.dart';

/// Firebase configuration — shared across all platforms
const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyAfY18qUi7pRthM6aYv7Q9JeE3_ANLneY8",
  authDomain: "annur-motor-system.firebaseapp.com",
  projectId: "annur-motor-system",
  storageBucket: "annur-motor-system.firebasestorage.app",
  messagingSenderId: "770182713014",
  appId: "1:770182713014:web:51f3a4d2c45d8635c02017",
  measurementId: "G-HTVYZL3FD2",
  // TODO: After registering iOS app in Firebase Console, replace appId above
  // with the iOS-specific appId and add:
  // iosBundleId: "com.annurmotor.app",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Real font weights before the first frame (see AppFonts).
  await AppFonts.load();
  try {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      await NotificationService().init();
    }
  } catch (e) {
    print("Notification Init Failed: $e");
  }

  // Windows Window Management
  if (!kIsWeb && Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(800, 600),
      center: true,
      title: 'Annur App',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await initializeDateFormatting('id_ID', null);
  try {
    // Use explicit options for all platforms — no need for GoogleService-Info.plist
    // Android still needs google-services.json, but options act as fallback
    if (kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isIOS || Platform.isMacOS))) {
      await Firebase.initializeApp(options: firebaseOptions);
    } else {
      // Android — relies on google-services.json
      await Firebase.initializeApp();
    }
  } catch (e) {
    print("FIREBASE INIT FAILED: $e");
    runApp(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text("Firebase Error"))),
      ),
    );
    return;
  }

  runApp(
    DevicePreview(
      enabled: kIsWeb, // Enable on Web for device frame
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PosProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ItemsProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => CustomersProvider()),
        ChangeNotifierProvider(create: (_) => SuppliersProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => DailySalesProvider()),
        ChangeNotifierProxyProvider<AuthProvider, StockRequestProvider>(
          create: (_) => StockRequestProvider(),
          update: (_, auth, previous) =>
              (previous ?? StockRequestProvider())..update(auth),
        ),
        ChangeNotifierProvider(create: (_) => ReturnProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),

        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => StockOpnameProvider()),
      ],
      child: MaterialApp(
        title: 'Annur App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        scrollBehavior: AppScrollBehavior(),
        // DevicePreview settings - only for web
        useInheritedMediaQuery: kIsWeb,
        locale: kIsWeb ? DevicePreview.locale(context) : null,
        builder: kIsWeb ? DevicePreview.appBuilder : null,
        home: const SplashScreen(),
      ),
    );
  }
}

