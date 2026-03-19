import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/sermon_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';

import 'home_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'full_player_screen.dart';

import '../widgets/custom_bottom_nav.dart';
import '../widgets/mini_player.dart';
import '../utils/app_colors.dart';
import '../utils/player_transitions.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  BottomTab _activeTab = BottomTab.home;
  bool _isPlayerModalOpen = false;

  @override
  void initState() {
    super.initState();
    // Use a microtask to attach the listener after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AudioProvider>().addListener(_handleAudioStateChange);
      }
    });
  }

  @override
  void dispose() {
    // Clean up listener to prevent memory leaks or late-initialization errors
    try {
      context.read<AudioProvider>().removeListener(_handleAudioStateChange);
    } catch (_) {}
    super.dispose();
  }

  void _handleAudioStateChange() {
    if (!mounted) return;
    final audioProvider = context.read<AudioProvider>();

    // Optimization: Only trigger modal if provider specifically flags it
    // and we aren't already showing it.
    if (audioProvider.showFullPlayer && !_isPlayerModalOpen) {
      _showFullScreenPlayer();
    }
  }

  void _onTabChange(BottomTab tab) {
    if (_activeTab != tab) {
      setState(() => _activeTab = tab);
    }
  }

  Future<void> _showFullScreenPlayer() async {
    if (_isPlayerModalOpen || !mounted) return;

    setState(() => _isPlayerModalOpen = true);

    await Navigator.of(context).push(
      PlayerTransition.slideUpRoute(const FullScreenPlayer()),
    );

    if (mounted) {
      setState(() => _isPlayerModalOpen = false);
      context.read<AudioProvider>().closeFullPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- CRITICAL OPTIMIZATION ---
    // Using context.select ensures this build() ONLY runs when the active audio status changes.
    // This prevents the screen from freezing/stuttering while audio is buffering.
    final bool hasActiveAudio = context.select<AudioProvider, bool>(
        (pro) => pro.currentSermon != null || pro.currentEpisode != null);

    // We use .read() for these because their internal state changes (like sermon lists)
    // are handled by the sub-screens (HomeScreen, etc.), not the MainApp shell.
    final authProvider = context.read<AuthProvider>();
    final sermonProvider = context.read<SermonProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();

    // Determine which screen to show based on the active tab
    Widget currentScreen;
    switch (_activeTab) {
      case BottomTab.home:
        currentScreen = const HomeScreen();
        break;
      case BottomTab.search:
        currentScreen = const SearchScreen();
        break;
      case BottomTab.favorites:
        currentScreen = const FavoritesScreen();
        break;
      case BottomTab.library:
        currentScreen = const LibraryScreen();
        break;
      case BottomTab.profile:
        currentScreen = ProfileScreen(
          userName: authProvider.user?.displayName ?? 'User',
          userEmail: authProvider.user?.email ?? '',
          currentStreak: 0,
          totalSermons: sermonProvider.sermons.length,
          favorites: favoritesProvider.favoriteSermonIds,
          sermons: sermonProvider.sermons,
          onLogout: () => authProvider.signOut(),
        );
        break;
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // The main page content
                currentScreen,

                // --- 3D SPINNING LOGO BADGE ---
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  child: const SpinningRhemaLogo(),
                ),
              ],
            ),
          ),

          // --- MINI PLAYER LOGIC ---
          // Using a Consumer here localized to just the MiniPlayer prevents the
          // whole screen from rebuilding every second for the progress bar.
          if (hasActiveAudio && !_isPlayerModalOpen)
            Consumer<AudioProvider>(
              builder: (context, audioPro, _) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: MiniPlayer(
                    sermon: audioPro.currentSermon,
                    episode: audioPro.currentEpisode,
                    isPlaying: audioPro.isPlaying,
                    currentTime: audioPro.position.inSeconds.toDouble(),
                    duration: audioPro.duration.inSeconds.toDouble(),
                    onPlayPause: () => audioPro.togglePlayPause(),
                    onExpand: _showFullScreenPlayer,
                    onClose: () => audioPro.stop(),
                    onSkipForward: () => audioPro.playNext(),
                    onSkipBack: () => audioPro.playPrevious(),
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        activeTab: _activeTab,
        onTabChange: _onTabChange,
      ),
    );
  }
}

// --- SPINNING LOGO COMPONENT (Keep as is) ---
class SpinningRhemaLogo extends StatefulWidget {
  const SpinningRhemaLogo({super.key});

  @override
  State<SpinningRhemaLogo> createState() => _SpinningRhemaLogoState();
}

class _SpinningRhemaLogoState extends State<SpinningRhemaLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(_controller.value * 2 * 3.14159),
          child: child,
        );
      },
      child: Container(
        height: 48,
        width: 48,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
        child: Image.asset(
          'assets/images/rhema-logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
        ),
      ),
    );
  }
}
