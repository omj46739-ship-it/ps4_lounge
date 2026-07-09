import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_center_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GameCenterProvider>();
    _rateController =
        TextEditingController(text: provider.hourlyRate.toInt().toString());
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'الإعدادات',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF9B59B6)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // بطاقة أسعار اليدات
            Container(
              width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.price_change,
                          color: Color(0xFF9B59B6), size: 28),
                      SizedBox(width: 10),
                      Text(
                        'أسعار اليدات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPriceRow('يدان (2)', '5,000 ل.س/ساعة', Icons.gamepad),
                  const SizedBox(height: 8),
                  _buildPriceRow('ثلاث أيدٍ (3)', '8,000 ل.س/ساعة', Icons.gamepad),
                  const SizedBox(height: 8),
                  _buildPriceRow('أربع أيدٍ (4)', '12,000 ل.س/ساعة', Icons.gamepad),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // بطاقة سعر الساعة الافتراضي
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.attach_money,
                          color: Color(0xFF9B59B6), size: 28),
                      SizedBox(width: 10),
                      Text(
                        'سعر الساعة الافتراضي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'هذا السعر يستخدم كمرجع فقط. الأسعار الفعلية تحدد حسب عدد اليدات المختارة عند بدء الجلسة.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      suffixText: 'ل.س',
                      suffixStyle: const TextStyle(
                        color: Color(0xFF9B59B6),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF9B59B6),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final rate =
                            double.tryParse(_rateController.text) ?? 5000;
                        if (rate >= 1000) {
                          context
                              .read<GameCenterProvider>()
                              .updateHourlyRate(rate);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم تحديث سعر الساعة إلى $rate ل.س'),
                              backgroundColor: const Color(0xFF2ECC71),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('يجب أن يكون سعر الساعة 1000 ل.س على الأقل'),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B59B6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'حفظ التعديلات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // بطاقة معلومات الإشعارات
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16213E), Color(0xFF1A1A2E)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFF1C40F).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active,
                          color: Color(0xFFF1C40F), size: 28),
                      SizedBox(width: 10),
                      Text(
                        'حالة الإشعارات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Color(0xFF2ECC71), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الإشعارات المجدولة نشطة. سيتم إعلامك عند انتهاء وقت الجلسة حتى لو كان التطبيق مغلقاً.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // نصائح تقنية لأجهزة شاومي
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tips_and_updates,
                          color: Color(0xFFF1C40F), size: 28),
                      SizedBox(width: 10),
                      Text(
                        'نصائح لأجهزة شاومي (MIUI/HyperOS)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTip(
                    '1',
                    'اذهب إلى الإعدادات → التطبيقات → إدارة التطبيقات',
                  ),
                  _buildTip(
                    '2',
                    'ابحث عن تطبيق "PS4 Lounge"',
                  ),
                  _buildTip(
                    '3',
                    'اضغط على "توفير البطارية" ← اختر "بدون قيود"',
                  ),
                  _buildTip(
                    '4',
                    'فعّل "التشغيل في الخلفية" و"البدء التلقائي"',
                  ),
                  _buildTip(
                    '5',
                    'في "الأذونات": فعّل جميع الأذونات خصوصاً الإشعارات',
                  ),
                  _buildTip(
                    '6',
                    'في "تثبيت التطبيق": قم بتثبيت التطبيق في الذاكرة',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1C40F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF1C40F).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFFF1C40F), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'هذه الإعدادات تضمن استمرار عمل التايمر والإشعارات في الخلفية دون إغلاق التطبيق من قبل النظام',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // بطاقة إعادة ضبط البيانات
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16213E), Color(0xFF1A1A2E)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.redAccent, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'إعادة ضبط البيانات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سيتم حذف جميع الجلسات المسجلة وإعادة تعيين الأجهزة',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmReset(context),
                      icon: const Icon(Icons.delete_forever, color: Colors.white),
                      label: const Text(
                        'إعادة ضبط الكل',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9B59B6), size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFF2ECC71),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF9B59B6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'تأكيد إعادة الضبط',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'هل أنت متأكد؟ سيتم حذف جميع بيانات الجلسات نهائياً!',
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
              await context.read<GameCenterProvider>().resetAll();
              await context.read<GameCenterProvider>().deleteAllSessions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تم إعادة ضبط البيانات بنجاح'),
                    backgroundColor: const Color(0xFF2ECC71),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('تأكيد الحذف',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}