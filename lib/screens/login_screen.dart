import 'package:flutter/material.dart';
import 'package:my_flutter_app/screens/home_gate.dart';

import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/auth_request.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _service = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.login(AuthRequest(
          login: _userCtrl.text.trim(), password: _passCtrl.text));
      if (!mounted) return;
      AppSnackbar.success(context, 'Login successful');
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeGate()));
    } on ApiException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Unexpected error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goRegister() async {
    final registered = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const RegisterScreen()));
    if (registered == true && mounted) {
      AppSnackbar.success(context, 'Account created. Please log in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: MaxWidth(
              maxWidth: Responsive.maxAuthWidth,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text('LOGIN',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text)),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: 'Username',
                      hint: 'Username',
                      controller: _userCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Username is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      hint: 'Password',
                      controller: _passCtrl,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password is required'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                        text: 'LOGIN', onPressed: _submit, loading: _loading),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Forgot password?',
                          style: TextStyle(color: AppColors.text)),
                    ),
                    TextButton(
                      onPressed: _goRegister,
                      child: const Text('Create Account',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
