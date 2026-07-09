import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ps4_device.dart';
import '../providers/game_center_provider.dart';

class DeviceCard extends StatelessWidget {
  final Ps4Device device;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: device.isOccupied
                ? [const Color(0xFF9B59B6), const Color(0xFF8E44AD)]
                : [const Color(0xFF16213E), const Color(0xFF1A1A2E)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: device.isOccupied
                ? const Color(0xFF9B59B6).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: device.isOccupied
                  ? const Color(0xFF9B59B6).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة الجهاز
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  device.isOccupied ? Icons.sports_esports : Icons.tv,
                  key: ValueKey(device.isOccupied),
                  size: 50,
                  color: device.isOccupied ? Colors.white : Colors.white54,
                ),
              ),
              const SizedBox(height: 12),

              // اسم الجهاز
              Text(
                device.name,
                style: TextStyle(
                  color: device.isOccupied ? Colors.white : Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // حالة الجهاز
              Consumer<GameCenterProvider>(
                builder: (context, provider, _) {
                  if (!device.isOccupied) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'متاح',
                            style: TextStyle(
                              color: Color(0xFF2ECC71),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      // التايمر مع أنيميشن
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          device.isOpenEnded
                              ? provider.getActiveDurationString(device.id)
                              : provider.getRemainingTimeString(device.id),
                          key: ValueKey(
                              '${device.remainingSeconds}_${device.isPaused}_${device.isOpenEnded}'),
                          style: TextStyle(
                            color: device.isPaused
                                ? Colors.orangeAccent
                                : device.isOpenEnded
                                    ? const Color(0xFF2ECC71)
                                    : Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // عرض عدد اليدات
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B59B6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          device.controllerLabel,
                          style: const TextStyle(
                            color: Color(0xFF9B59B6),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      if (device.isOpenEnded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${provider.getCurrentOpenEndedCost(device.id).toInt()} ل.س',
                            style: const TextStyle(
                              color: Color(0xFF2ECC71),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (device.isPaused)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'متوقف',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}