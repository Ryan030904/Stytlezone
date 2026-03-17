import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_config.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/product_provider.dart';
import 'providers/promotion_provider.dart';
import 'providers/order_provider.dart';
import 'providers/shipment_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/audit_log_provider.dart';
import 'providers/banner_provider.dart';
import 'providers/brand_provider.dart';
import 'providers/rma_provider.dart';
import 'providers/warehouse_receipt_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/review_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/feedback_provider.dart';
import 'providers/settings_provider.dart';

import 'screens/auth_shell.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => PromotionProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ShipmentProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => AuditLogProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => BrandProvider()),
        ChangeNotifierProvider(create: (_) => RmaProvider()),
        ChangeNotifierProvider(create: (_) => WarehouseReceiptProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'StyleZone Admin',
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US')],
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isAuthenticated) {
              return const DashboardScreen();
            }
            return const AuthShell();
          },
        ),
      ),
    );
  }
}
