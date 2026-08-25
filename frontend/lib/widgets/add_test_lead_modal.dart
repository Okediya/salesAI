import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_ai_provider.dart';
import '../theme/app_theme.dart';
import 'lead_detail_modal.dart';

class AddTestLeadModal extends StatefulWidget {
  const AddTestLeadModal({super.key});

  @override
  State<AddTestLeadModal> createState() => _AddTestLeadModalState();
}

class _AddTestLeadModalState extends State<AddTestLeadModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _roleController = TextEditingController(text: 'Founder & CEO');
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _painPointsController = TextEditingController();
  final _hookController = TextEditingController();

  bool _autoGenerate = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _painPointsController.dispose();
    _hookController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = context.read<SalesAiProvider>();
      final lead = await provider.createCustomLead({
        'name': _nameController.text.trim(),
        'company': _companyController.text.trim(),
        'role': _roleController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'pain_points': _painPointsController.text.trim().isEmpty
            ? 'Scaling customer acquisition and converting cold leads'
            : _painPointsController.text.trim(),
        'personalization_hooks': _hookController.text.trim().isEmpty
            ? 'Actively expanding operations this quarter'
            : _hookController.text.trim(),
        'auto_generate_campaign': _autoGenerate,
      });

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.emeraldGreen,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Test Lead "${lead.name}" added! AI is crafting personalized outreach.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      // Open the lead detail modal immediately to inspect generated copy and dispatch
      showDialog(
        context: context,
        builder: (_) => LeadDetailModal(lead: lead),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.roseDanger,
            content: Text('Failed to add lead: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.cyanAccent, AppTheme.blueAccent],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_add_alt_1, color: Colors.black, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Test Lead (You)',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Test how SalesAI reaches out to you via Email & WhatsApp',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: AppTheme.borderSubtle, height: 1),
                const SizedBox(height: 20),

                // Name & Company row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nameController,
                        label: 'Full Name *',
                        hint: 'e.g. Ayobami',
                        icon: Icons.person_outline,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _companyController,
                        label: 'Company Name *',
                        hint: 'e.g. Apex Innovations',
                        icon: Icons.business,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Company is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Role
                _buildTextField(
                  controller: _roleController,
                  label: 'Job Title / Role',
                  hint: 'e.g. Founder & CEO / Head of Growth',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),

                // Email & Phone Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'you@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneController,
                        label: 'WhatsApp / Phone',
                        hint: '+2348012345678',
                        icon: Icons.phone_android,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pain Points
                _buildTextField(
                  controller: _painPointsController,
                  label: 'Core Pain Point (What you struggle with)',
                  hint: 'e.g. Scaling outbound prospecting without hiring more SDRs',
                  icon: Icons.bolt,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Personalization Context
                _buildTextField(
                  controller: _hookController,
                  label: 'Context / Hook for AI',
                  hint: 'e.g. Recently launched new beta, expanding sales in Q3',
                  icon: Icons.psychology,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Auto generate checkbox
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _autoGenerate,
                        activeColor: AppTheme.cyanAccent,
                        checkColor: Colors.black,
                        onChanged: (val) => setState(() => _autoGenerate = val ?? true),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Immediately run Gemini Copywriter to generate 3-step outreach',
                          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Row(
                              children: [
                                Icon(Icons.rocket_launch, size: 18, color: Colors.black),
                                SizedBox(width: 8),
                                Text(
                                  'Generate & Test Outreach',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            prefixIcon: Icon(icon, color: AppTheme.cyanAccent, size: 20),
            filled: true,
            fillColor: AppTheme.bgSecondary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.cyanAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
