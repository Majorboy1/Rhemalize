import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/sermon.dart';
import '../providers/audio_provider.dart';
import '../widgets/pastor_badge.dart';
import '../utils/app_colors.dart';

class SeriesDetailPage extends StatelessWidget {
  final Sermon series;
  final VoidCallback onBack;
  final List<Sermon>
      allSermons; // Added to pass the full context to the provider
  final Set<String> playedSermons;
  final bool isLoading;

  const SeriesDetailPage({
    super.key,
    required this.series,
    required this.onBack,
    required this.allSermons,
    required this.playedSermons,
    this.isLoading = false,
  });

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Episode> episodes = series.episodes;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Column(
        children: [
          // HEADER SECTION
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 30),
            decoration: const BoxDecoration(
              color: AppColors.primaryPurple,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onBack,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  series.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (series.description != null &&
                    series.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    series.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      series.speaker,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    SeniorPastorBadge(speaker: series.speaker),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${series.totalEpisodes} Episodes',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // EPISODES LIST SECTION
          Expanded(
            child: isLoading
                ? _buildSkeletonList(isDark)
                : episodes.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                        itemCount: episodes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final episode = episodes[index];
                          final isPlayed = playedSermons.contains(episode.id);

                          // Use context.watch to rebuild when the current track changes
                          final audioProv = context.watch<AudioProvider>();
                          final bool isCurrentlyPlaying =
                              audioProv.currentEpisode?.id == episode.id;

                          return _buildEpisodeItem(context, episode, isPlayed,
                              isCurrentlyPlaying, index + 1, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeItem(BuildContext context, Episode episode, bool isPlayed,
      bool isCurrentlyPlaying, int episodeNumber, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrentlyPlaying
            ? AppColors.primaryPurple.withOpacity(0.1) // Highlight if playing
            : (isDark ? Colors.white.withOpacity(0.05) : AppColors.gray50),
        borderRadius: BorderRadius.circular(16),
        border: isCurrentlyPlaying
            ? Border.all(color: AppColors.primaryPurple.withOpacity(0.3))
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // CALL UPDATED PROVIDER METHOD
          context.read<AudioProvider>().playEpisode(
                series,
                episode,
                allSermons,
                PlaybackContext.library,
              );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isCurrentlyPlaying
                      ? AppColors.primaryPurple
                      : (isDark ? Colors.black26 : Colors.white),
                  border: Border.all(
                      color: AppColors.primaryPurple.withOpacity(0.1)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCurrentlyPlaying
                      ? const Icon(Icons.bar_chart,
                          color: Colors.white, size: 20) // Animated-style icon
                      : Text(
                          episodeNumber.toString(),
                          style: const TextStyle(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isCurrentlyPlaying
                              ? AppColors.primaryPurple
                              : (isDark ? Colors.white : Colors.black87)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          episode.speaker,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : Colors.black.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SeniorPastorBadge(speaker: episode.speaker),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(_formatDate(episode.date),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                        const SizedBox(width: 15),
                        const Icon(Icons.access_time_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(episode.duration,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  isCurrentlyPlaying
                      ? Icons.pause_circle_filled
                      : (isPlayed
                          ? Icons.check_circle
                          : Icons.play_circle_fill),
                  color: isCurrentlyPlaying
                      ? AppColors.primaryPurple
                      : (isPlayed ? Colors.green : AppColors.primaryPurple),
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.grey.shade800 : Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('No episodes available for this series.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
