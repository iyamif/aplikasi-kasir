import 'package:flutter/material.dart';
import 'package:point_of_sale/pages/register_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final api = ApiService();

  bool loading = false;
  bool obscurePass = true;
  String? qrUrl;
  String? secret;
  String? userId;

  // === LOGIN HANDLER ===
  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    final res = await api.login(emailCtrl.text.trim(), passCtrl.text.trim());
    setState(() => loading = false);

    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada respons dari server'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final status = res['status'] ?? res['message'];

    if (status == 'need_scan' || res['qr_url'] != null) {
      setState(() {
        qrUrl = res['qr_url'];
        secret = res['secret'];
        userId = res['user_id'].toString();
      });
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 200));
      show2FASetupDialog();
    } else if (status == 'need_otp' ||
        status == 'OTP required' ||
        (res['need_otp'] == true)) {
      setState(() => userId = res['user_id'].toString());
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 200));
      showOtpDialog();
    } else if (res['token'] != null) {
      await api.saveToken(res['token']);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage(user: res['user'])),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Email atau password salah'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // === MODAL QR CODE ===
  void show2FASetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Scan QR di Google Authenticator'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (qrUrl != null)
                SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(data: qrUrl!),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('QR tidak tersedia'),
                ),
              // const SizedBox(height: 12),
              // SelectableText(
              //   'Atau masukkan kode manual:\n$secret',
              //   textAlign: TextAlign.center,
              // ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showOtpDialog();
            },
            child: const Text('Sudah Scan, Masukkan OTP'),
          ),
        ],
      ),
    );
  }

  // === MODAL OTP ===
  void showOtpDialog() {
    otpCtrl.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Verifikasi OTP'),
        content: SizedBox(
          width: 300,
          child: TextField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Kode OTP',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              verifyOtp();
            },
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  // === VERIFIKASI OTP ===
  Future<void> verifyOtp() async {
    setState(() => loading = true);
    final res = await api.verify2FA(userId!, otpCtrl.text.trim());
    setState(() => loading = false);

    if (res['token'] != null) {
      await api.saveToken(res['token']);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage(user: res['user'])),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Kode OTP salah')),
      );
    }
  }

  // === UI LOGIN ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'POS SYSTEM',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passCtrl,
                  obscureText: obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => obscurePass = !obscurePass),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'Password wajib diisi';
                    if (val.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: const Text('Belum punya akun? Daftar di sini'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
