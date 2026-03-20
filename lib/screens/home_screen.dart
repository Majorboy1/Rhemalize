import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sermon_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/sermon_card.dart';
import '../models/sermon.dart';
import '../screens/series_detail_screen.dart'; // Ensure this matches your filename

enum FilterCategory { all, sunday, wednesday }

enum FilterType { all, series, single }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FilterCategory _selectedCategory = FilterCategory.all;
  FilterType _selectedType = FilterType.all;

  @override
  Widget build(BuildContext context) {
    final sermonProvider = context.watch<SermonProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final authProvider = context.read<AuthProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sermons = sermonProvider.sermons;
    final playedIds = audioProvider.playedSermonIds;
    final resumeTarget =
        _findResumeTarget(sermons, audioProvider.lastResumableId);
    final resumePosition = resumeTarget == null
        ? Duration.zero
        : audioProvider.getSavedPosition(resumeTarget.contentId);

    final filteredSermons = sermons.where((s) {
      bool catMatch = _selectedCategory == FilterCategory.all ||
          (s.category == SermonCategory.sunday &&
              _selectedCategory == FilterCategory.sunday) ||
          (s.category == SermonCategory.wednesday &&
              _selectedCategory == FilterCategory.wednesday);
      bool typeMatch = _selectedType == FilterType.all ||
          (s.messageType == MessageType.series &&
              _selectedType == FilterType.series) ||
          (s.messageType == MessageType.single &&
              _selectedType == FilterType.single);
      return catMatch && typeMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.primaryPurple,
      body: Stack(
        children: [
          _buildHeader(authProvider, sermons, isDark),
          Padding(
            padding: const EdgeInsets.only(top: 220),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (audioProvider.lastError != null) ...[
                      _buildPlaybackErrorCard(audioProvider),
                      const SizedBox(height: 16),
                    ],
                    if (resumeTarget != null &&
                        resumePosition > const Duration(seconds: 10)) ...[
                      _buildContinueListeningCard(
                        resumeTarget,
                        resumePosition,
                        sermons,
                        audioProvider,
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildFilters(sermons, isDark),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('All Sermons',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('${filteredSermons.length} messages',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: filteredSermons.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final sermon = filteredSermons[index];
                          return SermonCard(
                            sermon: sermon,
                            isFavorite: favoritesProvider.isFavorite(sermon.id),
                            isPlayed: playedIds.contains(sermon.id),
                            onToggleFavorite: () =>
                                favoritesProvider.toggleFavorite(sermon.id),
                            onPlay: () {
                              final audioPro = context.read<AudioProvider>();
                              if (sermon.messageType == MessageType.series) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SeriesDetailPage(
                                      series: sermon,
                                      allSermons:
                                          sermons, // FIXED: Added required argument
                                      onBack: () => Navigator.pop(context),
                                      playedSermons: playedIds,
                                      // FIXED: Removed undefined onPlayEpisode parameter
                                    ),
                                  ),
                                );
                              } else {
                                audioPro.playSermon(sermon, filteredSermons,
                                    PlaybackContext.home);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helper Methods ---

  Widget _buildPlaybackErrorCard(AudioProvider audioProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Playback Problem',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  audioProvider.lastError ?? 'Unknown playback error',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: audioProvider.clearLastError,
            icon: const Icon(Icons.close_rounded),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildContinueListeningCard(
    _ResumeTarget target,
    Duration position,
    List<Sermon> allSermons,
    AudioProvider audioProvider,
  ) {
    final progressText = _formatPosition(position);
    final imageUrl = target.imageUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (target.episode != null) {
          audioProvider.playEpisode(
            target.sermon,
            target.episode!,
            allSermons,
            PlaybackContext.home,
            resumeFromSavedPosition: true,
          );
        } else {
          audioProvider.playSermon(
            target.sermon,
            allSermons,
            PlaybackContext.home,
            resumeFromSavedPosition: true,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF32175E), Color(0xFF513B8F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF32175E).withOpacity(0.24),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl.isEmpty
                  ? const Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white, size: 30)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Continue Listening',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    target.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${target.subtitle} • $progressText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }

  _ResumeTarget? _findResumeTarget(List<Sermon> sermons, String? contentId) {
    if (contentId == null || contentId.isEmpty) return null;

    for (final sermon in sermons) {
      if (sermon.id == contentId) {
        return _ResumeTarget(
          contentId: sermon.id,
          sermon: sermon,
          title: sermon.title,
          subtitle: sermon.speaker,
          imageUrl: sermon.imageUrl,
        );
      }

      for (final episode in sermon.episodes) {
        if (episode.id == contentId) {
          return _ResumeTarget(
            contentId: episode.id,
            sermon: sermon,
            episode: episode,
            title: episode.title,
            subtitle: '${sermon.title} • ${episode.speaker}',
            imageUrl: episode.imageUrl ?? sermon.imageUrl,
          );
        }
      }
    }

    return null;
  }

  String _formatPosition(Duration position) {
    final hours = position.inHours;
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
  Widget _buildHeader(
      AuthProvider authProvider, List<Sermon> sermons, bool isDark) {
    final sundayCount =
        sermons.where((s) => s.category == SermonCategory.sunday).length;
    final wednesdayCount =
        sermons.where((s) => s.category == SermonCategory.wednesday).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rhemalize',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text("Hear God's Word Today",
                        style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _StaticRhemaLogo(size: 42, innerPadding: 7),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statCard('$sundayCount', 'Sunday Messages'),
              const SizedBox(width: 12),
              _statCard('$wednesdayCount', 'Wednesday Messages'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildFilters(List<Sermon> sermons, bool isDark) {
    final seriesCount =
        sermons.where((s) => s.messageType == MessageType.series).length;
    final singleCount =
        sermons.where((s) => s.messageType == MessageType.single).length;
    return Column(children: [
      Row(children: [
        _filterChip('All', _selectedCategory == FilterCategory.all, isDark,
            () => setState(() => _selectedCategory = FilterCategory.all)),
        const SizedBox(width: 8),
        _filterChip(
            'Sunday',
            _selectedCategory == FilterCategory.sunday,
            isDark,
            () => setState(() => _selectedCategory = FilterCategory.sunday)),
        const SizedBox(width: 8),
        _filterChip(
            'Wednesday',
            _selectedCategory == FilterCategory.wednesday,
            isDark,
            () => setState(() => _selectedCategory = FilterCategory.wednesday)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _filterChip('All Types', _selectedType == FilterType.all, isDark,
            () => setState(() => _selectedType = FilterType.all)),
        const SizedBox(width: 8),
        _filterChip('Series ($seriesCount)', _selectedType == FilterType.series,
            isDark, () => setState(() => _selectedType = FilterType.series)),
        const SizedBox(width: 8),
        _filterChip('Single ($singleCount)', _selectedType == FilterType.single,
            isDark, () => setState(() => _selectedType = FilterType.single)),
      ]),
    ]);
  }

  Widget _filterChip(
      String text, bool isActive, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryPurple
                : (isDark
                    ? Colors.white10
                    : AppColors.primaryPurple.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white70 : AppColors.primaryPurple))),
          ),
        ),
      ),
    );
  }
}

class _StaticRhemaLogo extends StatelessWidget {
  const _StaticRhemaLogo({
    required this.size,
    required this.innerPadding,
  });

  final double size;
  final double innerPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      padding: EdgeInsets.all(innerPadding),
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
    );
  }
}
class _ResumeTarget {
  const _ResumeTarget({
    required this.contentId,
    required this.sermon,
    required this.title,
    required this.subtitle,
    this.episode,
    this.imageUrl,
  });

  final String contentId;
  final Sermon sermon;
  final Episode? episode;
  final String title;
  final String subtitle;
  final String? imageUrl;
}