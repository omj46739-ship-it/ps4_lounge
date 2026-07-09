import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_center_provider.dart';
import '../widgets/device_card.dart';
import '../widgets/session_dialog.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'صالة PS4',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF9B59B6)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Color(0xFF9B59B6)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<GameCenterProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: provider.devices.length,
              itemBuilder: (context, index) {
                final device = provider.devices[index];
                return DeviceCard(
                  device: device,
                  onTap: () => _handleDeviceTap(context, device.id),
                  onLongPress: () => _handleLongPress(context, device.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleDeviceTap(BuildContext context, int deviceId) {
    final provider = context.read<GameCenterProvider>();
    final device = provider.devices.firstWhere((d) => d.id == deviceId);

    if (!device.isOccupied) {
      // الجهاز متاح - نفتح نافذة بدء الجلسة
      showDialog(
        context: context,
        builder: (ctx) => SessionDialog(deviceId: deviceId),
      );
    } else {
      // الجهاز مشغول - نظهر خيارات الجلسة
      _showSessionOptions(context, deviceId);
    }
  }

  void _handleLongPress(BuildContext context, int deviceId) {
    final provider = context.read<GameCenterProvider>();
    final device = provider.devices.firstWhere((d) => d.id == deviceId);

    if (device.isOccupied) {
      _showSessionOptions(context, deviceId);
    }
  }

  void _showSessionOptions(BuildContext context, int deviceId) {
    final provider = context.read<GameCenterProvider>();
    final device = provider.devices.firstWhere((d) => d.id == deviceId);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              device.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              device.isOpenEnded
                  ? 'الوقت المنقضي: ${provider.getActiveDurationString(deviceId)}'
                  : 'الوقت المتبقي: ${provider.getRemainingTimeString(deviceId)}',
              style: TextStyle(
                color: device.isOpenEnded ? const Color(0xFF2ECC71) : const Color(0xFF9B59B6),
                fontSize: 16,
              ),
            ),
            if (device.isOpenEnded) ...[
              const SizedBox(height: 4),
              Text(
                'التكلفة الحالية: ${provider.getCurrentOpenEndedCost(deviceId).toInt()} ل.س',
                style: const TextStyle(color: Color(0xFF2ECC71), fontSize: 14),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      provider.togglePause(deviceId);
                    },
                    icon: Icon(
                      device.isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                    ),
                    label: Text(
                      device.isPaused ? 'استئناف' : 'إيقاف مؤقت',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEndSessionConfirmation(context, deviceId);
                    },
                    icon: const Icon(Icons.stop, color: Colors.white),
                    label: const Text(
                      'إنهاء الجلسة',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showEndSessionConfirmation(BuildContext context, int deviceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'إنهاء الجلسة مبكراً؟',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'سيتم حساب المبلغ المسترد تلقائياً.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<GameCenterProvider>();
              final result = await provider.endSessionEarly(deviceId);
              if (context.mounted) {
                _showEndSessionResult(context, result);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('تأكيد الإنتهاء',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEndSessionResult(BuildContext context, Map<String, dynamic> result) {
    if (result.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'تم إنهاء الجلسة',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('الجهاز', result['deviceName']),
            const SizedBox(height: 8),
            _buildResultRow('المبلغ المدفوع', '${result['totalPaid']} ل.س'),
            const SizedBox(height: 8),
            _buildResultRow('الدقائق المستخدمة', '${result['usedMinutes']} دقيقة'),
            const SizedBox(height: 8),
            _buildResultRow(
              'المبلغ المسترد',
              '${result['refundAmount']} ل.س',
              isHighlight: true,
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'المبلغ النهائي',
              '${result['finalPaid']} ل.س',
              isBold: true,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B59B6),
            ),
            child: const Text('حسناً', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value,
      {bool isHighlight = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? const Color(0xFF2ECC71) : Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight
                ? const Color(0xFF2ECC71)
                : isBold
                    ? const Color(0xFF9B59B6)
                    : Colors.white,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}