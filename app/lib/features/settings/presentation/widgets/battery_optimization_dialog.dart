import 'package:flutter/material.dart';

class BatteryOptimizationDialog extends StatelessWidget {
  const BatteryOptimizationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF181A22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2C2F3E)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.battery_alert,
                        color: Color(0xFFFFB800), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ضمان وصول الإشعارات في الخلفية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'بعض أجهزة أندرويد (مثل شاومي، أوبو، ريلمي، هواوي، سامسونج) تقوم بإغلاق التطبيقات في الخلفية لتوفير البطارية، مما قد يؤخر وصول إشعار التذاكر. لضمان وصول الإشعار في ثوانٍ معدودة على شاشة القفل، يُرجى تفعيل الخطوات التالية:',
                style: TextStyle(fontSize: 13, color: Color(0xFFCCCCCC), height: 1.5),
              ),
              const SizedBox(height: 16),
              _buildStep(
                icon: Icons.play_circle_outline,
                title: '1. التشغيل التلقائي (Autostart)',
                description:
                    'توجه إلى إعدادات الهاتف > التطبيقات > تنبيهات تذكرتي > تفعيل "التشغيل التلقائي".',
              ),
              const SizedBox(height: 12),
              _buildStep(
                icon: Icons.battery_charging_full,
                title: '2. توفير شحن البطارية (Battery Saver)',
                description:
                    'اضبط قيود البطارية للتطبيق على "بلا قيود" (No restrictions) لكي لا يقوم النظام بتعليق الإشعارات.',
              ),
              const SizedBox(height: 12),
              _buildStep(
                icon: Icons.notification_important_outlined,
                title: '3. إشعارات شاشة القفل والمنبثقة',
                description:
                    'تأكد من تفعيل "إظهار الإشعارات المنبثقة" و"إظهار المحتوى على شاشة القفل" لقناة "تنبيهات تذاكر المباريات العاجلة".',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                  ),
                  child: const Text('فهمت ذلك، تم الضبط'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF13141B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2F3E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00E676), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
