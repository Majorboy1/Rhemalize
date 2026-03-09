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

class _LoginScreenState extends State<LoginScreen> {
  // Logic variables
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showAdminForm = false;
  bool _isPasswordVisible = false;

  // Image Transition variables
  late Timer _timer;
  int _currentImageIndex = 0;
  final List<String> _backgroundImages = [
    'assets/images/picture-1.png', // Ensure these exist in your assets
    'assets/images/picture-2.png',
    'assets/images/picture-3.png',
  ];

  @override
  void initState() {
    super.initState();
    // Transition background every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % _backgroundImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String method) async {
    if (method == 'admin' && !_showAdminForm) {
      setState(() => _showAdminForm = true);
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      String? userEmail;
      if (method == 'google') {
        final credential = await auth.signInWithGoogle();
        userEmail = credential?.user?.email?.toLowerCase();
      } else {
        userEmail = _emailController.text.trim().toLowerCase();
        if (userEmail.isEmpty) throw 'Please enter your admin email.';
        await auth.signInWithEmailAndPassword(
            userEmail, _passwordController.text.trim());
      }

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userEmail)
          .get();

      if (mounted) {
        if (adminDoc.exists) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminMainScreen()));
        } else if (_showAdminForm) {
          await auth.signOut();
          throw 'Unauthorized: Email is not registered as an Admin.';
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const MainApp()));
        }
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
            // TOP IMAGE SECTION WITH CLIPPER
            Stack(
              children: [
                ClipPath(
                  clipper: ZigZagClipper(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      key: ValueKey<int>(_currentImageIndex),
                      height: MediaQuery.of(context).size.height * 0.55,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image:
                              AssetImage(_backgroundImages[_currentImageIndex]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Overlay to darken image slightly
                      child: Container(color: Colors.black.withOpacity(0.2)),
                    ),
                  ),
                ),
              ],
            ),

            // LOGO & TEXT SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Image.asset('assets/images/rhema-logo.png', height: 60),
                  const SizedBox(height: 10),
                  const Text(
                    "RHEMAlize",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1),
                  ),
                  const Text(
                    "Spread the word wherever you are",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  // LOGIN ACTIONS
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else if (!_showAdminForm)
                    _buildGoogleButton()
                  else
                    _buildAdminForm(),

                  const SizedBox(height: 20),

                  // SECONDARY OPTION
                  if (!_isLoading)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAdminForm = !_showAdminForm;
                        });
                      },
                      child: Text(
                        _showAdminForm
                            ? "Back to User Login"
                            : "Admin Login Options",
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Text(
              "By continuing, you agree to RHEMAlize's\nTerms of Use and Privacy Policy",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return InkWell(
      onTap: () => _handleLogin('google'),
      child: Container(
        height: 60,
        width: 120, // Circular style button like the image
        decoration: BoxDecoration(
          color: const Color(0xFF24292E),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Icon(Icons.g_mobiledata, color: Colors.white, size: 45),
        ),
      ),
    );
  }

  Widget _buildAdminForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Admin Email',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Password',
            filled: true,
            fillColor: Colors.grey[100],
            suffixIcon: IconButton(
              icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: () => _handleLogin('admin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 55),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("Confirm Admin Login",
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Custom Clipper for the Zig-Zag / Angled bottom effect
class ZigZagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.lineTo(size.width * 0.5, size.height); // Peak in the middle
    path.lineTo(size.width, size.height - 80); // Higher on the right
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
