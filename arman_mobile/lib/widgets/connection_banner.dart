import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/robot_controller.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RobotController>();
    final health = controller.health;

    Color statusColor;
    String statusTitle;
    String statusSub;

    if (!health.isOnline) {
      statusColor = AppTheme.statusRed;
      statusTitle = 'BACKEND OFFLINE';
      statusSub = health.errorMessage ?? 'Cannot reach Spring Boot server';
    } else if (health.isSerialConnected) {
      statusColor = AppTheme.statusGreen;
      statusTitle = 'SYSTEM READY & CONNECTED';
      statusSub = '${health.backend} • Port: ${health.serialPort} @ ${health.baudRate} baud';
    } else if (health.isDryRun) {
      statusColor = AppTheme.statusAmber;
      statusTitle = 'DRY-RUN SIMULATION';
      statusSub = 'Hardware disconnected • Commands will simulate';
    } else {
      statusColor = AppTheme.statusAmber;
      statusTitle = 'SERIAL DISCONNECTED';
      statusSub = 'Spring Boot online • Arduino serial port offline';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusSub,
                  style: const TextStyle(
                    color: AppTheme.textDim,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: AppTheme.primaryCyan),
            tooltip: 'Refresh Health & Serial',
            onPressed: () {
              controller.checkHealth();
            },
          ),
          if (health.isOnline && !health.isSerialConnected)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryCyan,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () {
                controller.reconnectSerial();
              },
              child: const Text('RECONNECT', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
