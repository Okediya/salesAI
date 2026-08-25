import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';
import 'simulate_reply_modal.dart';

class LeadDetailModal extends StatelessWidget {
  final LeadModel lead;

  const LeadDetailModal({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesAiProvider>();
    final leadCampaigns = provider.campaigns.where((c) => c.leadId == lead.id).toList();

    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.purpleAccent.withOpacity(0.2),
                    child: Text(
                      lead.name.isNotEmpty ? lead.name[0] : 'L',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.purpleAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lead.role ?? 'Executive'} at ${lead.company}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildPill(lead.status, _getStatusColor(lead.status)),
                            const SizedBox(width: 8),
                            _buildPill(
                              'Confidence: ${(lead.confidenceScore * 100).toInt()}%',
                              AppTheme.cyanAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppTheme.borderSubtle),
              const SizedBox(height: 16),

              // Prospect Intelligence
              const Text(
                'AI PROSPECT INTELLIGENCE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppTheme.cyanAccent,
                ),
              ),
              const SizedBox(height: 10),
              _buildInfoRow('Pain Points:', lead.painPoints ?? 'Standard operational bottlenecks'),
              const SizedBox(height: 8),
              _buildInfoRow('Personalization Hook:', lead.personalizationHooks ?? 'Recent company expansion'),
              const SizedBox(height: 8),
              _buildInfoRow('Industry & Vertical:', lead.industry ?? 'B2B SaaS / Technology'),

              const SizedBox(height: 20),
              const Divider(color: AppTheme.borderSubtle),
              const SizedBox(height: 16),

              // Multichannel Generated Sequences
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI-GENERATED OUTREACH SEQUENCES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppTheme.purpleAccent,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => SimulateReplyModal(lead: lead),
                      );
                    },
                    icon: const Icon(Icons.forum, size: 16),
                    label: const Text('Simulate Inbound Reply', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (leadCampaigns.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Outreach sequences are currently being crafted by CopywriterAgent...',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                )
              else
                ...leadCampaigns.map((camp) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
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
                            Icon(
                              camp.channel == 'EMAIL' ? Icons.email : Icons.share,
                              size: 16,
                              color: AppTheme.cyanAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${camp.channel} - Step ${camp.sequenceStep}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            _buildPill(camp.status, _getCampColor(camp.status)),
                          ],
                        ),
                        if (camp.subject != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Subject: ${camp.subject}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          camp.body,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'QUALIFIED':
      case 'WON':
        return AppTheme.emeraldGreen;
      case 'ENGAGED':
        return AppTheme.purpleAccent;
      case 'CONTACTED':
        return AppTheme.cyanAccent;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getCampColor(String status) {
    switch (status) {
      case 'SENT':
        return AppTheme.emeraldGreen;
      case 'SCHEDULED':
        return AppTheme.amberWarning;
      default:
        return AppTheme.cyanAccent;
    }
  }
}
