import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sermon.dart';
import '../providers/audio_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/pastor_badge.dart'; // Ensure this import exists

class FullScreenPlayer extends StatelessWidget {
  final Sermon? sermon;
  final Episode? episode;

  const FullScreenPlayer({super.key, this.sermon, this.episode});

  // --- UI HELPER: UP NEXT QUEUE ---
  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor, // Adapts to Night/Day mode
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const _QueueSheet(),
    );
  }

  void _shareSermon(String title, String speaker) {
    final String shareText = '''
🎧 Listening to "$title" by $speaker on Rhemalize!
This message is transforming my life. Check it out!
''';
    Share.share(shareText, subject: 'Check out this sermon!');
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    // If the provider says don't show, return an empty box
    if (!audioProvider.showFullPlayer) return const SizedBox.shrink();
    final favoritesProvider = context.watch<FavoritesProvider>();

    // Theme sensing for persistence
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final currentSermon = audioProvider.currentSermon ?? sermon;
    final currentEpisode = audioProvider.currentEpisode ?? episode;
    final currentId = currentEpisode?.id ?? currentSermon?.id ?? '';
    final isFavorite = favoritesProvider.isFavorite(currentId);

    final isPlaying = audioProvider.isPlaying;
    final isBuffering = audioProvider.isBuffering;
    final duration = audioProvider.duration;
    final position = audioProvider.position;

    final currentTitle =
        currentEpisode?.title ?? currentSermon?.title ?? "No Title";
    final currentSpeaker = currentSermon?.speaker ?? "Pastor Bright Elliot";
    final imageUrl = currentSermon?.imageUrl;

    return Scaffold(
      body: Dismissible(
        key: const Key('full_player_dismiss'),
        direction: DismissDirection.down,
        onDismissed: (_) => audioProvider.closeFullPlayer(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Column(
              children: [
                // TOP BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down,
                          size: 30, color: AppColors.primaryPurple),
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                    ),
                    Text('NOW PLAYING',
                        style: TextStyle(
                            color: isDarkMode
                                ? Colors.white70
                                : AppColors.primaryPurple,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.share_outlined,
                          size: 24, color: AppColors.primaryPurple),
                      onPressed: () =>
                          _shareSermon(currentTitle, currentSpeaker),
                    ),
                  ],
                ),
                const Spacer(),

                // ALBUM ART
                Expanded(
                  flex: 8,
                  child: Center(
                    child: Hero(
                      tag: 'album_art',
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.primaryPurple
                                          .withOpacity(isDarkMode ? 0.4 : 0.15),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15))
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: (imageUrl != null && imageUrl.isNotEmpty)
                                    ? Image.network(imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildDefaultLogo())
                                    : _buildDefaultLogo(),
                              ),
                            ),
                            if (currentEpisode != null)
                              Positioned(
                                top: 15,
                                right: 15,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Text("SERIES",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),

                // TITLE & INFO
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentTitle,
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          // WRAPPED SPEAKER AND BADGE IN A ROW
                          Row(
                            children: [
                              Text(currentSpeaker,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.primaryPurple,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(width: 8),
                              SeniorPastorBadge(speaker: currentSpeaker),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 28),
                      onPressed: () async {
                        final wasAdded =
                            await favoritesProvider.toggleFavorite(currentId);
                        _showCenterFlash(
                            context, wasAdded ? 'Added' : 'Removed', wasAdded);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SLIDER
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6)),
                  child: Slider(
                    value: position.inSeconds.toDouble().clamp(
                        0,
                        duration.inSeconds.toDouble() > 0
                            ? duration.inSeconds.toDouble()
                            : 1.0),
                    max: duration.inSeconds.toDouble() > 0
                        ? duration.inSeconds.toDouble()
                        : 1.0,
                    activeColor: AppColors.primaryPurple,
                    inactiveColor: AppColors.primaryPurple.withOpacity(0.2),
                    onChanged: (value) =>
                        audioProvider.seek(Duration(seconds: value.toInt())),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatTime(position),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(_formatTime(duration),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const Spacer(),

                // MAIN CONTROLS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle,
                          color: audioProvider.isShuffleOn
                              ? AppColors.primaryPurple
                              : Colors.grey),
                      onPressed: () => audioProvider.toggleShuffle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded,
                          size: 48, color: AppColors.primaryPurple),
                      onPressed: audioProvider.hasPrevious
                          ? audioProvider.playPrevious
                          : null,
                    ),
                    GestureDetector(
                      onTap: audioProvider.togglePlayPause,
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: const BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle),
                        child: isBuffering
                            ? const Padding(
                                padding: EdgeInsets.all(22.0),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3))
                            : Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 50,
                                color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded,
                          size: 48, color: AppColors.primaryPurple),
                      onPressed:
                          audioProvider.hasNext ? audioProvider.playNext : null,
                    ),
                    IconButton(
                      icon: Icon(
                          audioProvider.loopMode == LoopMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: audioProvider.loopMode != LoopMode.off
                              ? AppColors.primaryPurple
                              : Colors.grey),
                      onPressed: () => audioProvider.toggleLoopMode(),
                    ),
                  ],
                ),

                // BOTTOM UTILITY BAR
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => audioProvider.cycleSpeed(),
                        style: TextButton.styleFrom(
                            backgroundColor:
                                AppColors.primaryPurple.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text("${audioProvider.speed}x",
                            style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music_rounded,
                            color: AppColors.primaryPurple),
                        onPressed: () => _showQueue(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(45.0),
            child: Image.asset('assets/images/rhema-logo.png',
                fit: BoxFit.contain)));
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showCenterFlash(BuildContext context, String message, bool isAdding) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// --- QUEUE WIDGET ---
class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioProvider>();
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<dynamic> queue =
        audioProv.currentSermon?.messageType == MessageType.series
            ? audioProv.currentSermon!.episodes
            : (audioProv.playbackSession?.originalList ?? []);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Up Next",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final item = queue[index];
                final bool isCurrent =
                    (item.id == audioProv.currentEpisode?.id) ||
                        (item.id == audioProv.currentSermon?.id &&
                            audioProv.currentEpisode == null);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        ? Image.network(
                            item is Episode
                                ? (item.imageUrl ??
                                    audioProv.currentSermon?.imageUrl ??
                                    "")
                                : item.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _errorPlaceholder(),
                          )
                        : _errorPlaceholder(),
                  ),
                  title: Text(item.title,
                      style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent
                              ? AppColors.primaryPurple
                              : (isDarkMode ? Colors.white : Colors.black))),
                  subtitle: Text(item.speaker,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white60 : Colors.black54)),
                  trailing: isCurrent
                      ? const Icon(Icons.bar_chart,
                          color: AppColors.primaryPurple)
                      : null,
                  onTap: () {
                    if (item is Episode) {
                      audioProv.playEpisode(
                          audioProv.currentSermon!,
                          item,
                          audioProv.playbackSession!.originalList,
                          audioProv.playbackSession!.context);
                    } else {
                      audioProv.playSermon(
                          item,
                          audioProv.playbackSession!.originalList,
                          audioProv.playbackSession!.context);
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
        color: Colors.grey[200],
        width: 50,
        height: 50,
        child: const Icon(Icons.music_note, color: Colors.grey));
  }
}
