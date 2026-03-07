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
  late List<AnimationController> _floatingControllers;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showAdminForm = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _floatingControllers = List.generate(
        4,
        (i) => AnimationController(
            vsync: this, duration: Duration(milliseconds: 3000 + (i * 500)))
          ..repeat(reverse: true));

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    for (var c in _floatingControllers) {
      c.dispose();
    }
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String method) async {
    // Switch to Admin Form view
    if (method == 'admin' && !_showAdminForm) {
      setState(() => _showAdminForm = true);
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      String? userEmail;

      if (method == 'google') {
        // Only regular users use Google Login
        final credential = await auth.signInWithGoogle();
        userEmail = credential?.user?.email?.toLowerCase();
      } else {
        // Admin Login uses custom form
        userEmail = _emailController.text.trim().toLowerCase();
        if (userEmail.isEmpty) throw 'Please enter your admin email.';
        if (_passwordController.text.trim().isEmpty)
          throw 'Please enter your password.';

        await auth.signInWithEmailAndPassword(
            userEmail, _passwordController.text.trim());
      }

      // Check Admin permissions in Firestore
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userEmail)
          .get();

      if (mounted) {
        if (adminDoc.exists) {
          // If in Admin collection, go to Admin Panel
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminMainScreen()));
        } else if (_showAdminForm) {
          // If they tried the Admin form but aren't admins, kick them out
          await auth.signOut();
          throw 'Unauthorized: Your email is not registered as an Admin.';
        } else {
          // Normal user login via Google
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A458C), Color(0xFF2D2A54)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildTopBrand(),
                _buildAvatarStack(),
                _buildBibleVerse(),
                _buildLoginCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBrand() {
    return Column(
      children: [
        Container(
          height: 70,
          width: 70,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
                image: AssetImage('assets/images/rhema-logo.png')),
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            children: [
              TextSpan(text: 'RHEMA'),
              TextSpan(
                  text: 'lize',
                  style:
                      TextStyle(fontWeight: FontWeight.normal, fontSize: 20)),
            ],
          ),
        ),
        const Text("Year of Supernatural Spreading",
            style: TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildAvatarStack() {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildAvatar(0, left: 70, top: 20, size: 75, img: 'picture-1'),
          _buildAvatar(1, right: 80, top: 10, size: 85, img: 'picture-2'),
          _buildAvatar(2, left: 120, bottom: 20, size: 75, img: 'picture-3'),
          _buildAvatar(3, right: 110, bottom: 60, size: 85, img: 'picture-4'),
        ],
      ),
    );
  }

  Widget _buildBibleVerse() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: const [
          Text(
            '"So then faith comes by hearing, and hearing by the word of God."',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 8),
          Text('Romans 10:17',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(35)),
        child: Column(
          children: [
            Text(_showAdminForm ? "Admin Portal" : "Welcome Back!",
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 8),
            Text(
                _showAdminForm
                    ? "Enter your secure admin credentials"
                    : "Choose your preferred sign-in method",
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),
            if (_showAdminForm) ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Admin Email', prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              // ONLY SHOW GOOGLE LOGIN FOR REGULAR USERS
              if (!_showAdminForm)
                _buildButton(
                  label: 'Login with Gmail',
                  icon: Icons.email,
                  color: const Color(0xFFB70019),
                  onTap: () => _handleLogin('google'),
                ),
              if (!_showAdminForm) const SizedBox(height: 15),
              _buildButton(
                label:
                    _showAdminForm ? 'Confirm Admin Login' : 'Sign in as Admin',
                icon: Icons.verified_user_outlined,
                color: const Color(0xFF4A458C), // Matched brand purple
                onTap: () => _handleLogin('admin'),
              ),
              if (_showAdminForm)
                TextButton(
                  onPressed: () => setState(() {
                    _showAdminForm = false;
                    _isPasswordVisible = false;
                  }),
                  child: const Text("Back to User Login"),
                ),
            ],
            const SizedBox(height: 25),
            const Text("By signing in, you agree to our Terms & Privacy Policy",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(int i,
      {double? left,
      double? right,
      double? top,
      double? bottom,
      required double size,
      required String img}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _floatingControllers[i],
        builder: (context, _) => Transform.translate(
          offset: Offset(0, 10 * _floatingControllers[i].value),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(
                  image: AssetImage('assets/images/$img.png'),
                  fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
    );
  }
}
