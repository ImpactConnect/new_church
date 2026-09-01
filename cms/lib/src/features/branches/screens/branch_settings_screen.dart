import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/permissions.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/core/widgets.dart';
import 'package:cms/src/features/branches/models/branch_model.dart';
import 'package:cms/src/features/communication/models/communication_settings_model.dart';

final _currentBranchProvider = StreamProvider.autoDispose.family<BranchModel?, String>(
  (ref, branchId) => ref.watch(branchRepositoryProvider).watchBranches().map(
    (branches) => branches.firstWhere((b) => b.id == branchId, orElse: () => BranchModel(
      id: branchId,
      name: 'Main Branch',
      address: '',
      pastorInCharge: '',
      phone: '',
      createdAt: DateTime.now(),
    )),
  ),
);

final _commSettingsProvider = FutureProvider.autoDispose<CommunicationSettingsModel>(
  (ref) => ref.watch(communicationRepositoryProvider).getCommunicationSettings(),
);

class BranchSettingsScreen extends ConsumerStatefulWidget {
  const BranchSettingsScreen({super.key});

  @override
  ConsumerState<BranchSettingsScreen> createState() => _BranchSettingsScreenState();
}

class _BranchSettingsScreenState extends ConsumerState<BranchSettingsScreen>
    with SingleTickerProviderStateMixin {
  // Branch form
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _pastorCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;
  bool _initialized = false;

  // Communication settings form
  late final TextEditingController _termiiKeyCtrl;
  late final TextEditingController _termiiSenderCtrl;
  late final TextEditingController _resendKeyCtrl;
  late final TextEditingController _resendEmailCtrl;
  late final TextEditingController _resendNameCtrl;
  late final TextEditingController _fcmKeyCtrl;
  late final TextEditingController _waTemplateCtrl;
  bool _waEnabled = false;
  bool _commSettingsLoaded = false;
  bool _savingComm = false;
  bool _testingSms = false;
  bool _testingEmail = false;
  bool _testingPush = false;

  // Reveal toggles for API key fields
  bool _showTermiiKey = false;
  bool _showResendKey = false;
  bool _showFcmKey = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _pastorCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _termiiKeyCtrl = TextEditingController();
    _termiiSenderCtrl = TextEditingController();
    _resendKeyCtrl = TextEditingController();
    _resendEmailCtrl = TextEditingController();
    _resendNameCtrl = TextEditingController();
    _fcmKeyCtrl = TextEditingController();
    _waTemplateCtrl = TextEditingController();
  }

  void _populate(BranchModel b) {
    if (_initialized) return;
    _nameCtrl.text = b.name;
    _addressCtrl.text = b.address;
    _pastorCtrl.text = b.pastorInCharge;
    _phoneCtrl.text = b.phone;
    _initialized = true;
  }

  void _populateCommSettings(CommunicationSettingsModel s) {
    if (_commSettingsLoaded) return;
    _termiiKeyCtrl.text = s.termiiApiKey;
    _termiiSenderCtrl.text = s.termiiSenderId;
    _resendKeyCtrl.text = s.resendApiKey;
    _resendEmailCtrl.text = s.resendFromEmail;
    _resendNameCtrl.text = s.resendFromName;
    _fcmKeyCtrl.text = s.fcmServerKey;
    _waTemplateCtrl.text = s.whatsappTemplateId;
    _waEnabled = s.whatsappEnabled;
    _commSettingsLoaded = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _pastorCtrl.dispose();
    _phoneCtrl.dispose();
    _termiiKeyCtrl.dispose();
    _termiiSenderCtrl.dispose();
    _resendKeyCtrl.dispose();
    _resendEmailCtrl.dispose();
    _resendNameCtrl.dispose();
    _fcmKeyCtrl.dispose();
    _waTemplateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String branchId, BranchModel current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = current.copyWith(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        pastorInCharge: _pastorCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      await ref.read(branchRepositoryProvider).saveBranch(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Branch settings saved.'), backgroundColor: CmsTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveCommSettings() async {
    setState(() => _savingComm = true);
    try {
      final settings = CommunicationSettingsModel(
        termiiApiKey: _termiiKeyCtrl.text.trim(),
        termiiSenderId: _termiiSenderCtrl.text.trim(),
        resendApiKey: _resendKeyCtrl.text.trim(),
        resendFromEmail: _resendEmailCtrl.text.trim(),
        resendFromName: _resendNameCtrl.text.trim(),
        fcmServerKey: _fcmKeyCtrl.text.trim(),
        whatsappEnabled: _waEnabled,
        whatsappTemplateId: _waTemplateCtrl.text.trim(),
      );
      await ref.read(communicationRepositoryProvider).saveCommunicationSettings(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Communication settings saved.'),
            backgroundColor: CmsTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: CmsTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _savingComm = false);
    }
  }

  Future<void> _testSms() async {
    setState(() => _testingSms = true);
    try {
      final settings = CommunicationSettingsModel(
        termiiApiKey: _termiiKeyCtrl.text.trim(),
        termiiSenderId: _termiiSenderCtrl.text.trim(),
      );
      final svc = ref.read(messagingServiceProvider);
      final result = await svc.sendSms(
        phones: ['08000000000'], // placeholder number
        message: 'Test SMS from Church CMS. Configuration is working!',
        settings: settings,
      );
      if (mounted) {
        _showSnack(result.errorMessage != null
            ? '✗ ${result.errorMessage}'
            : result.sent > 0
                ? '✓ Test SMS sent successfully!'
                : '✗ SMS failed — check your API key and Sender ID.',
            isError: result.errorMessage != null || result.sent == 0);
      }
    } finally {
      if (mounted) setState(() => _testingSms = false);
    }
  }

  Future<void> _testEmail() async {
    final user = ref.read(cmsUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _testingEmail = true);
    try {
      final settings = CommunicationSettingsModel(
        resendApiKey: _resendKeyCtrl.text.trim(),
        resendFromEmail: _resendEmailCtrl.text.trim(),
        resendFromName: _resendNameCtrl.text.trim(),
      );
      final svc = ref.read(messagingServiceProvider);
      final result = await svc.sendEmail(
        addresses: [user.email],
        subject: 'Test Email — Church CMS',
        htmlBody: '<p>This is a test email sent from Church CMS to verify your Resend configuration is working.</p>',
        settings: settings,
      );
      if (mounted) {
        _showSnack(result.errorMessage != null
            ? '✗ ${result.errorMessage}'
            : result.sent > 0
                ? '✓ Test email sent to ${user.email}'
                : '✗ Email failed — check your Resend API key.',
            isError: result.errorMessage != null || result.sent == 0);
      }
    } finally {
      if (mounted) setState(() => _testingEmail = false);
    }
  }

  Future<void> _testPush() async {
    setState(() => _testingPush = true);
    try {
      final settings = CommunicationSettingsModel(fcmServerKey: _fcmKeyCtrl.text.trim());
      final svc = ref.read(messagingServiceProvider);
      // Send to a dummy token — FCM will fail gracefully with InvalidRegistration
      final result = await svc.sendPush(
        fcmTokens: ['test-validation-token'],
        title: 'CMS Test Notification',
        body: 'Push notification configuration is active.',
        settings: settings,
      );
      if (mounted) {
        // Even a failed token means the FCM key was accepted — check statusCode
        _showSnack(
          result.errorMessage != null
              ? '✗ ${result.errorMessage}'
              : '✓ FCM key accepted. Push notifications are configured.',
          isError: result.errorMessage != null,
        );
      }
    } finally {
      if (mounted) setState(() => _testingPush = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
      backgroundColor: isError ? CmsTheme.danger : CmsTheme.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final branchId = ref.watch(currentBranchIdProvider);
    final user = ref.watch(cmsUserProvider).valueOrNull;
    final branchAsync = ref.watch(_currentBranchProvider(branchId));
    final commAsync = ref.watch(_commSettingsProvider);
    final canEdit = user?.can(AppPermission.manageRoles) ?? false;
    final isLeadPastor = user?.roleId == 'leadPastor';

    return Padding(
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CmsPageHeader(
              title: 'Settings',
              subtitle: 'Configure branch details and integrations',
            ),
            const SizedBox(height: 28),

            // ── Branch Info Section ──────────────────────────────────────────
            _SectionHeader(
              icon: Icons.business_outlined,
              title: 'Branch Information',
              subtitle: 'Church name, pastor, and contact details',
            ),
            const SizedBox(height: 16),
            branchAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: CmsTheme.danger)),
              data: (branch) {
                if (branch != null) _populate(branch);
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: CmsCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field('Branch Name', _nameCtrl, enabled: canEdit, required: true),
                          const SizedBox(height: 16),
                          _field('Pastor in Charge', _pastorCtrl, enabled: canEdit),
                          const SizedBox(height: 16),
                          _field('Phone Number', _phoneCtrl, enabled: canEdit, keyboard: TextInputType.phone),
                          const SizedBox(height: 16),
                          _field('Address', _addressCtrl, enabled: canEdit, maxLines: 3),
                          const SizedBox(height: 24),
                          if (canEdit)
                            Align(
                              alignment: Alignment.centerRight,
                              child: CmsButton(
                                label: 'Save Branch Info',
                                icon: Icons.check,
                                loading: _saving,
                                onPressed: () => _save(branchId, branch!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Communication Integrations (Lead Pastor only) ────────────────
            if (isLeadPastor) ...[
              const SizedBox(height: 36),
              _SectionHeader(
                icon: Icons.hub_outlined,
                title: 'Communication Integrations',
                subtitle: 'Configure API keys for SMS, WhatsApp, Email, and Push Notifications',
                iconColor: CmsTheme.info,
              ),
              const SizedBox(height: 16),
              commAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: CmsTheme.accent),
                ),
                error: (e, _) => Text('Error: $e', style: const TextStyle(color: CmsTheme.danger)),
                data: (settings) {
                  _populateCommSettings(settings);
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      children: [
                        // Termii — SMS + WhatsApp
                        _IntegrationCard(
                          icon: Icons.sms_outlined,
                          iconColor: CmsTheme.info,
                          title: 'Termii — SMS & WhatsApp',
                          subtitle: 'Nigerian gateway for bulk SMS and WhatsApp Business messages',
                          statusOk: settings.hasSmsConfig,
                          children: [
                            _apiKeyField(
                              label: 'Termii API Key',
                              ctrl: _termiiKeyCtrl,
                              obscure: !_showTermiiKey,
                              onToggleVisibility: () =>
                                  setState(() => _showTermiiKey = !_showTermiiKey),
                            ),
                            const SizedBox(height: 12),
                            _commField('Sender ID', _termiiSenderCtrl,
                                hint: 'e.g. ChurchName (max 11 chars)'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CmsButton(
                                  label: 'Test SMS',
                                  compact: true,
                                  loading: _testingSms,
                                  onPressed: _termiiKeyCtrl.text.isNotEmpty && _termiiSenderCtrl.text.isNotEmpty
                                      ? _testSms
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // WhatsApp toggle
                        _IntegrationCard(
                          icon: Icons.chat_bubble_outline,
                          iconColor: const Color(0xFF25D366),
                          title: 'WhatsApp Business (via Termii)',
                          subtitle: 'Send bulk WhatsApp messages using Termii\'s WA channel',
                          statusOk: settings.hasWhatsAppConfig,
                          children: [
                            Row(
                              children: [
                                Switch(
                                  value: _waEnabled,
                                  activeColor: const Color(0xFF25D366),
                                  onChanged: (v) => setState(() => _waEnabled = v),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _waEnabled
                                        ? 'WhatsApp channel enabled (uses Termii key above)'
                                        : 'Enable WhatsApp channel',
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: CmsTheme.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            if (_waEnabled) ...[
                              const SizedBox(height: 12),
                              _commField(
                                'WhatsApp Template ID',
                                _waTemplateCtrl,
                                hint: 'Approved Meta template name or ID',
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: CmsTheme.warning.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: CmsTheme.warning.withValues(alpha: 0.25)),
                                ),
                                child: const Text(
                                  '⚠ WhatsApp Business requires a Meta-approved message template for outbound bulk messages. Register your WABA account at business.facebook.com.',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: CmsTheme.warning),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Resend — Email
                        _IntegrationCard(
                          icon: Icons.email_outlined,
                          iconColor: CmsTheme.warning,
                          title: 'Resend — Email',
                          subtitle: 'Transactional and bulk email via Resend API (resend.com)',
                          statusOk: settings.hasEmailConfig,
                          children: [
                            _apiKeyField(
                              label: 'Resend API Key',
                              ctrl: _resendKeyCtrl,
                              obscure: !_showResendKey,
                              onToggleVisibility: () =>
                                  setState(() => _showResendKey = !_showResendKey),
                            ),
                            const SizedBox(height: 12),
                            _commField('From Email Address', _resendEmailCtrl,
                                hint: 'e.g. no-reply@yourchurch.com'),
                            const SizedBox(height: 12),
                            _commField('From Name', _resendNameCtrl,
                                hint: 'e.g. Grace Covenant Church'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CmsButton(
                                  label: 'Send Test Email',
                                  compact: true,
                                  loading: _testingEmail,
                                  onPressed: _resendKeyCtrl.text.isNotEmpty && _resendEmailCtrl.text.isNotEmpty
                                      ? _testEmail
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // FCM — Push Notifications
                        _IntegrationCard(
                          icon: Icons.notifications_outlined,
                          iconColor: CmsTheme.accent,
                          title: 'Firebase Cloud Messaging — Push',
                          subtitle: 'Send push notifications to the mobile app (FCM Server Key)',
                          statusOk: settings.hasPushConfig,
                          children: [
                            _apiKeyField(
                              label: 'FCM Server Key',
                              ctrl: _fcmKeyCtrl,
                              obscure: !_showFcmKey,
                              onToggleVisibility: () =>
                                  setState(() => _showFcmKey = !_showFcmKey),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: CmsTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: CmsTheme.border),
                              ),
                              child: const Text(
                                'Find this in Firebase Console → Project Settings → Cloud Messaging → Server key. This must match the Firebase project used by the mobile app.',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: CmsTheme.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CmsButton(
                                  label: 'Validate FCM Key',
                                  compact: true,
                                  loading: _testingPush,
                                  onPressed: _fcmKeyCtrl.text.isNotEmpty ? _testPush : null,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CmsButton(
                            label: 'Save Communication Settings',
                            icon: Icons.check,
                            loading: _savingComm,
                            onPressed: _saveCommSettings,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool enabled = true,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CmsTheme.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboard,
          style: const TextStyle(color: CmsTheme.textPrimary, fontFamily: 'Inter'),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  Widget _commField(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CmsTheme.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(
              color: CmsTheme.textPrimary, fontFamily: 'Inter', fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _apiKeyField({
    required String label,
    required TextEditingController ctrl,
    required bool obscure,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CmsTheme.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(
              color: CmsTheme.textPrimary, fontFamily: 'Inter', fontSize: 13),
          decoration: InputDecoration(
            hintText: obscure ? '••••••••••••••••••••••••' : 'Paste API key here…',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: CmsTheme.textMuted,
              ),
              onPressed: onToggleVisibility,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Reusable UI Components ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = CmsTheme.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CmsTheme.textPrimary),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: CmsTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.statusOk,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool statusOk;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CmsTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmsTheme.border),
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: CmsTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CmsTheme.textPrimary),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: CmsTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusOk
                        ? CmsTheme.success.withValues(alpha: 0.12)
                        : CmsTheme.textMuted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusOk
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        size: 12,
                        color: statusOk ? CmsTheme.success : CmsTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusOk ? 'Configured' : 'Not set',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusOk ? CmsTheme.success : CmsTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Card body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
