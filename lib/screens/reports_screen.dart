import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/game_center_provider.dart';
import '../models/session_record.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل',
      'مايو', 'يونيو', 'يوليو', 'أغسطس',
      'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'التقارير',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF9B59B6)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF9B59B6),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'الملخص', icon: Icon(Icons.pie_chart)),
            Tab(text: 'الجلسات', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: Column(
        children: [
          // منتقي الشهر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF16213E),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: Color(0xFF9B59B6)),
                  onPressed: () {
                    setState(() {
                      _selectedMonth--;
                      if (_selectedMonth == 0) {
                        _selectedMonth = 12;
                        _selectedYear--;
                      }
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    '${months[_selectedMonth - 1]} $_selectedYear',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: Color(0xFF9B59B6)),
                  onPressed: () {
                    setState(() {
                      _selectedMonth++;
                      if (_selectedMonth == 13) {
                        _selectedMonth = 1;
                        _selectedYear++;
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // المحتوى
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildSessionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return FutureBuilder<Map<String, double>>(
      future: context
          .read<GameCenterProvider>()
          .getMonthlyReport(_selectedYear, _selectedMonth),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF9B59B6)),
          );
        }

        final data = snapshot.data!;
        final formatter = NumberFormat('#,###');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // بطاقات الإحصائيات
              _buildStatCard(
                'إجمالي الإيرادات',
                '${formatter.format(data['totalRevenue']?.toInt() ?? 0)} ل.س',
                Icons.trending_up,
                const Color(0xFF2ECC71),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'إجمالي المسترد',
                '${formatter.format(data['totalRefunds']?.toInt() ?? 0)} ل.س',
                Icons.money_off,
                Colors.redAccent,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'صافي الإيرادات',
                '${formatter.format(data['netRevenue']?.toInt() ?? 0)} ل.س',
                Icons.account_balance_wallet,
                const Color(0xFF9B59B6),
                isLarge: true,
              ),
              const SizedBox(height: 20),

              // إحصائيات الجلسات
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16213E), Color(0xFF1A1A2E)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'إحصائيات الجلسات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSessionStat(
                      'إجمالي الجلسات',
                      '${data['totalSessions']?.toInt() ?? 0}',
                      Icons.sports_esports,
                    ),
                    const Divider(color: Colors.white12),
                    _buildSessionStat(
                      'جلسات مكتملة',
                      '${data['completedSessions']?.toInt() ?? 0}',
                      Icons.check_circle,
                      color: const Color(0xFF2ECC71),
                    ),
                    const Divider(color: Colors.white12),
                    _buildSessionStat(
                      'جلسات منتهية مبكراً',
                      '${data['earlyEndSessions']?.toInt() ?? 0}',
                      Icons.cancel,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color,
      {bool isLarge = false}) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16213E), Color(0xFF1A1A2E)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isLarge ? 32 : 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: isLarge ? 24 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStat(String label, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white54, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    return FutureBuilder<List<SessionRecord>>(
      future: context
          .read<GameCenterProvider>()
          .getSessionsByMonth(_selectedYear, _selectedMonth),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF9B59B6)),
          );
        }

        final sessions = snapshot.data!;
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد جلسات لهذا الشهر',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final dateFormat = DateFormat('MM/dd HH:mm');

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: session.isCompleted
                        ? const Color(0xFF2ECC71).withValues(alpha: 0.2)
                        : Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    session.isCompleted
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: session.isCompleted
                        ? const Color(0xFF2ECC71)
                        : Colors.redAccent,
                  ),
                ),
                title: Text(
                  '${session.deviceName} | ${session.durationMinutes} دقيقة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'البداية: ${dateFormat.format(session.startTime)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    if (session.endTime != null)
                      Text(
                        'النهاية: ${dateFormat.format(session.endTime!)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'المدفوع: ${session.totalCost.toInt()} ل.س',
                          style: const TextStyle(
                            color: Color(0xFF2ECC71),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (session.refundAmount != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            'مسترد: ${session.refundAmount!.toInt()} ل.س',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: Text(
                  session.isCompleted ? 'مكتملة' : 'مبكرة',
                  style: TextStyle(
                    color: session.isCompleted
                        ? const Color(0xFF2ECC71)
                        : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}