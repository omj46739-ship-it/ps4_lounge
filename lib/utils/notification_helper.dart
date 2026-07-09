import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // تهيئة بيانات المناطق الزمنية
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _initialized = true;
  }

  /// معالجة النقر على الإشعار
  void _onNotificationTap(NotificationResponse response) {
    // يمكن استخدامها لفتح شاشة معينة عند النقر
  }

  /// عرض إشعار فوري
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'ps4_lounge_channel',
      'إشعارات الصالة',
      channelDescription: 'إشعارات انتهاء جلسات البلاي ستيشن',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: 'session_$id');
  }

  /// جدولة إشعار دقيق عبر Android Alarm Manager
  /// يستخدم zonedSchedule مع exactAllowWhileIdle لضمان العمل
  /// حتى عند إغلاق التطبيق أو قفل الشاشة
  Future<void> scheduleSessionEndNotification({
    required int deviceId,
    required String deviceName,
    required DateTime endTime,
    required int durationMinutes,
    required double totalCost,
  }) async {
    await _ensureInitialized();
    if (kIsWeb) return;

    final now = DateTime.now();
    if (endTime.isBefore(now) || endTime.difference(now).inSeconds <= 0) {
      return;
    }

    // حفظ معلومات الإشعار في SharedPreferences للاسترجاع عند إعادة التشغيل
    await _saveScheduledNotification(
      deviceId: deviceId,
      deviceName: deviceName,
      endTime: endTime,
      durationMinutes: durationMinutes,
      totalCost: totalCost,
    );

    // إعداد قناة الإشعار للإنذارات الدقيقة
    final androidDetails = AndroidNotificationDetails(
      'ps4_lounge_alarm_channel',
      'إنذارات انتهاء الجلسة',
      channelDescription: 'تنبيهات دقيقة عند انتهاء وقت الجلسة تعمل حتى عند إغلاق التطبيق',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: 'انتهت جلسة $deviceName',
      colorized: true,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'open_app',
          'فتح التطبيق',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // تحويل وقت الإنهاء إلى المنطقة الزمنية المحلية
    final tzEndTime = tz.TZDateTime.from(endTime, tz.local);

    // جدولة الإشعار باستخدام zonedSchedule
    // هذا يستخدم Android AlarmManager داخلياً لدعم العمل دون اتصال
    await _plugin.zonedSchedule(
      deviceId,
      '⏰ تنبيه: انتهى وقت الجلسة للجهاز!',
      'انتهت جلسة $deviceName | المدة: $durationMinutes دقيقة | التكلفة: ${totalCost.toInt()} ل.س',
      tzEndTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'session_end_$deviceId',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// حفظ معلومات الإشعار المجدول لاستعادتها عند إعادة تشغيل الجهاز
  Future<void> _saveScheduledNotification({
    required int deviceId,
    required String deviceName,
    required DateTime endTime,
    required int durationMinutes,
    required double totalCost,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduled = prefs.getString('scheduled_notifications');
    List<dynamic> notifications = [];
    if (scheduled != null && scheduled.isNotEmpty) {
      try {
        notifications = jsonDecode(scheduled);
      } catch (_) {}
    }

    // إزالة أي إشعار سابق لنفس الجهاز
    notifications.removeWhere((n) => n['deviceId'] == deviceId);

    notifications.add({
      'deviceId': deviceId,
      'deviceName': deviceName,
      'endTime': endTime.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'totalCost': totalCost,
    });

    await prefs.setString('scheduled_notifications', jsonEncode(notifications));
  }

  /// استعادة الإشعارات المجدولة بعد إعادة تشغيل التطبيق
  Future<void> restoreScheduledNotifications() async {
    await _ensureInitialized();
    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    final scheduled = prefs.getString('scheduled_notifications');
    if (scheduled == null || scheduled.isEmpty) return;

    try {
      final List<dynamic> notifications = jsonDecode(scheduled);
      final now = DateTime.now();

      for (var notif in notifications) {
        final endTime = DateTime.fromMillisecondsSinceEpoch(
          notif['endTime'] as int,
        );

        // إذا كان وقت الإشعار قد مضى، نتخطاه
        if (endTime.isBefore(now)) continue;

        final deviceId = notif['deviceId'] as int;
        final deviceName = notif['deviceName'] as String;
        final durationMinutes = notif['durationMinutes'] as int;
        final totalCost = (notif['totalCost'] as num).toDouble();

        await scheduleSessionEndNotification(
          deviceId: deviceId,
          deviceName: deviceName,
          endTime: endTime,
          durationMinutes: durationMinutes,
          totalCost: totalCost,
        );
      }
    } catch (e) {
      debugPrint('خطأ في استعادة الإشعارات المجدولة: $e');
    }
  }

  /// إلغاء إشعار مجدول لجهاز معين
  Future<void> cancelScheduledNotification(int deviceId) async {
    await _ensureInitialized();
    if (kIsWeb) return;

    await _plugin.cancel(deviceId);

    // إزالة من القائمة المحفوظة
    final prefs = await SharedPreferences.getInstance();
    final scheduled = prefs.getString('scheduled_notifications');
    if (scheduled != null && scheduled.isNotEmpty) {
      try {
        List<dynamic> notifications = jsonDecode(scheduled);
        notifications.removeWhere((n) => n['deviceId'] == deviceId);
        await prefs.setString(
          'scheduled_notifications',
          jsonEncode(notifications),
        );
      } catch (_) {}
    }
  }

  /// إلغاء جميع الإشعارات المجدولة
  Future<void> cancelAllScheduledNotifications() async {
    await _ensureInitialized();
    if (kIsWeb) return;

    await _plugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scheduled_notifications');
  }

  /// عرض إشعار فوري (للتوافق مع الكود القديم)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int seconds,
  }) async {
    await _ensureInitialized();
    if (kIsWeb) return;

    await showNotification(
      id: id,
      title: title,
      body: body,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }
}