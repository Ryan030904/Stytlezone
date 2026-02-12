import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_config.dart';
import 'theme/app_theme.dart';
import 'utils/theme_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const StyleZoneApp(),
    ),
  );
}

class StyleZoneApp extends StatelessWidget {
  const StyleZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'StyleZone - Fashion Shop',
      theme: ShopTheme.lightTheme,
      darkTheme: ShopTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 220),
      themeAnimationCurve: Curves.easeOutCubic,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
