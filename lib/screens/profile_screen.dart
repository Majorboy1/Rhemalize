// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sermon.dart';
import '../providers/audio_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import 'about_us_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final int? currentStreak;
  final DateTime? lastListenDate;
  final int? totalSermons;
  final Set<String>? favorites;
  final List<Sermon> sermons;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.currentStreak,
    this.lastListenDate,
    this.totalSermons,
    this.favorites,
    required this.sermons,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int get calculatedStreak {
    final streak = widget.currentStreak ?? 0;
    final lastListen = widget.lastListenDate;
    if (lastListen == null) return streak;
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lastListen.year, lastListen.month, lastListen.day))
        .inDays;
    return (diff > 1) ? 0 : streak;
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mostListened = widget.sermons.where((s) => s.playCount > 0).toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FE),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            _buildModernHeader(authProvider.user),
            _buildGlassStats(isDark),
            _buildSectionHeader("Spiritual Growth"),
            _buildStreakTile(),
            _buildSectionHeader("Account & App"),
            _buildActionCard([
              _menuItem(
                  icon: Icons.history_rounded,
                  title: 'Listening History',
                  color: Colors.blueAccent,
                  onTap: () => _showMostListenedSheet(
                      audio, mostListened.take(10).toList())),
              _menuItem(
                  icon: Icons.church_rounded,
                  title: 'Ministry Mission',
                  color: Colors.amber,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AboutUsScreen()))),
              _menuItem(
                  icon: Icons.tune_rounded,
                  title: 'App Settings',
                  color: Colors.purpleAccent,
                  onTap: () => _showSettingsSheet(isDark)),
            ], isDark),
            const SizedBox(height: 32),
            _logoutButton(),
            _appVersion(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 50),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.primaryPurple, Color(0xFF6A11CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'profile_pic',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white24),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white10,
                child: ClipOval(
                  child: user?.photoURL != null
                      ? Image.network(user!.photoURL!,
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person,
                              size: 45, color: Colors.white))
                      : const Icon(Icons.person, size: 45, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.userName,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(widget.userEmail,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildGlassStats(bool isDark) {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
          border:
              Border.all(color: isDark ? Colors.white10 : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statCol((widget.totalSermons ?? 0).toString(), "Finished"),
            _statCol((widget.favorites?.length ?? 0).toString(), "Saved"),
            _statCol(calculatedStreak > 10 ? "Gold" : "Pro", "Rank"),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String val, String label) {
    return Column(
      children: [
        Text(val,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple)),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 10, 24, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildStreakTile() {
    // REAL LIFE VISUAL LOGIC: Tile changes color as streak increases
    List<Color> streakColors = [
      const Color(0xFF446AD2),
      const Color(0xFF310558)
    ]; // Default Blue/Purple
    if (calculatedStreak >= 3)
      streakColors = [
        const Color(0xFFFF9966),
        const Color(0xFFFF5E62)
      ]; // Orange/Fire
    if (calculatedStreak >= 7)
      streakColors = [
        const Color(0xFF8E2DE2),
        const Color(0xFF4A00E0)
      ]; // Royal Purple/Glow

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: streakColors),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: streakColors[0].withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Icon(
              calculatedStreak >= 3
                  ? Icons.local_fire_department_rounded
                  : Icons.bolt_rounded,
              color: Colors.white,
              size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$calculatedStreak Day Streak",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text(
                  calculatedStreak > 0
                      ? "You're on fire! Keep going."
                      : "Start your spiritual journey today!",
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(List<Widget> items, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
              blurRadius: 10)
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem(
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
    );
  }

  Widget _logoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutConfirmation(context),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text("Log Out Account"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          foregroundColor: Colors.redAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _appVersion() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Opacity(
        opacity: 0.4,
        child: Text("Rhemalize v1.2.0 • Built by Wisdom Magnus • Build 2026",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ),
    );
  }

  void _showSettingsSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Text("Settings",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.storage_rounded),
              title: const Text("Clear Audio Cache"),
              onTap: () async {
                await StorageService().remove('cached_audio_list');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cache cleared!")));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMostListenedSheet(AudioProvider audio, List<Sermon> sermons) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Your Top Messages",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: sermons.isEmpty
                  ? const Center(
                      child: Text("Start listening to see your history!"))
                  : ListView.builder(
                      itemCount: sermons.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primaryPurple.withOpacity(0.1),
                            child: Text("${i + 1}")),
                        title: Text(sermons[i].title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text("${sermons[i].playCount} plays"),
                        onTap: () {
                          audio.playSermon(
                              sermons[i], sermons, PlaybackContext.home);
                          Navigator.pop(context);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onLogout();
              },
              child: const Text("Logout",
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
