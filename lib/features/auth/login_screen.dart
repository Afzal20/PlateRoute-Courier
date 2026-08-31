import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_controller.dart';

/// S1 — Login (courier role). Wrong credentials are the only `danger` state
/// here; layout keeps the CTA bottom-anchored even at 1.4x text scale.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(
            _email.text.trim(),
            _password.text,
          );
      if (mounted) context.go('/today');
    } on Object {
      setState(() {
        _error = AppLocalizations.of(context)!.loginFailed;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final success = await ref.read(authProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    if (!success) {
      setState(() {
        _error = 'Google Login failed.';
        _busy = false;
      });
    } else {
      // The auth listener will redirect when signed in.
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(Spacing.l),
                  children: [
                    SizedBox(height: Spacing.xxl),
                    Icon(Icons.local_shipping_outlined,
                        size: 56, color: theme.colorScheme.primary),
                    SizedBox(height: Spacing.l),
                    Text(
                      l10n.appTitle,
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: Spacing.xs),
                    Text(
                      l10n.loginTitle,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.textTheme.bodySmall?.color),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: Spacing.xxl),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: l10n.loginEmail),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? l10n.loginEmail : null,
                    ),
                    SizedBox(height: Spacing.m),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration:
                          InputDecoration(labelText: l10n.loginPassword),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      SizedBox(height: Spacing.m),
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(Spacing.l),
                child: _busy
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed: _submit,
                            child: Text(l10n.loginBtn),
                          ),
                          SizedBox(height: Spacing.m),
                          OutlinedButton(
                            onPressed: _handleGoogleLogin,
                            child: Text('Continue with Google'),
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
}
