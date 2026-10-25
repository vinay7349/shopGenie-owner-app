import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DemoBanner extends StatelessWidget {
  final VoidCallback onExitDemo;

  const DemoBanner({super.key, required this.onExitDemo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.amberLight,
        border: Border(
          bottom: BorderSide(color: Color(0xFFFDE68A), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppTheme.amberWarning,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'DEMO MODE ACTIVE • Using isolated sample data',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onExitDemo,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Exit Demo',
              style: TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
