import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ActivityTerminal extends StatelessWidget {
  final List<ActivityLogModel> logs;

  const ActivityTerminal({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: AppTheme.cyanAccent, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'LIVE 24/7 AGENT TELEMETRY FEED',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.emeraldGreen.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi, color: AppTheme.emeraldGreen, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'STREAMING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emeraldGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              alignment: Alignment.center,
              child: const Text(
                'No activity logs yet. Onboard a product to start autonomous cycles.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.take(8).length,
              separatorBuilder: (context, index) => const Divider(color: AppTheme.borderSubtle, height: 16),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeFormat.format(log.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildRoleBadge(log.agentRole),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.action,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (log.details != null && log.details!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              log.details!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role) {
      case 'StrategyAgent':
        color = AppTheme.purpleAccent;
        break;
      case 'ProspectorAgent':
        color = AppTheme.cyanAccent;
        break;
      case 'CopywriterAgent':
        color = AppTheme.blueAccent;
        break;
      case 'SdrAgent':
        color = AppTheme.emeraldGreen;
        break;
      default:
        color = AppTheme.amberWarning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        role.replaceAll('Agent', ''),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
