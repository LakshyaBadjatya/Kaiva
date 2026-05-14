import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/firebase/firebase_service.dart';
import '../../core/theme/kaiva_colors.dart';
import '../../core/theme/kaiva_text_styles.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      final svc = FirebaseService.instance;
      if (_tabs.index == 0) {
        await svc.signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        await svc.registerWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _nameCtrl.text.trim(),
        );
      }
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseService.instance.signInWithGoogle();
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (raw.contains('email-already-in-use')) return 'Email already in use.';
    if (raw.contains('weak-password')) return 'Password must be at least 6 characters.';
    if (raw.contains('cancelled')) return 'Sign-in cancelled.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('Kaiva', style: KaivaTextStyles.headlineLarge),
              const SizedBox(height: 4),
              Text('Your music, everywhere.', style: KaivaTextStyles.bodyMedium.copyWith(color: KaivaColors.textMuted)),
              const SizedBox(height: 40),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: KaivaColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: KaivaColors.accentPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: KaivaColors.textOnAccent,
                  unselectedLabelColor: KaivaColors.textMuted,
                  labelStyle: KaivaTextStyles.labelLarge,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Register'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name field (register only)
                    AnimatedBuilder(
                      animation: _tabs,
                      builder: (_, __) => _tabs.index == 1
                          ? Column(children: [
                              _field(_nameCtrl, 'Display name', Icons.person_outline_rounded,
                                  validator: (v) => (v?.isEmpty ?? true) ? 'Enter your name' : null),
                              const SizedBox(height: 16),
                            ])
                          : const SizedBox.shrink(),
                    ),

                    _field(_emailCtrl, 'Email', Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v?.contains('@') ?? false) ? null : 'Enter a valid email'),
                    const SizedBox(height: 16),

                    _field(_passwordCtrl, 'Password', Icons.lock_outline_rounded,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: KaivaColors.textMuted, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Min 6 characters'),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
                    ],

                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: KaivaColors.accentPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : AnimatedBuilder(
                                animation: _tabs,
                                builder: (_, __) => Text(
                                  _tabs.index == 0 ? 'Sign In' : 'Create Account',
                                  style: KaivaTextStyles.labelLarge.copyWith(color: KaivaColors.textOnAccent),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider
                    const Row(children: [
                      Expanded(child: Divider(color: KaivaColors.borderSubtle)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: KaivaTextStyles.bodySmall),
                      ),
                      Expanded(child: Divider(color: KaivaColors.borderSubtle)),
                    ]),

                    const SizedBox(height: 16),

                    // Google sign-in
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _googleSignIn,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: KaivaColors.borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 18, height: 18,
                          errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, size: 22),
                        ),
                        label: Text('Continue with Google',
                            style: KaivaTextStyles.labelLarge.copyWith(color: KaivaColors.textPrimary)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () {
                        // Skip auth — use app without account
                        Navigator.of(context).pop();
                      },
                      child: Text('Skip for now',
                          style: KaivaTextStyles.bodySmall.copyWith(color: KaivaColors.textMuted)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: KaivaTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: KaivaColors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: KaivaColors.textMuted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: KaivaColors.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KaivaColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KaivaColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KaivaColors.accentPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
