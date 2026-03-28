import 'package:flutter/material.dart';
import '../models/sermon.dart';
import '../utils/app_colors.dart';

class MiniPlayer extends StatelessWidget {
  final Sermon? sermon;
  final Episode? episode;
  final bool isPlaying;
  final double currentTime;
  final double duration;
  final VoidCallback onPlayPause;
  final VoidCallback onExpand;
  final VoidCallback onClose;
  final VoidCallback onSkipForward;
  final VoidCallback onSkipBack;

  const MiniPlayer({
    super.key,
    this.sermon,
    this.episode,
    required this.isPlaying,
    required this.currentTime,
    required this.duration,
    required this.onPlayPause,
    required this.onExpand,
    required this.onClose,
    required this.onSkipForward,
    required this.onSkipBack,
  });

  @override
  Widget build(BuildContext context) {
    // Determine content text
    final String title = episode?.title ?? sermon?.title ?? "Loading...";
    final String artist = sermon?.speaker ?? "Please wait";

    final double progress =
        (duration > 0) ? (currentTime / duration).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: onExpand,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -100) onExpand();
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Progress Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryPurple),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 3, 8, 0),
                child: Row(
                  children: [
                    // PERMANENT RHEMA LOGO
                    Hero(
                      tag: 'player_art',
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isPlaying
                              ? AppColors.primaryPurple.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.1),
                          image: const DecorationImage(
                            fit: BoxFit
                                .contain, // Contain looks better for logos
                            image: AssetImage('assets/images/rhema-logo.png'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // LABELS
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    // CONTROLS
                    IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.primaryPurple,
                        size: 32,
                      ),
                      onPressed: onPlayPause,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.grey, size: 22),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

