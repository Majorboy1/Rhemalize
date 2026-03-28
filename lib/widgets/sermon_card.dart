import 'package:flutter/material.dart';
import '../models/sermon.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class SermonCard extends StatelessWidget {
  final Sermon sermon;
  final VoidCallback onPlay;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onViewSeries;
  final bool isFavorite;
  final bool isPlayed;

  const SermonCard({
    super.key,
    required this.sermon,
    required this.onPlay,
    this.onToggleFavorite,
    this.onViewSeries,
    this.isFavorite = false,
    this.isPlayed = false,
  });

  String _formatDate(DateTime date) {
    return DateFormat('d MMM, y').format(date);
  }

  // FIXED: Built the URL directly here to resolve the 'shareUrl' undefined getter error
  void _shareSermon() {
    const String baseUrl = 'https://rhemalize-church-audio-app.web.app/sermon';
    final String shareLink = '$baseUrl?id=${sermon.id}';

    final String shareText = '''
🎧 I'm listening to "${sermon.title}" by ${sermon.speaker} on Rhemalize!

Check out this powerful word here: $shareLink
''';
    SharePlus.instance.share(
        ShareParams(text: shareText, subject: 'Rhemalize - Share the Word'));
  }

  @override
  Widget build(BuildContext context) {
    final isSeries = sermon.messageType == MessageType.series;

    return GestureDetector(
      onTap: isSeries ? onViewSeries ?? onPlay : onPlay,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// BADGES + SHARE + FAVORITE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _badges()),

                      // Share Icon Button
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        icon: Icon(
                          Icons.share_outlined,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: _shareSermon,
                      ),

                      // Inside SermonCard's build method...
                      if (onToggleFavorite != null)
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color:
                                isFavorite ? Colors.red : Colors.grey.shade400,
                            size: 22,
                          ),
                          onPressed: () {
                            onToggleFavorite!();
                            // Added instant snackbar feedback
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isFavorite
                                    ? 'Removed from Favorites'
                                    : 'Added to Favorites'),
                                duration: const Duration(milliseconds: 800),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// TITLE
                  Text(
                    sermon.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// SPEAKER
                  Text(
                    sermon.speaker,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),

                  /// DESCRIPTION
                  if (sermon.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      sermon.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  /// META INFO
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 5),
                      Text(
                        _formatDate(sermon.date),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (!isSeries) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.access_time_outlined,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 5),
                        Text(
                          sermon.duration,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// PLAY BUTTON
                  _playButton(isSeries),
                ],
              ),
            ),

            /// CATEGORY BAR
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: sermon.category == SermonCategory.sunday
                    ? Colors.blue.shade400
                    : AppColors.primaryPurple,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badges() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _badge(
          sermon.messageType == MessageType.series ? 'Series' : 'Message',
          sermon.messageType == MessageType.series
              ? Colors.purple.shade50
              : Colors.blue.shade50,
          sermon.messageType == MessageType.series
              ? Colors.purple
              : Colors.blue,
        ),
        _badge(
          sermon.category == SermonCategory.sunday
              ? 'Sunday Service'
              : 'Wednesday Service',
          sermon.category == SermonCategory.sunday
              ? Colors.orange.shade50
              : Colors.green.shade50,
          sermon.category == SermonCategory.sunday
              ? Colors.orange.shade800
              : Colors.green.shade800,
        ),
      ],
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _playButton(bool isSeries) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isSeries ? onViewSeries ?? onPlay : onPlay,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSeries
                  ? Icons.library_music_outlined
                  : isPlayed
                      ? Icons.replay
                      : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isSeries
                  ? 'Explore Series'
                  : isPlayed
                      ? 'Listen Again'
                      : 'Play Message',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

