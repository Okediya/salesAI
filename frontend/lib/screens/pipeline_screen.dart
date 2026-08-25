import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/lead_detail_modal.dart';
import '../widgets/add_test_lead_modal.dart';

class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key});

  final List<Map<String, dynamic>> _columns = const [
    {'status': 'DISCOVERED', 'title': 'Discovered', 'color': AppTheme.textSecondary},
    {'status': 'CONTACTED', 'title': 'Contacted', 'color': AppTheme.cyanAccent},
    {'status': 'ENGAGED', 'title': 'Engaged', 'color': AppTheme.blueAccent},
    {'status': 'QUALIFIED', 'title': 'Qualified', 'color': AppTheme.purpleAccent},
    {'status': 'WON', 'title': 'Won / Closed', 'color': AppTheme.emeraldGreen},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesAiProvider>();
    final leads = provider.leads;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AUTONOMOUS CONVERSION FUNNEL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppTheme.purpleAccent,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sales Pipeline (Kanban)',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cyanAccent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddTestLeadModal(),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1, size: 16, color: Colors.black),
                    label: const Text('Add Test Lead (You)', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderSubtle),
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    onPressed: () => provider.triggerManualCycle(),
                    icon: const Icon(Icons.bolt, size: 16, color: AppTheme.cyanAccent),
                    label: const Text('Prospect More Leads'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Kanban Columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _columns.map((col) {
                final status = col['status'] as String;
                final title = col['title'] as String;
                final color = col['color'] as Color;
                final columnLeads = leads.where((l) => l.status == status).toList();

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSecondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${columnLeads.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppTheme.borderSubtle, height: 1),
                        const SizedBox(height: 12),
                        Expanded(
                          child: columnLeads.isEmpty
                              ? Center(
                                  child: Text(
                                    'No leads in $title',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: columnLeads.length,
                                  itemBuilder: (context, index) {
                                    final lead = columnLeads[index];
                                    return _buildLeadCard(context, lead, color);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(BuildContext context, LeadModel lead, Color stageColor) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => LeadDetailModal(lead: lead),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.cyanAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(lead.confidenceScore * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.cyanAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${lead.role ?? "Lead"} • ${lead.company}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (lead.painPoints != null) ...[
              const SizedBox(height: 6),
              Text(
                lead.painPoints!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (lead.email != null && lead.email!.isNotEmpty) ...[
                  const Icon(Icons.email, size: 12, color: AppTheme.cyanAccent),
                  const SizedBox(width: 4),
                  const Text('Email', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  const SizedBox(width: 8),
                ],
                if (lead.phoneNumber != null && lead.phoneNumber!.isNotEmpty) ...[
                  const Icon(Icons.chat, size: 12, color: AppTheme.emeraldGreen),
                  const SizedBox(width: 4),
                  const Text('WA', style: TextStyle(fontSize: 10, color: AppTheme.emeraldGreen)),
                  const SizedBox(width: 8),
                ],
                if (lead.telegramHandle != null && lead.telegramHandle!.isNotEmpty) ...[
                  const Icon(Icons.send_rounded, size: 12, color: Color(0xFF29B6F6)),
                  const SizedBox(width: 4),
                  const Text('TG', style: TextStyle(fontSize: 10, color: Color(0xFF29B6F6))),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
