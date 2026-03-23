import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sermon.dart';
import '../providers/audio_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import 'about_us_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final int? currentStreak;
  final DateTime? lastListenDate;
  final int? totalSermons;
  final Set<String>?
      favorites; // Kept for constructor compatibility, but ignored in logic
  final List<Sermon> sermons;
  final VoidCallback onLogout;
  final bool isAdminProfile;

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
    this.isAdminProfile = false,
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
    if (diff > 1) return 0;
    return streak > 0 ? streak : 1;
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final authProvider = context.watch<AuthProvider>();
    // LIVE SOURCE OF TRUTH
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final recentHistory =
        _resolveRecentHistory(widget.sermons, audio.recentPlayedIds);
    final showGrowth = !widget.isAdminProfile;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FE),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            _buildModernHeader(authProvider.user),
            _buildGlassStats(isDark, favoritesProvider),
            if (showGrowth) _buildSectionHeader('Spiritual Growth'),
            if (showGrowth) _buildStreakTile(),
            _buildSectionHeader('Account & App'),
            _buildEngagementCard(
                audio, favoritesProvider, recentHistory, isDark),
            _buildSectionHeader('Engagement'),
            _buildActionCard([
              _menuItem(
                icon: Icons.history_rounded,
                title: 'Listening History',
                color: Colors.blueAccent,
                onTap: () => _showListeningHistorySheet(audio, recentHistory),
              ),
              _menuItem(
                icon: Icons.favorite_rounded,
                title: 'Saved Messages',
                color: Colors.pinkAccent,
                onTap: () => _showListeningHistorySheet(
                  audio,
                  _resolveRecentHistory(
                    widget.sermons,
                    // FIX: Use live list from Provider here
                    favoritesProvider.favoriteSermonIds.toList(),
                  ),
                  title: 'Saved Messages',
                  emptyText: 'Save sermons to see them here.',
                ),
              ),
              _menuItem(
                icon: Icons.church_rounded,
                title: 'Ministry Mission',
                color: Colors.amber,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                ),
              ),
              _menuItem(
                icon: Icons.tune_rounded,
                title: 'App Settings',
                color: Colors.purpleAccent,
                onTap: () => _showSettingsSheet(isDark),
              ),
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
          end: Alignment.bottomRight,
        ),
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
                          fit: BoxFit.cover, width: 90, height: 90)
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

  Widget _buildGlassStats(bool isDark, FavoritesProvider favoritesProvider) {
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
              offset: const Offset(0, 10),
            )
          ],
          border:
              Border.all(color: isDark ? Colors.white10 : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statCol((widget.totalSermons ?? 0).toString(), 'Heard'),
            // FIX: Force live length from provider
            _statCol(
                favoritesProvider.favoriteSermonIds.length.toString(), 'Saved'),
            _statCol(
                widget.isAdminProfile ? 'Admin' : calculatedStreak.toString(),
                widget.isAdminProfile ? 'Role' : 'Streak'),
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
        const SizedBox(height: 4),
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
    List<Color> streakColors = [
      const Color(0xFF446AD2),
      const Color(0xFF310558)
    ];
    if (calculatedStreak >= 3) {
      streakColors = [const Color(0xFFFF9966), const Color(0xFFFF5E62)];
    }
    if (calculatedStreak >= 7) {
      streakColors = [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)];
    }

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
              Text('$calculatedStreak Day Streak',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text(
                  calculatedStreak > 0
                      ? 'You are staying consistent. Keep going.'
                      : 'Start your spiritual journey today!',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementCard(
      AudioProvider audio,
      FavoritesProvider favoritesProvider,
      List<Sermon> recentHistory,
      bool isDark) {
    final lastListenLabel = widget.lastListenDate == null
        ? 'No listening yet'
        : _formatProfileDate(widget.lastListenDate!);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
              blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _engagementTile(
                  icon: Icons.schedule_rounded,
                  label: 'Continue From',
                  value: audio.lastResumableId == null
                      ? 'Nothing queued'
                      : _formatPosition(
                          audio.getSavedPosition(audio.lastResumableId!)),
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _engagementTile(
                  icon: Icons.favorite_rounded,
                  label: 'Favorites Sync',
                  // FIX: Use live length from provider
                  value: '${favoritesProvider.favoriteSermonIds.length} saved',
                  color: Colors.pinkAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _engagementTile(
                      icon: Icons.history_rounded,
                      label: 'Recent Plays',
                      value: '${recentHistory.length}',
                      color: Colors.blueAccent)),
              const SizedBox(width: 12),
              Expanded(
                  child: _engagementTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'Last Listen',
                      value: lastListenLabel,
                      color: Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _engagementTile(
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        label: const Text('Log Out Account'),
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
        child: Text('Rhemalize v1.2.0 • Built by Wisdom Magnus • 2026',
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
            const Text('Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.storage_rounded),
              title: const Text('Clear Audio Cache'),
              onTap: () async {
                await StorageService().remove('cached_audio_list');
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared!')));
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Sermon> _resolveRecentHistory(
      List<Sermon> sermons, List<String> recentIds) {
    final List<Sermon> history = [];
    for (final id in recentIds) {
      for (final sermon in sermons) {
        if (sermon.id == id) {
          history.add(sermon);
          break;
        }
        final ep = sermon.episodes.where((e) => e.id == id).toList();
        if (ep.isNotEmpty) {
          final episode = ep.first;
          history.add(Sermon(
            id: episode.id,
            title: episode.title,
            speaker: episode.speaker,
            imageUrl: episode.imageUrl ?? sermon.imageUrl,
            audioUrl: episode.audioUrl,
            category: sermon.category,
            description: episode.description,
            date: episode.date,
            duration: episode.duration,
            messageType: MessageType.single,
            episodes: const [],
            seriesTitle: sermon.title,
            playCount: episode.playCount,
          ));
          break;
        }
      }
    }
    return history;
  }

  String _formatProfileDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatPosition(Duration pos) {
    final h = pos.inHours;
    final m = pos.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = pos.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _showListeningHistorySheet(AudioProvider audio, List<Sermon> sermons,
      {String title = 'Your Recent Listening',
      String emptyText = 'Start listening to see your history!'}) {
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
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: sermons.isEmpty
                  ? Center(child: Text(emptyText))
                  : ListView.builder(
                      itemCount: sermons.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primaryPurple.withOpacity(0.1),
                            child: Text('${i + 1}')),
                        title: Text(sermons[i].title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(sermons[i].seriesTitle != null
                            ? '${sermons[i].seriesTitle} • ${sermons[i].speaker}'
                            : sermons[i].speaker),
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
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onLogout();
              },
              child: const Text('Logout',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
