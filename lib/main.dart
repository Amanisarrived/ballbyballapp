import 'package:ballbyball/providers/auth_provider.dart';
import 'package:ballbyball/providers/banner_provder.dart';
import 'package:ballbyball/providers/highlights_provider.dart';
import 'package:ballbyball/providers/news_provider.dart';
import 'package:ballbyball/providers/product_provider.dart';
import 'package:ballbyball/screens/splashscreen/splash_screen.dart';
import 'package:ballbyball/service/app_analytics.dart';
import 'package:ballbyball/service/notification_prefrence.dart';
import 'package:ballbyball/service/notification_service.dart';
import 'package:ballbyball/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/notificationscreen/notification_prefrence_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider()
        : AndroidPlayIntegrityProvider(),
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  final isGranted = await NotificationPreference.isGranted();
  if (isGranted) {
    await NotificationService().init();
  }
  final showPermissionScreen =
      await NotificationPreference.shouldShowPermissionScreen();

  runApp(MyApp(showPermissionScreen: showPermissionScreen));
}

class MyApp extends StatelessWidget {
  final bool showPermissionScreen;

  const MyApp({super.key, required this.showPermissionScreen});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => HighlightsProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        navigatorObservers: [AppAnalytics.observer],
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: showPermissionScreen
            ? const NotificationPermissionScreen()
            : const SplashScreen(),
      ),
    );
  }
}
