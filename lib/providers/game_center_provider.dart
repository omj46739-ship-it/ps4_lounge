import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ps4_device.dart';
import '../models/session_record.dart';
import '../database/database_helper.dart';
import '../utils/notification_helper.dart';

class GameCenterProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationHelper _notif = NotificationHelper();

  List<Ps4Device> _devices = [];
  double _hourlyRate = 5000;
  double _globalHourlyRate = 5000; // الساعة الافتراضية للمطور
  Timer? _timer;

  List<Ps4Device> get devices => _devices;
  double get hourlyRate => _hourlyRate;

  // تهيئة الأجهزة الأربعة
  Future<void> initDevices() async {
    _globalHourlyRate = await _db.getHourlyRate();
    _hourlyRate = _globalHourlyRate;
    _devices = List.generate(
      4,
      (index) => Ps4Device(
        id: index + 1,
        name: 'جهاز ${index + 1}',
        deviceNumber: index + 1,
      ),
    );
    // استعادة الجلسات المحفوظة
    await _restoreActiveSessions();
    notifyListeners();
  }

  // ========== الحفظ والاستعادة للتشغيل دون اتصال ==========

  /// حفظ حالة الأجهزة النشطة
  Future<void> _saveActiveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final activeData = _devices
        .where((d) => d.isOccupied)
        .map((d) => {
              'id': d.id,
              'sessionStart': d.sessionStart?.millisecondsSinceEpoch,
              'sessionDurationMinutes': d.sessionDurationMinutes,
              'remainingSeconds': d.remainingSeconds,
              'hourlyRate': d.hourlyRate,
              'totalCost': d.totalCost,
              'isPaused': d.isPaused,
              'isOpenEnded': d.isOpenEnded,
              'controllerCount': d.controllerCount,
            })
        .toList();
    await prefs.setString('active_sessions', jsonEncode(activeData));
  }

  /// استعادة الجلسات المحفوظة عند إعادة تشغيل التطبيق
  Future<void> _restoreActiveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('active_sessions');
    if (saved == null || saved.isEmpty) return;

    try {
      final List<dynamic> sessionsData = jsonDecode(saved);
      for (var data in sessionsData) {
        final deviceId = data['id'] as int;
        final device = _devices.firstWhere(
          (d) => d.id == deviceId,
          orElse: () => Ps4Device(id: deviceId, name: 'جهاز $deviceId', deviceNumber: deviceId),
        );
        device.isOccupied = true;
        device.sessionStart = data['sessionStart'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['sessionStart'] as int)
            : null;
        device.sessionDurationMinutes = data['sessionDurationMinutes'] as int?;
        device.remainingSeconds = data['remainingSeconds'] as int?;
        device.hourlyRate = (data['hourlyRate'] as num?)?.toDouble();
        device.totalCost = (data['totalCost'] as num?)?.toDouble();
        device.isPaused = data['isPaused'] == true;
        device.isOpenEnded = data['isOpenEnded'] == true;
        device.controllerCount = (data['controllerCount'] as int?) ?? 2;
      }
    } catch (e) {
      debugPrint('خطأ في استعادة الجلسات: $e');
    }

    // بدء التايمر إذا كان هناك جلسات نشطة
    if (_devices.any((d) => d.isOccupied)) {
      if (_timer == null || !_timer!.isActive) {
        _startGlobalTimer();
      }
    }
  }

  /// حفظ سجل الجلسات
  Future<void> _saveSessionHistory() async {
    final sessions = await _db.getAllSessions();
    final prefs = await SharedPreferences.getInstance();
    final historyData = sessions.map((s) => s.toJson()).toList();
    await prefs.setString('session_history', jsonEncode(historyData));
  }

  // ========== الأسعار حسب عدد اليدات ==========

  /// الحصول على سعر الساعة بناءً على عدد اليدات
  double getControllerBasedRate(int controllerCount) {
    switch (controllerCount) {
      case 2:
        return 5000;
      case 3:
        return 8000;
      case 4:
        return 12000;
      default:
        return 5000;
    }
  }

  /// حساب التكلفة التقريبية لدقيقة بناءً على عدد اليدات
  double getCostPerMinute(int controllerCount) {
    final rate = getControllerBasedRate(controllerCount);
    return rate / 60.0;
  }

  /// تقريب المبلغ لأقرب 500
  double roundCost(double amount) {
    final rounded = (amount / 500).round() * 500;
    return rounded < 1000 ? 1000.0 : rounded.toDouble();
  }

  // ========== إدارة الجلسات ==========

  /// بدء جلسة لجهاز معين مع عدد اليدات المحدد
  Future<void> startSession({
    required int deviceId,
    required int durationMinutes,
    int controllerCount = 2,
  }) async {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    if (device.isOccupied) return;

    // حساب السعر بناءً على عدد اليدات
    final rate = getControllerBasedRate(controllerCount);

    // حساب التكلفة بناءً على سعر الساعة
    final cost = (rate / 60) * durationMinutes;
    final finalCost = roundCost(cost);

    device.controllerCount = controllerCount;
    device.isOccupied = true;
    device.sessionStart = DateTime.now();
    device.sessionDurationMinutes = durationMinutes;
    device.remainingSeconds = durationMinutes * 60;
    device.hourlyRate = rate;
    device.totalCost = finalCost;
    device.isPaused = false;
    device.isOpenEnded = false;

    notifyListeners();
    await _saveActiveSessions();

    // جدولة إشعار دقيق عبر Android Alarm Manager
    // يعمل حتى عند إغلاق التطبيق
    if (durationMinutes > 0) {
      final endTime = DateTime.now().add(Duration(minutes: durationMinutes));
      try {
        await _notif.scheduleSessionEndNotification(
          deviceId: device.id,
          deviceName: device.name,
          endTime: endTime,
          durationMinutes: durationMinutes,
          totalCost: finalCost,
        );
      } catch (e) {
        debugPrint('فشل جدولة الإشعار: $e');
      }
    }

    // بدء التايمر العام إذا لم يكن شغال
    if (_timer == null || !_timer!.isActive) {
      _startGlobalTimer();
    }
  }

  /// بدء جلسة مفتوحة بدون وقت محدد
  Future<void> startOpenEndedSession({
    required int deviceId,
    int controllerCount = 2,
  }) async {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    if (device.isOccupied) return;

    final rate = getControllerBasedRate(controllerCount);

    device.controllerCount = controllerCount;
    device.isOccupied = true;
    device.sessionStart = DateTime.now();
    device.sessionDurationMinutes = null;
    device.remainingSeconds = null;
    device.hourlyRate = rate;
    device.totalCost = 0; // سيتم احتسابها عند الإنهاء
    device.isPaused = false;
    device.isOpenEnded = true;

    notifyListeners();
    await _saveActiveSessions();

    // بدء التايمر العام إذا لم يكن شغال
    if (_timer == null || !_timer!.isActive) {
      _startGlobalTimer();
    }
  }

  // ========== الوقت والتكلفة ==========

  /// الحصول على مدة الجلسة بصيغة نصية
  String getActiveDurationString(int deviceId) {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    if (device.sessionStart == null) return '--:--:--';
    
    if (device.isOpenEnded || device.remainingSeconds == null) {
      final elapsed = DateTime.now().difference(device.sessionStart!);
      final hours = elapsed.inHours;
      final minutes = elapsed.inMinutes.remainder(60);
      final seconds = elapsed.inSeconds.remainder(60);
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    
    return getRemainingTimeString(deviceId);
  }

  /// الحصول على الوقت المنقضي بالثواني
  int getElapsedSeconds(int deviceId) {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    if (device.sessionStart == null) return 0;
    return DateTime.now().difference(device.sessionStart!).inSeconds;
  }

  /// الحصول على الوقت المنقضي بالدقائق
  int getElapsedMinutes(int deviceId) {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    if (device.sessionStart == null) return 0;
    return DateTime.now().difference(device.sessionStart!).inMinutes;
  }

  /// الحصول على التكلفة الحالية للجلسة المفتوحة
  double getCurrentOpenEndedCost(int deviceId) {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    if (!device.isOpenEnded || device.sessionStart == null) return 0;
    
    final elapsed = DateTime.now().difference(device.sessionStart!);
    final elapsedHours = elapsed.inMinutes / 60.0;
    final rawCost = (device.hourlyRate ?? _globalHourlyRate) * elapsedHours;
    return roundCost(rawCost);
  }

  /// الحصول على التكلفة المتوقعة للجلسة المفتوحة عند الإنهاء الآن
  String getOpenEndedCostBreakdown(int deviceId) {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    if (!device.isOpenEnded || device.sessionStart == null) return '';

    final elapsed = DateTime.now().difference(device.sessionStart!);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final totalMinutes = elapsed.inMinutes;
    final rate = device.hourlyRate ?? _globalHourlyRate;
    final cost = getCurrentOpenEndedCost(deviceId);

    return 'الوقت: ${hours}h ${minutes}m | السعر: $rate ل.س/سا | الإجمالي: ${cost.toInt()} ل.س';
  }

  // ========== التايمر العام ==========

  void _startGlobalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool updated = false;

      for (var device in _devices) {
        if (!device.isOccupied || device.isPaused) continue;
        
        if (device.isOpenEnded) {
          // الجلسات المفتوحة: نحتاجها لتحديث الـ UI فقط
          updated = true;
        } else if (device.remainingSeconds != null) {
          if (device.remainingSeconds! > 0) {
            device.remainingSeconds = device.remainingSeconds! - 1;
            updated = true;

            // إذا انتهى الوقت
            if (device.remainingSeconds! <= 0) {
              device.remainingSeconds = 0;
              _endSessionAutomatically(device);
            }
          }
        }
      }

      if (updated) {
        notifyListeners();
      }
    });
  }

  // ========== إنهاء الجلسات ==========

  /// إنهاء الجلسة تلقائياً عند انتهاء الوقت
  Future<void> _endSessionAutomatically(Ps4Device device) async {
    // حساب الوقت الفعلي المستخدم (قد يختلف عن المدة المدفوعة بسبب الإيقاف المؤقت)
    final usedMinutes = device.sessionDurationMinutes ?? 0;

    final record = SessionRecord(
      deviceNumber: device.deviceNumber,
      deviceName: device.name,
      startTime: device.sessionStart!,
      endTime: DateTime.now(),
      durationMinutes: device.sessionDurationMinutes!,
      usedMinutes: usedMinutes,
      hourlyRate: device.hourlyRate!,
      totalCost: device.totalCost!,
      refundAmount: null,
      isCompleted: true,
    );

    // عرض إشعار بانتهاء الجلسة
    try {
      await _notif.showNotification(
        id: device.id,
        title: '⏰ ${device.name} - انتهى الوقت',
        body: 'انتهت جلسة ${device.name}. المدة: ${device.sessionDurationMinutes} دقيقة | التكلفة: ${device.totalCost!.toInt()} ل.س',
      );
    } catch (e) {
      debugPrint('فشل عرض الإشعار: $e');
    }

    await _db.insertSession(record);
    await _saveActiveSessions();
    await _saveSessionHistory();

    // إذا كانت كل الجلسات انتهت نوقف التايمر
    if (!_devices.any((d) => d.isOccupied)) {
      _timer?.cancel();
      _timer = null;
    }

    notifyListeners();
  }

  /// إنهاء الجلسة مبكراً (يدوياً) - مع احتساب الوقت المنقضي للجلسات المفتوحة
  Future<Map<String, dynamic>> endSessionEarly(int deviceId) async {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    if (!device.isOccupied) return {};

    final now = DateTime.now();
    final usedDuration = now.difference(device.sessionStart!);
    final usedMinutes = usedDuration.inMinutes;
    final usedSeconds = usedDuration.inSeconds;
    final rate = device.hourlyRate ?? _globalHourlyRate;

    if (device.isOpenEnded) {
      // جلسة مفتوحة: حساب التكلفة بناءً على الوقت المنقضي
      final elapsedHours = usedMinutes / 60.0;
      final rawCost = rate * elapsedHours;
      final totalCost = roundCost(rawCost);

      final record = SessionRecord(
        deviceNumber: device.deviceNumber,
        deviceName: device.name,
        startTime: device.sessionStart!,
        endTime: now,
        durationMinutes: 0,
        usedMinutes: usedMinutes < 1 ? 1 : usedMinutes,
        hourlyRate: rate,
        totalCost: totalCost,
        refundAmount: null,
        isCompleted: false,
        isOpenEnded: true,
      );

      await _db.insertSession(record);
      await _saveActiveSessions();
      await _saveSessionHistory();
      _resetDevice(device);

      // إيقاف التايمر إذا لم يعد هناك جلسات نشطة
      if (!_devices.any((d) => d.isOccupied)) {
        _timer?.cancel();
        _timer = null;
      }

      notifyListeners();

      return {
        'deviceName': device.name,
        'totalPaid': totalCost,
        'usedMinutes': usedMinutes < 1 ? 1 : usedMinutes,
        'refundAmount': 0,
        'finalPaid': totalCost,
        'isOpenEnded': true,
        'priceBreakdown': '${rate.toInt()} ل.س/ساعة × ${usedMinutes ~/ 60}h ${usedMinutes % 60}m',
      };
    }

    // جلسة عادية: حساب المبلغ المسترد
    final actualCost = (rate / 3600) * usedSeconds;

    double refundAmount = 0;
    if (device.totalCost! > actualCost) {
      refundAmount = device.totalCost! - actualCost;
      refundAmount = (refundAmount / 500).floor() * 500.0;
      if (refundAmount < 0) refundAmount = 0;
    }

    double finalPaid = device.totalCost! - refundAmount;
    if (finalPaid < 0) finalPaid = 0;

    final record = SessionRecord(
      deviceNumber: device.deviceNumber,
      deviceName: device.name,
      startTime: device.sessionStart!,
      endTime: now,
      durationMinutes: device.sessionDurationMinutes!,
      usedMinutes: usedMinutes < 1 ? 1 : usedMinutes,
      hourlyRate: rate,
      totalCost: device.totalCost!,
      refundAmount: refundAmount,
      isCompleted: false,
    );

    await _db.insertSession(record);
    await _saveActiveSessions();
    await _saveSessionHistory();
    _resetDevice(device);

    // إلغاء الإشعار المعلق
    await _notif.cancelNotification(device.id);

    // إيقاف التايمر إذا لم يعد هناك جلسات نشطة
    if (!_devices.any((d) => d.isOccupied)) {
      _timer?.cancel();
      _timer = null;
    }

    notifyListeners();

    // إشعار بنهاية الجلسة
    try {
      await _notif.showNotification(
        id: device.id + 100,
        title: '✅ تم إنهاء الجلسة - ${device.name}',
        body: 'المدة المستخدمة: $usedMinutes دقيقة | المبلغ النهائي: ${finalPaid.toInt()} ل.س',
      );
    } catch (e) {
      debugPrint('فشل عرض إشعار الإنهاء: $e');
    }

    return {
      'deviceName': device.name,
      'totalPaid': device.totalCost!,
      'usedMinutes': usedMinutes < 1 ? 1 : usedMinutes,
      'refundAmount': refundAmount,
      'finalPaid': finalPaid,
      'controllerCount': device.controllerCount,
      'ratePerHour': rate.toInt(),
    };
  }

  /// إيقاف/تشغيل التايمر مؤقتاً
  void togglePause(int deviceId) {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    if (!device.isOccupied) return;
    device.isPaused = !device.isPaused;
    notifyListeners();
    _saveActiveSessions();
  }

  /// إعادة ضبط الجهاز
  void _resetDevice(Ps4Device device) {
    device.isOccupied = false;
    device.sessionStart = null;
    device.sessionDurationMinutes = null;
    device.remainingSeconds = null;
    device.hourlyRate = null;
    device.totalCost = null;
    device.isPaused = false;
    // لا نعيد تعيين عدد اليدات
  }

  // ========== الإعدادات ==========

  /// تحديث سعر الساعة الافتراضي
  Future<void> updateHourlyRate(double newRate) async {
    _globalHourlyRate = newRate;
    await _db.setHourlyRate(newRate);
    notifyListeners();
  }

  // ========== التقارير ==========

  /// الحصول على التقارير الشهرية
  Future<Map<String, double>> getMonthlyReport(int year, int month) async {
    return await _db.getMonthlyReport(year, month);
  }

  /// الحصول على كل الجلسات
  Future<List<SessionRecord>> getAllSessions() async {
    // محاولة التحميل من التخزين المحلي أولاً
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('session_history');
    if (historyJson != null && historyJson.isNotEmpty) {
      try {
        final List<dynamic> data = jsonDecode(historyJson);
        return data.map((s) => SessionRecord.fromJson(s as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('خطأ في تحميل سجل الجلسات من التخزين: $e');
      }
    }
    return await _db.getAllSessions();
  }

  /// الحصول على جلسات شهر معين
  Future<List<SessionRecord>> getSessionsByMonth(int year, int month) async {
    return await _db.getSessionsByMonth(year, month);
  }

  /// حذف جميع الجلسات من قاعدة البيانات
  Future<void> deleteAllSessions() async {
    await _db.deleteAllSessions();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_history');
  }

  /// إعادة تعيين الكل
  Future<void> resetAll() async {
    _timer?.cancel();
    _timer = null;
    for (var device in _devices) {
      _resetDevice(device);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_sessions');
    notifyListeners();
  }

  // ========== دوال مساعدة ==========

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// الحصول على الوقت المتبقي بصيغة HH:MM:SS
  String getRemainingTimeString(int deviceId) {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    if (device.remainingSeconds == null) return '--:--:--';

    final hours = device.remainingSeconds! ~/ 3600;
    final minutes = (device.remainingSeconds! % 3600) ~/ 60;
    final seconds = device.remainingSeconds! % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}