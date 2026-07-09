import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session_record.dart';

/// محاكاة قاعدة البيانات للويب (حيث لا يعمل sqflite)
class _InMemoryStore {
  final List<SessionRecord> _sessions = [];
  double _hourlyRate = 5000;
  int _nextId = 1;

  Future<int> insertSession(SessionRecord session) async {
    final record = SessionRecord(
      id: _nextId++,
      deviceNumber: session.deviceNumber,
      deviceName: session.deviceName,
      startTime: session.startTime,
      endTime: session.endTime,
      durationMinutes: session.durationMinutes,
      usedMinutes: session.usedMinutes,
      hourlyRate: session.hourlyRate,
      totalCost: session.totalCost,
      refundAmount: session.refundAmount,
      isCompleted: session.isCompleted,
    );
    _sessions.add(record);
    return record.id!;
  }

  List<SessionRecord> getAllSessions() {
    return List.from(_sessions.reversed);
  }

  List<SessionRecord> getSessionsByMonth(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    return _sessions
        .where((s) =>
            s.startTime.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            s.startTime.isBefore(endOfMonth.add(const Duration(seconds: 1))))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  List<SessionRecord> getSessionsByDateRange(DateTime start, DateTime end) {
    return _sessions
        .where((s) =>
            s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
            s.startTime.isBefore(end.add(const Duration(seconds: 1))))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Map<String, double> getMonthlyReport(int year, int month) {
    final sessions = getSessionsByMonth(year, month);
    double totalRevenue = 0;
    double totalRefunds = 0;
    int totalSessions = sessions.length;
    int completedSessions = 0;
    int earlyEndSessions = 0;

    for (var session in sessions) {
      totalRevenue += session.totalCost;
      if (session.refundAmount != null) {
        totalRefunds += session.refundAmount!;
      }
      if (session.isCompleted) {
        completedSessions++;
      } else {
        earlyEndSessions++;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalRefunds': totalRefunds,
      'netRevenue': totalRevenue - totalRefunds,
      'totalSessions': totalSessions.toDouble(),
      'completedSessions': completedSessions.toDouble(),
      'earlyEndSessions': earlyEndSessions.toDouble(),
    };
  }

  double getHourlyRate() => _hourlyRate;
  void setHourlyRate(double rate) => _hourlyRate = rate;
  void deleteAllSessions() => _sessions.clear();
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final _InMemoryStore? _memoryStore = kIsWeb ? _InMemoryStore() : null;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('sqflite is not supported on web');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ps4_lounge.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceNumber INTEGER NOT NULL,
        deviceName TEXT NOT NULL,
        startTime INTEGER NOT NULL,
        endTime INTEGER,
        durationMinutes INTEGER NOT NULL DEFAULT 0,
        usedMinutes INTEGER NOT NULL DEFAULT 0,
        hourlyRate REAL NOT NULL,
        totalCost REAL NOT NULL,
        refundAmount REAL,
        isCompleted INTEGER NOT NULL DEFAULT 1,
        isOpenEnded INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.insert('settings', {'key': 'hourlyRate', 'value': '5000'});
  }

  // ========== عمليات الجلسات ==========

  Future<int> insertSession(SessionRecord session) async {
    if (kIsWeb) {
      return _memoryStore!.insertSession(session);
    }
    final db = await database;
    return await db.insert('sessions', session.toMap());
  }

  Future<List<SessionRecord>> getAllSessions() async {
    if (kIsWeb) {
      return _memoryStore!.getAllSessions();
    }
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'startTime DESC');
    return maps.map((map) => SessionRecord.fromMap(map)).toList();
  }

  Future<List<SessionRecord>> getSessionsByMonth(int year, int month) async {
    if (kIsWeb) {
      return _memoryStore!.getSessionsByMonth(year, month);
    }
    final db = await database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final maps = await db.query(
      'sessions',
      where: 'startTime >= ? AND startTime <= ?',
      whereArgs: [
        startOfMonth.millisecondsSinceEpoch,
        endOfMonth.millisecondsSinceEpoch,
      ],
      orderBy: 'startTime DESC',
    );
    return maps.map((map) => SessionRecord.fromMap(map)).toList();
  }

  Future<List<SessionRecord>> getSessionsByDateRange(
      DateTime start, DateTime end) async {
    if (kIsWeb) {
      return _memoryStore!.getSessionsByDateRange(start, end);
    }
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'startTime >= ? AND startTime <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'startTime DESC',
    );
    return maps.map((map) => SessionRecord.fromMap(map)).toList();
  }

  Future<Map<String, double>> getMonthlyReport(int year, int month) async {
    if (kIsWeb) {
      return _memoryStore!.getMonthlyReport(year, month);
    }
    final sessions = await getSessionsByMonth(year, month);
    double totalRevenue = 0;
    double totalRefunds = 0;
    int totalSessions = sessions.length;
    int completedSessions = 0;
    int earlyEndSessions = 0;

    for (var session in sessions) {
      totalRevenue += session.totalCost;
      if (session.refundAmount != null) {
        totalRefunds += session.refundAmount!;
      }
      if (session.isCompleted) {
        completedSessions++;
      } else {
        earlyEndSessions++;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalRefunds': totalRefunds,
      'netRevenue': totalRevenue - totalRefunds,
      'totalSessions': totalSessions.toDouble(),
      'completedSessions': completedSessions.toDouble(),
      'earlyEndSessions': earlyEndSessions.toDouble(),
    };
  }

  // ========== عمليات الإعدادات ==========

  Future<double> getHourlyRate() async {
    if (kIsWeb) {
      return _memoryStore!.getHourlyRate();
    }
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['hourlyRate'],
    );
    if (result.isNotEmpty) {
      return double.parse(result.first['value'] as String);
    }
    return 5000.0;
  }

  Future<void> setHourlyRate(double rate) async {
    if (kIsWeb) {
      _memoryStore!.setHourlyRate(rate);
      return;
    }
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'hourlyRate', 'value': rate.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAllSessions() async {
    if (kIsWeb) {
      _memoryStore!.deleteAllSessions();
      return;
    }
    final db = await database;
    await db.delete('sessions');
  }
}