import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';

class BatchUploadModal extends StatefulWidget {
  const BatchUploadModal({super.key});

  @override
  State<BatchUploadModal> createState() => _BatchUploadModalState();
}

class _BatchUploadModalState extends State<BatchUploadModal> {
  final TextEditingController _contactsController = TextEditingController();
  bool _isImporting = false;

  final String _samplePlaceholder = """@alex_founder
@sarah_growth
elena@cloudscale.io
+14155552671
michael@finopsai.com""";

  @override
  void dispose() {
    _contactsController.dispose();
    super.dispose();
  }

  Future<void> _importContacts() async {
    final text = _contactsController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste or type contact handles/emails first.')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final provider = context.read<SalesAiProvider>();
      final result = await provider.batchImportLeads(text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.bgCardHover,
            content: Text(result['message'] ?? 'Contacts imported successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contacts_outlined, size: 20, color: AppTheme.pureWhite),
                const SizedBox(width: 10),
                const Text(
                  'IMPORT CUSTOMER & LEAD LIST',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Paste a list of Telegram handles (@username), email addresses, or phone numbers separated by newlines or commas. SalesAI will automatically track them and begin scheduled follow-ups and product updates.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactsController,
              maxLines: 8,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: _samplePlaceholder,
                labelText: 'Contact List',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _contactsController.text = _samplePlaceholder;
                  },
                  child: const Text('Insert Sample List', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isImporting ? null : _importContacts,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.check, size: 16, color: Colors.black),
                  label: Text(_isImporting ? 'Importing...' : 'Start Automated Follow-up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
