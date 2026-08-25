import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/agent_pulse_card.dart';
import '../widgets/kpi_card.dart';
import '../widgets/activity_terminal.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesAiProvider>();
    final stats = provider.stats;
    final activeProduct = provider.activeProduct;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '24/7 MISSION CONTROL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                      color: AppTheme.cyanAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeProduct != null ? activeProduct.name : 'SalesAI Autonomous Agent',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      if (onNavigate != null) onNavigate!(3); // Product setup
                    },
                    icon: const Icon(Icons.business, size: 16, color: AppTheme.pureWhite),
                    label: const Text('Setup Product'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (onNavigate != null) onNavigate!(0); // Open Chat
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.black),
                    label: const Text('Chat with Bot'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 24/7 Pulse & Telemetry Status Card
          const AgentPulseCard(),
          const SizedBox(height: 20),

          // KPI Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  KpiCard(
                    title: 'Total Discovered',
                    value: '${stats?.totalLeads ?? 0}',
                    icon: Icons.search,
                    accentColor: AppTheme.cyanAccent,
                    subtitle: '${stats?.discoveredLeads ?? 0} in discovery queue',
                  ),
                  KpiCard(
                    title: 'Campaigns Dispatched',
                    value: '${stats?.totalCampaignsSent ?? 0}',
                    icon: Icons.send_rounded,
                    accentColor: AppTheme.blueAccent,
                    subtitle: '${stats?.contactedLeads ?? 0} prospects reached',
                  ),
                  KpiCard(
                    title: 'Qualified Leads',
                    value: '${stats?.qualifiedLeads ?? 0}',
                    icon: Icons.verified_user_rounded,
                    accentColor: AppTheme.purpleAccent,
                    subtitle: '${stats?.engagedLeads ?? 0} actively engaged',
                  ),
                  KpiCard(
                    title: 'Avg Buyer Intent',
                    value: '${stats?.averageIntentScore ?? 0.0}%',
                    icon: Icons.trending_up,
                    accentColor: AppTheme.emeraldGreen,
                    subtitle: 'Autonomous SDR Calibrated',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Active Product DNA & ICP summary banner
          if (activeProduct != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hub, color: AppTheme.purpleAccent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE TARGET ICP: ${activeProduct.targetMarket ?? "B2B Market"}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppTheme.purpleAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeProduct.icpSummary ?? activeProduct.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      if (onNavigate != null) onNavigate!(1);
                    },
                    child: const Text('View DNA', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Live Activity Terminal Feed
          ActivityTerminal(logs: stats?.recentActivities ?? []),
        ],
      ),
    );
  }
}
