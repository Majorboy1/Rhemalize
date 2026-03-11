import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_main_screen.dart';
import 'main_app_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showAdminForm = false;
  bool _isPasswordVisible = false;

  late Timer _imageTimer;
  late AnimationController _scrollController;
  late AnimationController _scaleController;
  int _currentImageIndex = 0;

  final List<String> _backgroundImages = [
    'assets/images/picture-4.png',
    'assets/images/pst&wife.jpg',
    'assets/images/ma_judith.png',
    'assets/images/bro_dave.jpg',
    'assets/images/sis_peace.jpg',
    'assets/images/bro_wisdom.jpg',
    'assets/images/esther.jpg',
  ];

  @override
  void initState() {
    super.initState();

    // 1. Infinite Horizontal Scroll (Marquee)
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // 2. Background Image Zoom
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _imageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() => _currentImageIndex =
            (_currentImageIndex + 1) % _backgroundImages.length);
      }
    });
  }

  @override
  void dispose() {
    _imageTimer.cancel();
    _scrollController.dispose();
    _scaleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String method) async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      String? userEmail;
      if (method == 'google') {
        final credential = await auth.signInWithGoogle();
        userEmail = credential?.user?.email?.toLowerCase();
      } else {
        userEmail = _emailController.text.trim().toLowerCase();
        await auth.signInWithEmailAndPassword(
            userEmail, _passwordController.text.trim());
      }

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userEmail)
          .get();
      if (!mounted) return;

      if (adminDoc.exists) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AdminMainScreen()));
      } else if (_showAdminForm) {
        await auth.signOut();
        throw 'Access Denied: Admin rights required.';
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainApp()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER IMAGE
            ClipPath(
              clipper: HeaderClipper(),
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1000),
                    child: ScaleTransition(
                      key: ValueKey<int>(_currentImageIndex),
                      scale: Tween<double>(begin: 1.0, end: 1.15)
                          .animate(_scaleController),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.42,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                _backgroundImages[_currentImageIndex]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                      height: MediaQuery.of(context).size.height * 0.42,
                      color: Colors.black.withOpacity(0.3)),
                ],
              ),
            ),

            // FIXED MARQUEE (Solves the 639px overflow)
            SizedBox(
              height: 40,
              width: double.infinity,
              child: ClipRect(
                // Clips the text so it doesn't bleed out of the screen
                child: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          left: MediaQuery.of(context).size.width -
                              (_scrollController.value *
                                  (MediaQuery.of(context).size.width + 800)),
                          child: Row(
                            children: List.generate(
                                400, (index) => _buildScrollingText()),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Image.asset('assets/images/rhema-logo.png', height: 70),
                  const Text("RHEMAlize",
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5)),
                  const SizedBox(height: 8),
                  const Text(
                    "\"Faith comes by hearing, and hearing through the word of Christ.\"",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 40),
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.black)
                  else if (!_showAdminForm)
                    _buildGoogleButton()
                  else
                    _buildAdminForm(),
                  const SizedBox(height: 30),
                  if (!_isLoading)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showAdminForm = !_showAdminForm),
                      child: Text(
                        _showAdminForm ? "Sign in as Member" : "Admin Login",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollingText() {
    return Container(
      padding: const EdgeInsets.only(right: 60), // Space between repetitions
      child: const Text(
        "YEAR OF SUPERNATURAL SPREADING •",
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.blueAccent,
            letterSpacing: 1.5),
      ),
    );
  }

  // PREMIUM BLACK GOOGLE BUTTON
  Widget _buildGoogleButton() {
    return InkWell(
      onTap: () => _handleLogin('google'),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black, // Your requested black background
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Standard Multi-color Google Icon
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_\"G\"_Logo.svg/480px-Google_\"G\"_Logo.svg.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 15),
            const Text(
              "Continue with Google",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED ADMIN DESIGN
  Widget _buildAdminForm() {
    return Column(
      children: [
        _buildTextField(_emailController, "Admin Email", Icons.email_outlined),
        const SizedBox(height: 12),
        _buildTextField(_passwordController, "Password", Icons.lock_outline,
            isPass: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _handleLogin('admin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: const Size(double.infinity, 58),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text("Access Admin Portal",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon,
      {bool isPass = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black45, size: 20),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: 20),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width * 0.5, size.height + 10, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}
