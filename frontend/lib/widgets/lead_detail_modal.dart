import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';
import 'simulate_reply_modal.dart';

class LeadDetailModal extends StatelessWidget {
  final LeadModel lead;

  const LeadDetailModal({super.key, required this.lead});

  Future<void> _launchActionUrl(BuildContext context, String? urlString, String channel) async {
    if (urlString == null || urlString.isEmpty) return;
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.amberWarning,
            content: Text('Could not automatically launch $channel. Please check browser permissions.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.roseDanger,
            content: Text('Error launching $channel: $e'),
          ),
        );
      }
    }
  }

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
                'AI PROSPECT INTELLIGENCE & CONTACT INFO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppTheme.cyanAccent,
                ),
              ),
              const SizedBox(height: 10),
              if (lead.email != null && lead.email!.isNotEmpty) ...[
                _buildInfoRow('Email Address:', lead.email!),
                const SizedBox(height: 8),
              ],
              if (lead.phoneNumber != null && lead.phoneNumber!.isNotEmpty) ...[
                _buildInfoRow('WhatsApp / Phone:', lead.phoneNumber!),
                const SizedBox(height: 8),
              ],
              if (lead.telegramHandle != null && lead.telegramHandle!.isNotEmpty) ...[
                _buildInfoRow('Telegram Handle:', '@${lead.telegramHandle!.replaceAll('@', '')}'),
                const SizedBox(height: 8),
              ],
              _buildInfoRow('Pain Points:', lead.painPoints ?? 'Standard operational bottlenecks'),
              const SizedBox(height: 8),
              _buildInfoRow('Personalization Hook:', lead.personalizationHooks ?? 'Recent company expansion'),
              const SizedBox(height: 8),
              _buildInfoRow('Industry & Vertical:', lead.industry ?? 'B2B SaaS / Technology'),

              const SizedBox(height: 20),
              // Live Outreach Action Buttons
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.send_rounded, size: 16, color: AppTheme.cyanAccent),
                        SizedBox(width: 8),
                        Text(
                          'LIVE MULTI-CHANNEL DISPATCH',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.cyanAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trigger real outreach delivery to this lead via Telegram, Email, or WhatsApp:',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF29B6F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: () async {
                            try {
                              final res = await provider.dispatchTelegram(lead.id);
                              final actionUrl = res['action_url'] as String?;
                              if (!context.mounted) return;
                              if (actionUrl != null) {
                                await _launchActionUrl(context, actionUrl, 'Telegram');
                              }
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF0288D1),
                                  content: Text(res['message'] ?? 'Telegram launched.'),
                                  action: actionUrl != null
                                      ? SnackBarAction(
                                          label: 'OPEN TG',
                                          textColor: Colors.white,
                                          onPressed: () => _launchActionUrl(context, actionUrl, 'Telegram'),
                                        )
                                      : null,
                                ),
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.roseDanger,
                                    content: Text('Telegram error: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                          label: const Text('Send Telegram', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: () async {
                            try {
                              final res = await provider.dispatchEmail(lead.id);
                              final actionUrl = res['action_url'] as String?;
                              if (!context.mounted) return;
                              if (actionUrl != null && actionUrl.startsWith('mailto:')) {
                                await _launchActionUrl(context, actionUrl, 'Email Client');
                              }
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: res['success'] == true ? AppTheme.emeraldGreen : AppTheme.amberWarning,
                                  content: Text(res['message'] ?? 'Email processed successfully.'),
                                  action: actionUrl != null
                                      ? SnackBarAction(
                                          label: 'OPEN MAIL',
                                          textColor: Colors.white,
                                          onPressed: () => _launchActionUrl(context, actionUrl, 'Email Client'),
                                        )
                                      : null,
                                ),
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.roseDanger,
                                    content: Text('Email dispatch error: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.email, size: 16, color: Colors.black),
                          label: const Text('Send Email (Inbox)', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emeraldGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: () async {
                            try {
                              final res = await provider.dispatchWhatsApp(lead.id);
                              final actionUrl = res['action_url'] as String?;
                              if (!context.mounted) return;
                              if (actionUrl != null) {
                                await _launchActionUrl(context, actionUrl, 'WhatsApp');
                              }
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppTheme.emeraldGreen,
                                  content: Text(res['message'] ?? 'WhatsApp opened.'),
                                  action: actionUrl != null
                                      ? SnackBarAction(
                                          label: 'RE-OPEN WA',
                                          textColor: Colors.white,
                                          onPressed: () => _launchActionUrl(context, actionUrl, 'WhatsApp'),
                                        )
                                      : null,
                                ),
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.roseDanger,
                                    content: Text('WhatsApp error: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.chat, size: 16, color: Colors.white),
                          label: const Text('Send to WhatsApp', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
                    label: const Text('Test SDR Conversation', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.purpleAccent,
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
                              camp.channel == 'EMAIL'
                                  ? Icons.email
                                  : camp.channel == 'WHATSAPP'
                                      ? Icons.chat
                                      : camp.channel == 'TELEGRAM'
                                          ? Icons.send_rounded
                                          : Icons.share,
                              size: 16,
                              color: camp.channel == 'WHATSAPP'
                                  ? AppTheme.emeraldGreen
                                  : camp.channel == 'TELEGRAM'
                                      ? const Color(0xFF29B6F6)
                                      : AppTheme.cyanAccent,
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
