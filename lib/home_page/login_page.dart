import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/auth_provider.dart';
import 'home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // Tab: 0 = Login, 1 = Register
  int _selectedTab = 0;
  bool _loading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Login
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Register
  final _nameController = TextEditingController();
  final _regUserNameController = TextEditingController();
  final _gmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ── Brand colours ────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF6C63FF);
  static const Color _darkBg = Color(0xFF1A1A2E);
  static const Color _darkCard = Color(0xFF16213E);
  static const Color _surface = Color(0xFFF5F5FA);
  static const Color _textMuted = Color(0xFF9E9E9E);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _regUserNameController.dispose();
    _gmailController.dispose();
    _phoneController.dispose();
    _regPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Auth actions ─────────────────────────────────────────────────────────

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields.');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );
      await AuthProvider.instance.saveSession(
        result['token'] as String,
        result['user'],
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Connection error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final userName = _regUserNameController.text.trim();
    final gmail = _gmailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _regPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || userName.isEmpty || gmail.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all required fields.');
      return;
    }
    if (password != confirm) {
      _showSnack('Passwords do not match.');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AuthService.register(
        name: name,
        userName: userName,
        gmail: gmail,
        phoneNo: phone.isEmpty ? null : phone,
        password: password,
        passwordConfirmation: confirm,
      );
      await AuthProvider.instance.saveSession(
        result['token'] as String,
        result['user'],
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Connection error. Check your network.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTabSwitcher(),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedTab == 0
                        ? _buildLoginForm()
                        : _buildRegisterForm(),
                  ),
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildBottomLink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 32,
        bottom: 36,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkBg, _darkCard],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B7CF8), _primary],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.article_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'NeetCommon',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ace every exam with confidence',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab switcher ──────────────────────────────────────────────────────────
  Widget _buildTabSwitcher() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _tabItem('Log In', 0),
          _tabItem('Register', 1),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [_primary, Color(0xFF8B7CF8)],
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : _textMuted,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Login form ────────────────────────────────────────────────────────────
  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('Email'),
        const SizedBox(height: 6),
        _inputField(
          controller: _emailController,
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        _fieldLabel('Password'),
        const SizedBox(height: 6),
        _inputField(
          controller: _passwordController,
          hint: 'Enter your password',
          obscure: !_passwordVisible,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _passwordVisible = !_passwordVisible),
            child: Icon(
              _passwordVisible ? Icons.visibility_off : Icons.visibility,
              color: _textMuted,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _primaryButton(
          label: _loading ? '...' : 'Log In →',
          onTap: _loading ? null : _login,
        ),
      ],
    );
  }

  // ── Register form ─────────────────────────────────────────────────────────
  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('Full Name *'),
        const SizedBox(height: 6),
        _inputField(
          controller: _nameController,
          hint: 'Enter your full name',
        ),
        const SizedBox(height: 16),
        _fieldLabel('Username *'),
        const SizedBox(height: 6),
        _inputField(
          controller: _regUserNameController,
          hint: 'Choose a username',
        ),
        const SizedBox(height: 16),
        _fieldLabel('Gmail *'),
        const SizedBox(height: 6),
        _inputField(
          controller: _gmailController,
          hint: 'Enter your Gmail',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Phone No (optional)'),
        const SizedBox(height: 6),
        _inputField(
          controller: _phoneController,
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Password *'),
        const SizedBox(height: 6),
        _inputField(
          controller: _regPasswordController,
          hint: 'Create a password (min 6 chars)',
          obscure: !_passwordVisible,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _passwordVisible = !_passwordVisible),
            child: Icon(
              _passwordVisible ? Icons.visibility_off : Icons.visibility,
              color: _textMuted,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Confirm Password *'),
        const SizedBox(height: 6),
        _inputField(
          controller: _confirmPasswordController,
          hint: 'Repeat your password',
          obscure: !_confirmPasswordVisible,
          suffixIcon: GestureDetector(
            onTap: () => setState(
                () => _confirmPasswordVisible = !_confirmPasswordVisible),
            child: Icon(
              _confirmPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: _textMuted,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 26),
        _primaryButton(
          label: _loading ? '...' : 'Create Account →',
          onTap: _loading ? null : _register,
        ),
      ],
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _primary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffixIcon,
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: onTap == null
                ? [Colors.grey.shade400, Colors.grey.shade400]
                : [_primary, const Color(0xFF8B7CF8)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: onTap == null
              ? []
              : [
                  BoxShadow(
                    color: _primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFDDDDDD))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(color: _textMuted, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDDDDDD))),
      ],
    );
  }

  Widget _buildBottomLink() {
    final isLogin = _selectedTab == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? "Don't have an account? " : 'Already have an account? ',
          style: const TextStyle(color: _textMuted, fontSize: 13),
        ),
        GestureDetector(
          onTap: () => setState(() => _selectedTab = isLogin ? 1 : 0),
          child: Text(
            isLogin ? 'Sign up' : 'Log In',
            style: const TextStyle(
              color: _primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
