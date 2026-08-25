import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';

class CampaignsScreen extends StatelessWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesAiProvider>();
    final campaigns = provider.campaigns;
    final leads = provider.leads;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MULTICHANNEL OUTREACH ENGINE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.cyanAccent,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Campaign Studio',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: campaigns.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mark_email_unread, size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 14),
                          const Text(
                            'No Outreach Campaigns Generated Yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Onboard your startup or trigger autonomous prospecting to generate personalized sequences.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: () => provider.triggerManualCycle(),
                            icon: const Icon(Icons.bolt),
                            label: const Text('Trigger CopywriterAgent Cycle'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {
                      final camp = campaigns[index];
                      final lead = leads.firstWhere(
                        (l) => l.id == camp.leadId,
                        orElse: () => LeadModel(
                          id: 0,
                          productId: 0,
                          name: 'Target Prospect',
                          company: 'Target Company',
                          confidenceScore: 0.9,
                          status: 'DISCOVERED',
                          isApproved: true,
                          createdAt: DateTime.now(),
                        ),
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: camp.channel == 'EMAIL'
                                        ? AppTheme.cyanAccent.withOpacity(0.12)
                                        : AppTheme.purpleAccent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    camp.channel == 'EMAIL' ? Icons.email : Icons.share,
                                    color: camp.channel == 'EMAIL' ? AppTheme.cyanAccent : AppTheme.purpleAccent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${camp.channel} • Sequence Step ${camp.sequenceStep}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Prospect: ${lead.name} (${lead.role ?? "Decision Maker"} at ${lead.company})',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: camp.status == 'SENT'
                                        ? AppTheme.emeraldGreen.withOpacity(0.15)
                                        : AppTheme.amberWarning.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    camp.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: camp.status == 'SENT' ? AppTheme.emeraldGreen : AppTheme.amberWarning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (camp.subject != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Subject: ${camp.subject}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSecondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                camp.body,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
