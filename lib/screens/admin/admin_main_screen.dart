import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/audio_provider.dart';
import '../../providers/sermon_provider.dart';
import '../../providers/auth_provider.dart';

// Screens
import '../profile_screen.dart';
import '../full_player_screen.dart';
import 'one_time_messages_screen.dart';
import 'series_screen.dart';
import 'pastor_management_screen.dart';
import 'user_management_screen.dart';

// Widgets
import '../admin/admin_bottom_nav.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/modals/add_sermon_modal.dart';
import '../../utils/app_colors.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  AdminTab _activeTab = AdminTab.sermons;
  bool _isModalOpen = false;
  DateTime _lastSync = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AudioProvider>().addListener(_handleAudioStateChange);
      }
    });
  }

  @override
  void dispose() {
    try {
      context.read<AudioProvider>().removeListener(_handleAudioStateChange);
    } catch (_) {}
    super.dispose();
  }

  void _handleAudioStateChange() {
    if (!mounted) return;
    final audioProvider = context.read<AudioProvider>();

    if (audioProvider.showFullPlayer && !_isModalOpen) {
      Future.microtask(_showFullScreenPlayer);
    }
  }

  void _onTabChange(AdminTab tab) {
    if (_activeTab != tab) {
      setState(() => _activeTab = tab);
    }
  }

  void _showFullScreenPlayer() {
    if (_isModalOpen || !mounted) return;
    setState(() => _isModalOpen = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => const FullScreenPlayer(),
    ).then((_) {
      if (mounted) {
        setState(() => _isModalOpen = false);
        context.read<AudioProvider>().closeFullPlayer();
      }
    });
  }

  void _showUploadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSermonModal(),
    );
  }

  Future<void> _handleLogout() async {
    final audioProvider = context.read<AudioProvider>();
    final authProvider = context.read<AuthProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content:
            const Text("Are you sure you want to log out of the Admin panel?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      audioProvider.stop();
      await authProvider.signOut();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final sermonProv = context.watch<SermonProvider>();
    final authProv = context.watch<AuthProvider>();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasActiveAudio = audioProvider.currentSermon != null ||
        audioProvider.currentEpisode != null;

    if (!sermonProv.isLoading) {
      _lastSync = DateTime.now();
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                    authProv.user?.displayName, isDark, sermonProv.isLoading),

                // Show statistics only on the primary sermon tab
                if (_activeTab == AdminTab.sermons)
                  _buildStatsRow(
                    sermonProv.oneTimeMessages.length,
                    sermonProv.seriesMessages.length,
                    sermonProv.isLoading,
                    isDark,
                  ),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCurrentScreen(authProv, sermonProv),
                      ),
                    ),
                  ),
                ),
                if (hasActiveAudio && !_isModalOpen)
                  const SizedBox(height: 110),
              ],
            ),
            if (hasActiveAudio && !_isModalOpen)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: MiniPlayer(
                  sermon: audioProvider.currentSermon,
                  episode: audioProvider.currentEpisode,
                  isPlaying: audioProvider.isPlaying,
                  currentTime: audioProvider.position.inSeconds.toDouble(),
                  duration: audioProvider.duration.inSeconds.toDouble(),
                  onPlayPause: () => audioProvider.togglePlayPause(),
                  onExpand: _showFullScreenPlayer,
                  onClose: () => audioProvider.stop(),
                  onSkipForward: () => audioProvider.playNext(),
                  onSkipBack: () => audioProvider.playPrevious(),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNav(
        activeTab: _activeTab,
        onTabChange: _onTabChange,
      ),

      // Floating Action Button logic updated to include AdminTab.users check
      floatingActionButton:
          (_activeTab == AdminTab.sermons || _activeTab == AdminTab.series)
              ? Padding(
                  padding: EdgeInsets.only(bottom: hasActiveAudio ? 85.0 : 0.0),
                  child: FloatingActionButton(
                    onPressed: _showUploadModal,
                    backgroundColor: AppColors.primaryPurple,
                    elevation: 6,
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 32),
                  ),
                )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCurrentScreen(AuthProvider auth, SermonProvider sermon) {
    // This switch is now exhaustive for AdminTab { sermons, series, pastors, users, profile }
    switch (_activeTab) {
      case AdminTab.sermons:
        return const OneTimeMessagesScreen();
      case AdminTab.series:
        return const SeriesScreen();
      case AdminTab.pastors:
        return const PastorManagementScreen();
      case AdminTab.users:
        return const UserManagementScreen();
      case AdminTab.profile:
        return ProfileScreen(
          userName: auth.user?.displayName ?? 'Admin User',
          userEmail: auth.user?.email ?? '',
          currentStreak: null,
          totalSermons: sermon.sermons.length,
          sermons: sermon.sermons,
          onLogout: _handleLogout,
          isAdminProfile: true,
        );
    }
  }

  Widget _buildHeader(String? name, bool isDark, bool isLoading) {
    final String timeStr = DateFormat('h:mm a').format(_lastSync);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isLoading ? "Updating Data..." : "Last synced: $timeStr",
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3),
                  ),
                  if (isLoading) const SizedBox(width: 8),
                  if (isLoading)
                    const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primaryPurple)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "Hi, ${name?.split(' ')[0] ?? 'Admin'}",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5),
              ),
            ],
          ),
          GestureDetector(
            onTap: _handleLogout,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 22),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatsRow(
      int singles, int series, bool isLoading, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _statCard("Single", singles.toString(), Icons.mic_rounded,
              AppColors.primaryPurple, isLoading),
          const SizedBox(width: 12),
          _statCard("Series", series.toString(), Icons.layers_rounded,
              Colors.blueAccent, isLoading),

        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color, bool isLoading) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(isLoading ? "..." : value,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            Text(label,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}








