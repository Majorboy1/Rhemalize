import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sermon.dart';
import '../providers/audio_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/pastor_badge.dart';

class FullScreenPlayer extends StatelessWidget {
  final Sermon? sermon;
  final Episode? episode;

  const FullScreenPlayer({super.key, this.sermon, this.episode});

  void _close(BuildContext context, AudioProvider provider) {
    provider.closeFullPlayer();
    Navigator.of(context).pop();
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => const _QueueSheet(),
    );
  }

  void _shareSermon(String title, String speaker) {
    final String shareText =
        '🎧 Listening to "$title" by $speaker on Rhemalize!\nThis message is transforming my life. Check it out!';
    SharePlus.instance
        .share(ShareParams(text: shareText, subject: 'Check out this sermon!'));
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final currentSermon = audioProvider.currentSermon ?? sermon;
    final currentEpisode = audioProvider.currentEpisode ?? episode;

    if (currentSermon == null && currentEpisode == null) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      );
    }

    final currentId = currentEpisode?.id ?? currentSermon?.id ?? '';
    final isFavorite = favoritesProvider.isFavorite(currentId);
    final isPlaying = audioProvider.isPlaying;
    final isBuffering = audioProvider.isBuffering;
    final duration = audioProvider.duration;
    final position = audioProvider.position;

    final currentTitle =
        currentEpisode?.title ?? currentSermon?.title ?? "Loading...";
    final currentSpeaker = currentSermon?.speaker ?? "Pastor Bright Elliot";
    final imageUrl = currentSermon?.imageUrl;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF1A1A2E), Colors.black]
                : [Colors.white, const Color(0xFFF2F2F7)],
          ),
        ),
        child: Dismissible(
          key: const Key('full_player_dismiss'),
          direction: DismissDirection.down,
          onDismissed: (_) => audioProvider.closeFullPlayer(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                children: [
                  // --- TOP NAVIGATION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 35, color: AppColors.primaryPurple),
                        onPressed: () => _close(context, audioProvider),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('PLAYING FROM',
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white54
                                        : Colors.grey,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold)),
                            Text(currentSermon?.title ?? "Sermon",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded,
                            size: 28, color: AppColors.primaryPurple),
                        onPressed: () =>
                            _shareSermon(currentTitle, currentSpeaker),
                      ),
                    ],
                  ),

                  const Expanded(flex: 1, child: SizedBox()),

                  // --- ANIMATED & ROTATING ALBUM ART ---
                  Expanded(
                    flex: 12, // Increased size from 10 to 12
                    child: Center(
                      child: AnimatedScale(
                        scale: isPlaying ? 1.0 : 0.9,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        child: Hero(
                          tag: 'player_art',
                          child: RotatingPlayerArt(
                            imageUrl: imageUrl,
                            isPlaying: isPlaying,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Expanded(flex: 1, child: SizedBox()),

                  // --- METADATA & FAVORITE ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentTitle,
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(currentSpeaker,
                                    style: const TextStyle(
                                        fontSize: 17,
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
                            color: isFavorite
                                ? Colors.red
                                : AppColors.primaryPurple,
                            size: 30),
                        onPressed: () async {
                          final wasAdded =
                              await favoritesProvider.toggleFavorite(currentId);
                          if (!context.mounted) return;
                          _showCenterFlash(
                              context,
                              wasAdded
                                  ? 'Added to Favorites'
                                  : 'Removed from Favorites');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- PROGRESS SLIDER ---
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7, elevation: 3),
                      activeTrackColor: AppColors.primaryPurple,
                      inactiveTrackColor: isDarkMode
                          ? Colors.white10
                          : AppColors.primaryPurple.withValues(alpha: 0.1),
                      thumbColor:
                          isDarkMode ? Colors.white : AppColors.primaryPurple,
                    ),
                    child: Slider(
                      value: position.inSeconds.toDouble().clamp(
                          0,
                          duration.inSeconds.toDouble() > 0
                              ? duration.inSeconds.toDouble()
                              : 1.0),
                      max: duration.inSeconds.toDouble() > 0
                          ? duration.inSeconds.toDouble()
                          : 1.0,
                      onChanged: (value) =>
                          audioProvider.seek(Duration(seconds: value.toInt())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatTime(position),
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        Text(_formatTime(duration),
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),

                  const Expanded(flex: 1, child: SizedBox()),

                  // --- PLAYBACK CONTROLS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.shuffle_rounded,
                            size: 26,
                            color: audioProvider.isShuffleOn
                                ? AppColors.primaryPurple
                                : Colors.grey.withValues(alpha: 0.6)),
                        onPressed: () => audioProvider.toggleShuffle(),
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_previous_rounded,
                            size: 55,
                            color: audioProvider.hasPrevious
                                ? AppColors.primaryPurple
                                : Colors.grey.shade300),
                        onPressed: audioProvider.hasPrevious
                            ? audioProvider.playPrevious
                            : null,
                      ),
                      GestureDetector(
                        onTap: audioProvider.togglePlayPause,
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                              color: AppColors.primaryPurple,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.primaryPurple
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10))
                              ]),
                          child: isBuffering
                              ? const Padding(
                                  padding: EdgeInsets.all(22.0),
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 4))
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 50,
                                  color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next_rounded,
                            size: 55,
                            color: audioProvider.hasNext
                                ? AppColors.primaryPurple
                                : Colors.grey.shade300),
                        onPressed: audioProvider.hasNext
                            ? audioProvider.playNext
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                            audioProvider.loopMode == LoopMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            size: 26,
                            color: audioProvider.loopMode != LoopMode.off
                                ? AppColors.primaryPurple
                                : Colors.grey.withValues(alpha: 0.6)),
                        onPressed: () => audioProvider.toggleLoopMode(),
                      ),
                    ],
                  ),

                  const Expanded(flex: 1, child: SizedBox()),

                  // --- BOTTOM TOOLBAR ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => audioProvider.cycleSpeed(),
                        icon: const Icon(Icons.speed_rounded, size: 18),
                        label: Text("${audioProvider.speed}x"),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryPurple,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor:
                                AppColors.primaryPurple.withValues(alpha: 0.1),
                            shape: const StadiumBorder()),
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music_rounded,
                            size: 28, color: AppColors.primaryPurple),
                        onPressed: () => _showQueue(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showCenterFlash(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        width: 220,
        backgroundColor: AppColors.primaryPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}

// --- NEW WIDGET FOR INFINITE ROTATION ---
class RotatingPlayerArt extends StatefulWidget {
  final String? imageUrl;
  final bool isPlaying;

  const RotatingPlayerArt({super.key, this.imageUrl, required this.isPlaying});

  @override
  State<RotatingPlayerArt> createState() => _RotatingPlayerArtState();
}

class _RotatingPlayerArtState extends State<RotatingPlayerArt>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 25), // Adjust speed of rotation here
      vsync: this,
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RotatingPlayerArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RotationTransition(
      turns: _controller,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.primaryPurple.withValues(alpha: isDarkMode ? 0.3 : 0.2),
                blurRadius: 50,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipOval(
            child: (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                ? Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(45.0),
      child: Image.asset('assets/images/rhema-logo.png', fit: BoxFit.contain),
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

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.fromLTRB(25, 15, 25, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 25),
            Text("Up Next",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final item = queue[index];
                  final bool isCurrent =
                      (item.id == audioProv.currentEpisode?.id) ||
                          (item.id == audioProv.currentSermon?.id &&
                              audioProv.currentEpisode == null);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.primaryPurple.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:
                            (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                                ? Image.network(
                                    item is Episode
                                        ? (item.imageUrl ??
                                            audioProv.currentSermon?.imageUrl ??
                                            "")
                                        : item.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _errorPlaceholder(),
                                  )
                                : _errorPlaceholder(),
                      ),
                      title: Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCurrent
                                  ? AppColors.primaryPurple
                                  : (isDarkMode
                                      ? Colors.white
                                      : Colors.black))),
                      subtitle: Text(item.speaker,
                          style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white60
                                  : Colors.black54)),
                      trailing: isCurrent
                          ? const Icon(Icons.bar_chart_rounded,
                              color: AppColors.primaryPurple)
                          : const Icon(Icons.play_circle_outline_rounded,
                              size: 20),
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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

