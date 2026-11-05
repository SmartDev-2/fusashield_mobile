import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_logo.dart';
import '../widgets/farm_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/pill_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _url = TextEditingController(text: ApiService.baseUrl);
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String cleanUrl = _url.text.trim().replaceAll(RegExp(r'^[=\s]+'), '');
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'http://$cleanUrl';
      }
      _url.text = cleanUrl;
      await ApiService.instance.setBaseUrl(cleanUrl);
      await ApiService.instance.login(_user.text.trim(), _pass.text);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Server tidak terjangkau. Periksa alamat server dan jaringan.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const FarmBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: GlassCard(
                  radius: 34,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(size: 72),
                      const SizedBox(height: 12),
                      const Text('FusaShield',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      const Text('Masuk untuk memantau tanaman', style: AppText.body),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _url,
                        keyboardType: TextInputType.url,
                        decoration: _deco('Alamat server', Icons.dns_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: _user, decoration: _deco('Username', Icons.person_rounded)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pass,
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                        decoration: _deco('Password', Icons.lock_rounded),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 20),
                      PillButton(
                        label: _busy ? 'Menghubungkan…' : 'Masuk',
                        icon: Icons.login_rounded,
                        onTap: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
