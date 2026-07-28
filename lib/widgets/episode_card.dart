import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sermon.dart';
import '../providers/sermon_provider.dart';
import '../utils/app_colors.dart';

class EpisodeCard extends StatelessWidget {
  final Episode episode;
  final Sermon seriesInfo;
  final bool isPlaying;
  final bool isCurrentEpisode;
  final VoidCallback onPlay;
  final VoidCallback onPause;

  const EpisodeCard({
    super.key,
    required this.episode,
    required this.seriesInfo,
    required this.isPlaying,
    required this.isCurrentEpisode,
    required this.onPlay,
    required this.onPause,
  });

  String _formatDate(DateTime date) {
    return '${date.day} ${_month(date.month)}, ${date.year}';
  }

  String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isSeniorPastor = episode.speaker == 'Pastor Bright Elliot';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentEpisode
            ? Border.all(color: Colors.purple, width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: isPlaying && isCurrentEpisode ? onPause : onPlay,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isPlaying && isCurrentEpisode
                    ? const LinearGradient(
                        colors: [Colors.red, Colors.redAccent])
                    : const LinearGradient(
                        colors: [Colors.purple, Colors.deepPurple]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying && isCurrentEpisode ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Episode Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // Speaker
                Row(
                  children: [
                    Text(
                      episode.speaker,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray600),
                    ),
                    if (isSeniorPastor)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Senior Pastor',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Description
                if (episode.description.isNotEmpty)
                  Text(
                    episode.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.gray500),
                  ),
                const SizedBox(height: 6),
                // Meta info
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 12, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text(_formatDate(episode.date),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.gray500)),
                    const SizedBox(width: 12),
                    const Icon(Icons.schedule,
                        size: 12, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text(
                        context.select<SermonProvider, String>(
                            (p) => p.getEpisodeDuration(episode)),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.gray500)),
                  ],
                ),
                // Now Playing Indicator
                if (isCurrentEpisode && isPlaying)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Container(
                            width: 4,
                            height: 4,
                            color: Colors.red,
                            margin: const EdgeInsets.symmetric(horizontal: 1)),
                        Container(
                            width: 4,
                            height: 4,
                            color: Colors.red,
                            margin: const EdgeInsets.symmetric(horizontal: 1)),
                        Container(
                            width: 4,
                            height: 4,
                            color: Colors.red,
                            margin: const EdgeInsets.symmetric(horizontal: 1)),
                        const SizedBox(width: 6),
                        const Text('Now Playing',
                            style: TextStyle(fontSize: 10, color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
