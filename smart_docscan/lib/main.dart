import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'providers/app_state_provider.dart';
import 'providers/document_provider.dart';
import 'providers/premium_provider.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Mobile Ads SDK
  await MobileAds.instance.initialize();
  
  // Initialize database
  await DatabaseService.instance.initDatabase();
  
  runApp(const SmartDocScanApp());
}

class SmartDocScanApp extends StatelessWidget {
  const SmartDocScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
      ],
      child: MaterialApp(
        title: 'Smart DocScan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
