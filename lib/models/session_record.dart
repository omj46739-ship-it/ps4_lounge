class SessionRecord {
  final int? id;
  final int deviceNumber;
  final String deviceName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes; // المدة المدفوعة بالدقائق (0 for open-ended)
  final int usedMinutes; // الدقائق التي استخدمت فعلياً
  final double hourlyRate;
  final double totalCost;
  final double? refundAmount; // المبلغ المسترد إذا انتهت الجلسة مبكراً
  final bool isCompleted; // true: اكتملت المدة, false: انتهت مبكراً
  final bool isOpenEnded; // جلسة مفتوحة بدون وقت محدد

  SessionRecord({
    this.id,
    required this.deviceNumber,
    required this.deviceName,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.usedMinutes,
    required this.hourlyRate,
    required this.totalCost,
    this.refundAmount,
    required this.isCompleted,
    this.isOpenEnded = false,
  });

  double get actualRevenue => totalCost - (refundAmount ?? 0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceNumber': deviceNumber,
      'deviceName': deviceName,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'usedMinutes': usedMinutes,
      'hourlyRate': hourlyRate,
      'totalCost': totalCost,
      'refundAmount': refundAmount,
      'isCompleted': isCompleted ? 1 : 0,
      'isOpenEnded': isOpenEnded ? 1 : 0,
    };
  }

  factory SessionRecord.fromMap(Map<String, dynamic> map) {
    return SessionRecord(
      id: map['id'] as int?,
      deviceNumber: map['deviceNumber'] as int,
      deviceName: map['deviceName'] as String,
      startTime:
          DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int)
          : null,
      durationMinutes: map['durationMinutes'] as int,
      usedMinutes: map['usedMinutes'] as int,
      hourlyRate: (map['hourlyRate'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),
      refundAmount: (map['refundAmount'] as num?)?.toDouble(),
      isCompleted: (map['isCompleted'] as int) == 1,
      isOpenEnded: (map['isOpenEnded'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceNumber': deviceNumber,
      'deviceName': deviceName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'usedMinutes': usedMinutes,
      'hourlyRate': hourlyRate,
      'totalCost': totalCost,
      'refundAmount': refundAmount,
      'isCompleted': isCompleted,
      'isOpenEnded': isOpenEnded,
    };
  }

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'] as int?,
      deviceNumber: json['deviceNumber'] as int,
      deviceName: json['deviceName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      durationMinutes: json['durationMinutes'] as int,
      usedMinutes: json['usedMinutes'] as int,
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      isCompleted: json['isCompleted'] as bool,
      isOpenEnded: json['isOpenEnded'] as bool? ?? false,
    );
  }
}
