import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';




Widget _buildComingSoon(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppTheme.paleGold,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, size: 48, color: AppTheme.primaryGold),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.darkGold, AppTheme.primaryGold],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.construction_rounded, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('Coming Soon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
