import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/game_center_provider.dart';
import 'utils/notification_helper.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة الإشعارات (مع try-catch للويب)
  try {
    final notifHelper = NotificationHelper();
    await notifHelper.init();
    // استعادة الإشعارات المجدولة بعد إعادة تشغيل التطبيق
    await notifHelper.restoreScheduledNotifications();
  } catch (e) {
    debugPrint('Notification init skipped: $e');
  }

  // إبقاء الشاشة مضاءة (فقط على الأجهزة المحمولة)
  if (!kIsWeb) {
    try {
      await _enableWakelock();
    } catch (e) {
      debugPrint('Wakelock init skipped: $e');
    }
  }

  // تعيين اتجاه الشاشة عمودي فقط
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Orientation lock skipped: $e');
  }

  // تعيين ألوان شريط الحالة
  try {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  } catch (e) {
    debugPrint('Status bar style skipped: $e');
  }

  runApp(const PS4LoungeApp());
}

/// تفعيل Wakelock بشكل آمن
Future<void> _enableWakelock() async {
  debugPrint('Wakelock: requires mobile platform');
}

class PS4LoungeApp extends StatelessWidget {
  const PS4LoungeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameCenterProvider()..initDevices(),
      child: MaterialApp(
        title: 'صالة PS4',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9B59B6),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Tajawal',
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF16213E),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
