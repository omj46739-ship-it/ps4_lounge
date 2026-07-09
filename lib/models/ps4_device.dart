class Ps4Device {
  final int id;
  final String name;
  final int deviceNumber;
  bool isOccupied;
  DateTime? sessionStart;
  int? sessionDurationMinutes; // المدة المطلوبة بالدقائق (null for open-ended)
  int? remainingSeconds; // الثواني المتبقية (null for open-ended)
  double? hourlyRate; // سعر الساعة لهذه الجلسة
  double? totalCost; // التكلفة الإجمالية
  bool isPaused;
  bool isOpenEnded; // جلسة مفتوحة بدون وقت محدد
  int controllerCount; // عدد اليدات: 2, 3, أو 4

  Ps4Device({
    required this.id,
    required this.name,
    required this.deviceNumber,
    this.isOccupied = false,
    this.sessionStart,
    this.sessionDurationMinutes,
    this.remainingSeconds,
    this.hourlyRate,
    this.totalCost,
    this.isPaused = false,
    this.isOpenEnded = false,
    this.controllerCount = 2,
  });

  /// الحصول على سعر الساعة بناءً على عدد اليدات
  static double getHourlyRateForControllers(int count) {
    switch (count) {
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

  /// الحصول على نص وصف عدد اليدات
  String get controllerLabel {
    switch (controllerCount) {
      case 2:
        return 'يدان';
      case 3:
        return 'ثلاث أيدٍ';
      case 4:
        return 'أربع أيدٍ';
      default:
        return 'يدان';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'deviceNumber': deviceNumber,
      'isOccupied': isOccupied ? 1 : 0,
      'sessionStart': sessionStart?.millisecondsSinceEpoch,
      'sessionDurationMinutes': sessionDurationMinutes,
      'remainingSeconds': remainingSeconds,
      'hourlyRate': hourlyRate,
      'totalCost': totalCost,
      'isPaused': isPaused ? 1 : 0,
      'isOpenEnded': isOpenEnded ? 1 : 0,
      'controllerCount': controllerCount,
    };
  }

  factory Ps4Device.fromMap(Map<String, dynamic> map) {
    return Ps4Device(
      id: map['id'] as int,
      name: map['name'] as String,
      deviceNumber: map['deviceNumber'] as int,
      isOccupied: (map['isOccupied'] as int) == 1,
      sessionStart: map['sessionStart'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['sessionStart'] as int)
          : null,
      sessionDurationMinutes: map['sessionDurationMinutes'] as int?,
      remainingSeconds: map['remainingSeconds'] as int?,
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble(),
      totalCost: (map['totalCost'] as num?)?.toDouble(),
      isPaused: (map['isPaused'] as int) == 1,
      isOpenEnded: (map['isOpenEnded'] as int?) == 1,
      controllerCount: (map['controllerCount'] as int?) ?? 2,
    );
  }

  Ps4Device copyWith({
    int? id,
    String? name,
    int? deviceNumber,
    bool? isOccupied,
    DateTime? sessionStart,
    int? sessionDurationMinutes,
    int? remainingSeconds,
    double? hourlyRate,
    double? totalCost,
    bool? isPaused,
    bool? isOpenEnded,
    int? controllerCount,
  }) {
    return Ps4Device(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceNumber: deviceNumber ?? this.deviceNumber,
      isOccupied: isOccupied ?? this.isOccupied,
      sessionStart: sessionStart ?? this.sessionStart,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      totalCost: totalCost ?? this.totalCost,
      isPaused: isPaused ?? this.isPaused,
      isOpenEnded: isOpenEnded ?? this.isOpenEnded,
      controllerCount: controllerCount ?? this.controllerCount,
    );
  }
}