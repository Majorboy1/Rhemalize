import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  // 1. List of images to cycle through
  final List<String> _images = [
    'assets/images/pst&wife.jpg',
    'assets/images/ma_judith.jpg',
    'assets/images/bro_dave.jpg',
    'assets/images/sis_peace.jpg',
    'assets/images/bro_wisdom.jpg',
    'assets/images/esther.jpg',
    'assets/images/millenium.jpg',
    'assets/images/choir.jpg',
    'assets/images/usher.jpg',
    'assets/images/soul_winners.jpg',
    'assets/images/pst_ministering.jpg',
    'assets/images/crowd.jpg',
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 2. Start the timer to change the index every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Always cancel timers to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            stretch: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: AppColors.primaryPurple,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              title: const Text(
                "Our Story",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 3. AnimatedSwitcher for smooth transitions
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Image.asset(
                      _images[_currentIndex],
                      key: ValueKey<int>(
                          _currentIndex), // Vital for the switcher to know the widget changed
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primaryPurple.withValues(alpha: 0.2),
                        child: const Icon(Icons.church,
                            size: 80, color: Colors.white24),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.6, 1.0],
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow(
                      "6 Years", "Spreading the Word", Icons.history_edu),
                  const SizedBox(height: 30),
                  const Text("Meet the Founder",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    "Pastor & Mrs Bright Elliot",
                    style: TextStyle(
                        fontSize: 18,
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "With a heart for the broken and a vision for the future, Pastor Bright has led Rhema house of glory Church since its inception in 2020. Alongside his wife Evang. Judith, they have dedicated their lives to teaching the uncompromised Word of God, fostering a community where everyone can experience the tangible presence of God.",
                    style: TextStyle(
                        fontSize: 16, color: Colors.black87, height: 1.6),
                  ),
                  const SizedBox(height: 40),
                  _buildMissionCard(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.1)),
      ),
      child: const Column(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.primaryPurple, size: 36),
          SizedBox(height: 12),
          Text("OUR MISSION",
              style: TextStyle(
                  letterSpacing: 2,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple)),
          SizedBox(height: 15),
          Text(
            "A) is to manifest the glory of God in all nations through the power of the Holy Spirit.\n\nB) Our mission is to raise a generation of men and women that will walk with God through the Rhema Word of Life (Genesis 5:24).\n\nC) Our purpose is to make all men see the fellowship of the mystery of Christ and bring them into their place of glory and inheritance in Christ Jesus. (Ephesians 3:9–12).",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18,
                height: 1.4,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String sub, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryPurple),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        )
      ],
    );
  }
}
