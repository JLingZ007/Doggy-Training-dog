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

  /// ตรวจสอบก่อนว่ากรอกครบหรือยัง
  if (_usernameController.text.trim().isEmpty ||
      _emailController.text.trim().isEmpty ||
      _passwordController.text.isEmpty ||
      _confirmController.text.isEmpty) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("กรุณากรอกข้อมูลให้ครบทุกช่อง"),
        backgroundColor: Colors.red,
      ),
    );

    return;
  }

  /// ตรวจสอบ email
  if (!_emailController.text.contains("@")) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("รูปแบบอีเมลไม่ถูกต้อง"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  /// ตรวจสอบ password
  if (_passwordController.text.length < 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  /// ตรวจสอบ confirm password
  if (_passwordController.text != _confirmController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("รหัสผ่านไม่ตรงกัน"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    await credential.user
        ?.updateDisplayName(_usernameController.text.trim());

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.home, (_) => false);
    }

  } on FirebaseAuthException catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message ?? "เกิดข้อผิดพลาด"),
        backgroundColor: Colors.red,
      ),
    );

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

  InputDecoration _modernInput({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EFE7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              /// Logo
              Image.asset(
                'assets/images/doggy_logo.png',
                height: 140,
              ),

              const SizedBox(height: 16),

              const Text(
                "สร้างบัญชีใหม่",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "เริ่มต้นฝึกสุนัขของคุณได้ทันที",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 32),

              Form(
  key: _formKey,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      /// USERNAME
      TextFormField(
        controller: _usernameController,
        onChanged: (_) => setState(() {}),
        decoration: _modernInput(
          label: "ชื่อผู้ใช้งาน",
          icon: Icons.person,
        ),
      ),

      if (_usernameController.text.isNotEmpty &&
          _usernameController.text.trim().length < 3)
        const Padding(
          padding: EdgeInsets.only(top: 6, left: 12),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 18),
              SizedBox(width: 6),
              Text(
                "ชื่อผู้ใช้งานต้องมีอย่างน้อย 3 ตัวอักษร",
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),

      const SizedBox(height: 16),

      /// EMAIL
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        onChanged: (_) => setState(() {}),
        decoration: _modernInput(
          label: "อีเมล",
          icon: Icons.email,
        ),
      ),

      if (_emailController.text.isNotEmpty &&
          !_emailController.text.contains("@"))
        const Padding(
          padding: EdgeInsets.only(top: 6, left: 12),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 18),
              SizedBox(width: 6),
              Text(
                "รูปแบบอีเมลไม่ถูกต้อง",
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),

      const SizedBox(height: 16),

      /// PASSWORD
      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePwd,
        onChanged: (_) => setState(() {}),
        decoration: _modernInput(
          label: "รหัสผ่าน",
          icon: Icons.lock,
          suffix: IconButton(
            icon: Icon(
              _obscurePwd ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
          ),
        ),
      ),

      if (_passwordController.text.isNotEmpty &&
          _passwordController.text.length < 6)
        const Padding(
          padding: EdgeInsets.only(top: 6, left: 12),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 18),
              SizedBox(width: 6),
              Text(
                "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร",
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),

      const SizedBox(height: 16),

      /// CONFIRM PASSWORD
      TextFormField(
        controller: _confirmController,
        obscureText: _obscureConfirm,
        onChanged: (_) => setState(() {}),
        decoration: _modernInput(
          label: "ยืนยันรหัสผ่าน",
          icon: Icons.lock_outline,
          suffix: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ),

      if (_confirmController.text.isNotEmpty &&
          _confirmController.text != _passwordController.text)
        const Padding(
          padding: EdgeInsets.only(top: 6, left: 12),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 18),
              SizedBox(width: 6),
              Text(
                "รหัสผ่านไม่ตรงกัน",
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
    ],
  ),
),

              const SizedBox(height: 28),

              /// REGISTER BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 209, 170, 87),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "สร้างบัญชี",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              /// LOGIN LINK
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("มีบัญชีอยู่แล้ว? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "เข้าสู่ระบบ",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
