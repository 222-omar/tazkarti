import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final int statusRaw;

  const StatusBadge({super.key, required this.statusRaw});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'قيمة رقمية مباشرة (RAW) من موقع تذكرتي. يتم إشعارك فور تغير هذا الرقم.',
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F3E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFB800).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFFB800),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'الحالة (RAW): $statusRaw',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
