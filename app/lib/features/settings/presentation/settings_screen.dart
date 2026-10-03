import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/notification_service.dart';
import 'settings_provider.dart';
import 'widgets/battery_optimization_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _sendTestNotification(BuildContext context) async {
    await NotificationService().showTestNotification(
      title: '🇪🇬 مباراة جديدة لـ منتخب مصر',
      body: 'مصر vs جنوب افريقيا - الأحد 4 أكتوبر 2026 - 09:00 م',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF00E676)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تم إرسال إشعار تجريبي! تفقد شريط الإشعارات أو شاشة القفل.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E2029),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات والاشتراكات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Tracked Teams Subscriptions
          const Text(
            'تنبيهات الفرق المُتابعة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اختر الفرق التي ترغب في استلام إشعار عاجل فور طرح تذاكرها أو تغير حالتها على تذكرتي.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF181A22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2C2F3E)),
            ),
            child: Column(
              children: [
                // Egypt National Team Switch
                SwitchListTile(
                  title: const Row(
                    children: [
                      Text('🇪🇬', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Text(
                        'منتخب مصر',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'تنبيهات المباريات الودية والرسمية وتصفيات كأس العالم وأفريقيا',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                  value: settings.subscribeEgypt,
                  activeThumbColor: const Color(0xFFD32F2F),
                  onChanged: (val) => notifier.toggleEgypt(val),
                ),
                const Divider(color: Color(0xFF2C2F3E), height: 1),

                // Al Ahly Switch
                SwitchListTile(
                  title: const Row(
                    children: [
                      Text('🔴', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Text(
                        'النادي الأهلي',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'تنبيهات الدوري المصري ودوري أبطال أفريقيا وكأس مصر',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                  value: settings.subscribeAhly,
                  activeThumbColor: const Color(0xFFD32F2F),
                  onChanged: (val) => notifier.toggleAhly(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Notifications Test & Diagnostics
          const Text(
            'اختبار الإشعارات وضمان العمل',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Test Notification Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF181A22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2C2F3E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active,
                        color: Color(0xFFFFB800), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'اختبار إشعار شاشة الهاتف',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'اضغط هنا لإرسال إشعار تجريبي فوري لمباراة مصر للتأكد من ظهور الإشعار المنبثق على شاشتك وخروج الصوت والاهتزاز.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC), height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _sendTestNotification(context),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('إرسال إشعار تجريبي الآن'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF242632),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD32F2F)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Battery Optimization Guide Button
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const BatteryOptimizationDialog(),
              );
            },
            icon: const Icon(Icons.battery_charging_full,
                color: Color(0xFF00E676), size: 20),
            label: const Text(
              'دليل هواتف شاومي / أوبو / سامسونج في الخلفية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF2C2F3E)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Legal & Safety Notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF13141B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2C2F3E)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: Color(0xFF00E676), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'نظام تنبيه فقط (Alert-Only)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'هذا التطبيق مخصص للتنبيه فقط ولا يقوم بأي شراء تلقائي أو تخطي لأي حماية أو تسجيل دخول آلي. الشراء يتم مباشرة بواسطة المستخدم من خلال موقع تذكرتي الرسمي.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Visit Official Site
          Center(
            child: TextButton.icon(
              onPressed: () async {
                final uri = Uri.parse(AppConstants.tazkartiUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.link, size: 16, color: Color(0xFFD32F2F)),
              label: const Text(
                'زيارة موقع تذكرتي الرسمي (tazkarti.com)',
                style: TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
