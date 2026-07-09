import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_center_provider.dart';

class SessionDialog extends StatefulWidget {
  final int deviceId;

  const SessionDialog({super.key, required this.deviceId});

  @override
  State<SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends State<SessionDialog>
    with SingleTickerProviderStateMixin {
  int _selectedHours = 0;
  int _selectedMinutes = 30;
  int _selectedControllers = 2;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _totalMinutes => (_selectedHours * 60) + _selectedMinutes;

  double get _calculatedCost {
    final provider = context.read<GameCenterProvider>();
    final rate = provider.getControllerBasedRate(_selectedControllers);
    final cost = (rate / 60) * _totalMinutes;
    return provider.roundCost(cost);
  }

  String get _rateLabel {
    switch (_selectedControllers) {
      case 2:
        return 'يدان - 5,000 ل.س/ساعة';
      case 3:
        return 'ثلاث أيدٍ - 8,000 ل.س/ساعة';
      case 4:
        return 'أربع أيدٍ - 12,000 ل.س/ساعة';
      default:
        return 'يدان - 5,000 ل.س/ساعة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          title: Row(
            children: [
              const Icon(Icons.sports_esports,
                  color: Color(0xFF9B59B6), size: 28),
              const SizedBox(width: 10),
              Text(
                'جهاز ${widget.deviceId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر الجلسة المفتوحة
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final provider = context.read<GameCenterProvider>();
                      await provider.startOpenEndedSession(
                        deviceId: widget.deviceId,
                        controllerCount: _selectedControllers,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.timer_off, color: Colors.white),
                    label: const Text(
                      'جلسة مفتوحة (بدون وقت محدد)',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // فاصل
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'أو',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 16),

                // اختيار عدد اليدات
                const Text(
                  'عدد اليدات',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildControllerSelector(),
                const SizedBox(height: 8),
                Text(
                  _rateLabel,
                  style: const TextStyle(
                    color: Color(0xFF9B59B6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // اختيار الساعات
                const Text(
                  'الساعات',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildSelector(
                  value: _selectedHours,
                  min: 0,
                  max: 12,
                  onChanged: (v) => setState(() => _selectedHours = v),
                ),
                const SizedBox(height: 16),

                // اختيار الدقائق
                const Text(
                  'الدقائق',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildSelector(
                  value: _selectedMinutes,
                  min: 0,
                  max: 59,
                  step: 5,
                  onChanged: (v) => setState(() => _selectedMinutes = v),
                ),
                const SizedBox(height: 20),

                // عرض الوقت الإجمالي والتكلفة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الوقت',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedHours > 0 ? '$_selectedHours س ' : ''}$_selectedMinutes د',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'التكلفة',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_calculatedCost.toInt()} ل.س',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: _totalMinutes > 0
                  ? () async {
                      final provider = context.read<GameCenterProvider>();
                      await provider.startSession(
                        deviceId: widget.deviceId,
                        durationMinutes: _totalMinutes,
                        controllerCount: _selectedControllers,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B59B6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'بدء الجلسة',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControllerSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildControllerOption(2, 'يدان', Icons.gamepad),
          const SizedBox(width: 4),
          _buildControllerOption(3, '3 أيدٍ', Icons.gamepad),
          const SizedBox(width: 4),
          _buildControllerOption(4, '4 أيدٍ', Icons.gamepad),
        ],
      ),
    );
  }

  Widget _buildControllerOption(int count, String label, IconData icon) {
    final isSelected = _selectedControllers == count;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedControllers = count),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF9B59B6).withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF9B59B6) : Colors.white54,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelector({
    required int value,
    required int min,
    required int max,
    int step = 1,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: Color(0xFF9B59B6)),
            onPressed: value > min
                ? () => onChanged(value - step)
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36),
          ),
          const SizedBox(width: 8),
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Color(0xFF9B59B6)),
            onPressed: value < max
                ? () => onChanged(value + step)
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36),
          ),
        ],
      ),
    );
  }
}