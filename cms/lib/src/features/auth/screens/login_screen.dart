import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/core/theme.dart';

/// Login screen with inactivity auto-logout support.
/// Uses SESSION persistence (no token stored beyond this browser/app session).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      // Router redirect handles navigation to dashboard
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('invalid-credential') ||
        raw.contains('wrong-password') ||
        raw.contains('user-not-found')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many failed attempts. Please wait a moment and try again.';
    }
    if (raw.contains('network-request-failed')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Sign-in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CmsTheme.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: CmsTheme.brandGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: CmsTheme.accent.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.church,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Church CMS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: CmsTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to your management account',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: CmsTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),
                // Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: CmsTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CmsTheme.border),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email
                        const Text(
                          'Email address',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: CmsTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: const TextStyle(
                            color: CmsTheme.textPrimary,
                            fontFamily: 'Inter',
                          ),
                          validator: (v) =>
                              v == null || !v.contains('@')
                                  ? 'Enter a valid email'
                                  : null,
                          decoration: const InputDecoration(
                            hintText: 'admin@church.org',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: CmsTheme.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Password
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: CmsTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(
                            color: CmsTheme.textPrimary,
                            fontFamily: 'Inter',
                          ),
                          validator: (v) =>
                              v == null || v.length < 6
                                  ? 'Password too short'
                                  : null,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: CmsTheme.textMuted,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: CmsTheme.textMuted,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          onFieldSubmitted: (_) => _signIn(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: CmsTheme.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: CmsTheme.danger.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: CmsTheme.danger,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: CmsTheme.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signIn,
                            child: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Sign In'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Access is restricted to authorized church officers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: CmsTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
