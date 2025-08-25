import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // เพิ่มตามภาพสมัครสมาชิก
  final _usernameController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLogin = true; // true = เข้าสู่ระบบ, false = สมัครสมาชิก
  bool _isLoading = false;
  String? _errorMessage;

  // toggle แสดง/ซ่อนรหัสผ่าน
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

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'เกิดข้อผิดพลาด');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    // เช็คยืนยันรหัสผ่าน
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

      // อัปเดต displayName = ชื่อผู้ใช้งาน ตามภาพ
      await credential.user?.updateDisplayName(_usernameController.text.trim());

      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'เกิดข้อผิดพลาด');
    } finally {
      setState(() => _isLoading = false);
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
      fillColor: const Color(0xFFEAD8C8), // โทนครีมเหมือนภาพ
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

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/doggy_logo.png',
      width: 200,
      height: 200,
      fit: BoxFit.cover,
    );
  }

  Widget _buildTitle() {
    return Text(
      _isLogin ? 'เข้าสู่ระบบ' : 'ลงทะเบียน',
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: Colors.brown,
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLogin) ...[
            // ชื่อผู้ใช้งาน (ตามภาพลงทะเบียน)
            TextFormField(
              controller: _usernameController,
              decoration: _pillInput(label: 'ชื่อผู้ใช้งาน'),
              validator: (v) {
                if (_isLogin) return null;
                if (v == null || v.trim().isEmpty) return 'กรุณากรอกชื่อผู้ใช้งาน';
                if (v.trim().length < 3) return 'ชื่อผู้ใช้งานอย่างน้อย 3 ตัวอักษร';
                return null;
              },
            ),
            const SizedBox(height: 18),
          ],

          // อีเมล
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

          // รหัสผ่าน + ปุ่มตา
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

          if (!_isLogin) ...[
            // ยืนยันรหัสผ่าน + ปุ่มตา
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
                if (_isLogin) return null;
                if (v == null || v.isEmpty) return 'กรุณากรอกยืนยันรหัสผ่าน';
                if (v != _passwordController.text) {
                  return 'รหัสผ่านไม่ตรงกัน';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 22),

          // ปุ่มหลัก: เข้าสู่ระบบ / สมัครสมาชิก
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : (_isLogin ? _signInWithEmailAndPassword : _createAccount),
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
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isLogin ? 'เข้าสู่ระบบ' : 'ลงทะเบียน',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),

          // ปุ่ม "ยกเลิก" เฉพาะตอนสมัครสมาชิก (ตามภาพ)
          if (!_isLogin) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isLogin = true;
                  _errorMessage = null;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF7C5959), // โทนม่วงน้ำตาลคล้ายปุ่ม "ยกเลิก"
                side: const BorderSide(color: Colors.black87, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],

          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _isLogin = !_isLogin;
                _errorMessage = null;
              });
            },
            child: Text(
              _isLogin ? 'ยังไม่มีบัญชี ?  ลงทะเบียน' : 'มีบัญชีอยู่แล้ว ?  เข้าสู่ระบบ',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ใส่พื้นหลังโทนครีมอ่อนเหมือนภาพ
      backgroundColor: const Color(0xFFF7EFE7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLogin) _buildLogo(),
              if (_isLogin) const SizedBox(height: 16),
              _buildTitle(),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildAuthForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
