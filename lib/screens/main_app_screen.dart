// lib/screens/main_screen.dart
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
    // Listen for changes in the AudioProvider to trigger the Full Screen Player automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().addListener(_handleAudioStateChange);
    });
  }

  void _handleAudioStateChange() {
    if (!mounted) return;
    final audioProvider = context.read<AudioProvider>();

    // If the provider signals to show the full player and it isn't already open
    if (audioProvider.showFullPlayer && !_isPlayerModalOpen) {
      Future.microtask(() => _showFullScreenPlayer());
    }
  }

  void _onTabChange(BottomTab tab) {
    setState(() => _activeTab = tab);
  }

  Future<void> _showFullScreenPlayer() async {
    if (_isPlayerModalOpen || !mounted) return;

    setState(() => _isPlayerModalOpen = true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => const FullScreenPlayer(),
    );

    if (mounted) {
      setState(() => _isPlayerModalOpen = false);
      // Reset the flag in provider so it can be triggered again later
      context.read<AudioProvider>().closeFullPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    // watching the providers ensures the UI rebuilds when state changes
    final audioProvider = context.watch<AudioProvider>();
    final sermonProvider = context.watch<SermonProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final authProvider = context.watch<AuthProvider>();

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

    // This Boolean is the "Key" to showing/hiding the player.
    // It is true only if a sermon or episode is actually loaded.
    final bool hasActiveAudio = audioProvider.currentSermon != null ||
        audioProvider.currentEpisode != null;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // The main page content
                currentScreen,

                // --- 3D SPINNING LOGO BADGE (Static Overlay) ---
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  child: const SpinningRhemaLogo(),
                ),
              ],
            ),
          ),

          // --- MINI PLAYER LOGIC ---
          // If there is audio and the full player isn't covering the screen, show the MiniPlayer
          if (hasActiveAudio && !_isPlayerModalOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: MiniPlayer(
                sermon: audioProvider.currentSermon,
                episode: audioProvider.currentEpisode,
                isPlaying: audioProvider.isPlaying,
                currentTime: audioProvider.position.inSeconds.toDouble(),
                duration: audioProvider.duration.inSeconds.toDouble(),
                onPlayPause: () => audioProvider.togglePlayPause(),
                onExpand: _showFullScreenPlayer,
                onClose: () {
                  // This calls stop() in your provider, which sets currentSermon to null
                  // and triggers a rebuild, effectively removing this widget.
                  audioProvider.stop();
                },
                onSkipForward: () => audioProvider.playNext(),
                onSkipBack: () => audioProvider.playPrevious(),
              ),
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

// --- SPINNING LOGO COMPONENT ---
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
            ..setEntry(3, 2, 0.002) // Perspective for 3D depth
            ..rotateY(_controller.value * 2 * 3.14159), // Full Y-axis rotation
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
