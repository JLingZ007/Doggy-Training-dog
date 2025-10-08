import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/app_routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePwd = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = 'รหัสผ่านและยืนยันรหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await credential.user?.updateDisplayName(_usernameController.text.trim());

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'เกิดข้อผิดพลาด');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _pillInput({
    required String label,
    IconData? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix != null ? Icon(prefix) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFEAD8C8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.black87),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.black87),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.brown, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EFE7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ลงทะเบียน',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: _pillInput(label: 'ชื่อผู้ใช้งาน'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'กรุณากรอกชื่อผู้ใช้งาน';
                            if (v.trim().length < 3) return 'ชื่อผู้ใช้งานอย่างน้อย 3 ตัวอักษร';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _pillInput(label: 'อีเมล', prefix: Icons.email),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'กรุณากรอกอีเมล';
                            if (!v.contains('@')) return 'กรุณากรอกอีเมลให้ถูกต้อง';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePwd,
                          decoration: _pillInput(
                            label: 'รหัสผ่าน',
                            prefix: Icons.lock,
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                              icon: Icon(_obscurePwd ? Icons.visibility : Icons.visibility_off),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                            if (v.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          decoration: _pillInput(
                            label: 'ยืนยันรหัสผ่าน',
                            prefix: Icons.lock_outline,
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'กรุณากรอกยืนยันรหัสผ่าน';
                            if (v != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 6),
                          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _createAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFE2D3),
                            foregroundColor: Colors.black87,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                              side: const BorderSide(color: Colors.black87, width: 1),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'ลงทะเบียน',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF7C5959),
                            side: const BorderSide(color: Colors.black87, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'มีบัญชีอยู่แล้ว ?  เข้าสู่ระบบ',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
