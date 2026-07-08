import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sermon.dart';
import '../providers/audio_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/sermon_provider.dart';
import '../screens/series_detail_screen.dart';
import '../utils/app_colors.dart';
import '../widgets/sermon_card.dart';

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

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isScrolling = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 18;
      if (_isScrolling.value != scrolled) {
        _isScrolling.value = scrolled;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _isScrolling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sermonProvider = context.watch<SermonProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final authProvider = context.watch<AuthProvider>();

    final sermons = sermonProvider.sermons;
    final playedIds = audioProvider.playedSermonIds;
    final featuredSermon = sermons.isNotEmpty ? sermons.first : null;
    final resumeTarget =
        _findResumeTarget(sermons, audioProvider.lastResumableId);
    final resumePosition = resumeTarget == null
        ? Duration.zero
        : audioProvider.getSavedPosition(resumeTarget.contentId);

    final filteredSermons = sermons.where((sermon) {
      final categoryMatches = _selectedCategory == FilterCategory.all ||
          (sermon.category == SermonCategory.sunday &&
              _selectedCategory == FilterCategory.sunday) ||
          (sermon.category == SermonCategory.wednesday &&
              _selectedCategory == FilterCategory.wednesday);
      final typeMatches = _selectedType == FilterType.all ||
          (sermon.messageType == MessageType.series &&
              _selectedType == FilterType.series) ||
          (sermon.messageType == MessageType.single &&
              _selectedType == FilterType.single);
      return categoryMatches && typeMatches;
    }).toList();

    final sundayCount = sermons
        .where((sermon) => sermon.category == SermonCategory.sunday)
        .length;
    final wednesdayCount = sermons
        .where((sermon) => sermon.category == SermonCategory.wednesday)
        .length;
    final seriesCount = sermons
        .where((sermon) => sermon.messageType == MessageType.series)
        .length;
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EA),
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isScrolling,
                    builder: (context, scrolled, _) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: scrolled
                              ? Colors.white.withValues(alpha: 0.78)
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          boxShadow: scrolled
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 22,
                                    offset: const Offset(0, 10),
                                  ),
                                ]
                              : [],
                        ),
                        child: _buildTopBar(authProvider, scrolled),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F5F0),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              if (audioProvider.lastError != null) ...[
                                _buildPlaybackErrorCard(audioProvider),
                                const SizedBox(height: 16),
                              ],
                              _buildEditorialHero(
                                authProvider: authProvider,
                                featuredSermon: featuredSermon,
                                totalMessages: sermons.length,
                                playedCount: playedIds.length,
                                sundayCount: sundayCount,
                                seriesCount: seriesCount,
                              ),
                              const SizedBox(height: 18),
                              if (resumeTarget != null &&
                                  resumePosition >
                                      const Duration(seconds: 10)) ...[
                                _buildContinueListeningCard(
                                  target: resumeTarget,
                                  position: resumePosition,
                                  allSermons: sermons,
                                  audioProvider: audioProvider,
                                ),
                                const SizedBox(height: 18),
                              ],
                              _buildDailySpotlight(
                                featuredSermon: featuredSermon,
                                allSermons: sermons,
                                audioProvider: audioProvider,
                                sundayCount: sundayCount,
                                wednesdayCount: wednesdayCount,
                              ),
                              const SizedBox(height: 18),
                              _buildFilterSection(sermons),
                              const SizedBox(height: 22),
                              _buildSectionHeader(filteredSermons.length),
                              const SizedBox(height: 14),
                            ]),
                          ),
                        ),
                        filteredSermons.isEmpty
                            ? SliverFillRemaining(
                                hasScrollBody: false,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    18,
                                    0,
                                    18,
                                    110 + bottomInset,
                                  ),
                                  child: _buildEmptyState(),
                                ),
                              )
                            : SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                    18, 0, 18, 110 + bottomInset),
                                sliver: SliverList.separated(
                                  itemCount: filteredSermons.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final sermon = filteredSermons[index];
                                    return SermonCard(
                                      sermon: sermon,
                                      isFavorite: favoritesProvider
                                          .isFavorite(sermon.id),
                                      isPlayed: playedIds.contains(sermon.id),
                                      onToggleFavorite: () => favoritesProvider
                                          .toggleFavorite(sermon.id),
                                      onPlay: () => _openSermon(
                                        context: context,
                                        sermon: sermon,
                                        allSermons: sermons,
                                        playedIds: playedIds,
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSermon({
    required BuildContext context,
    required Sermon sermon,
    required List<Sermon> allSermons,
    required Set<String> playedIds,
  }) {
    if (sermon.messageType == MessageType.series) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeriesDetailPage(
            series: sermon,
            allSermons: allSermons,
            onBack: () => Navigator.pop(context),
            playedSermons: playedIds,
          ),
        ),
      );
      return;
    }

    context.read<AudioProvider>().playSermon(
          sermon,
          allSermons,
          PlaybackContext.home,
        );
  }

  Widget _buildBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF20102F), Color(0xFF6A3928), Color(0xFFC89861)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2C36B).withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            top: 180,
            right: 30,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AuthProvider authProvider, bool scrolled) {
    final displayName = authProvider.user?.displayName?.trim();
    final firstName = (displayName == null || displayName.isEmpty)
        ? 'Friend'
        : displayName.split(' ').first;
    final greeting = _buildGreeting(firstName);

    final titleColor = scrolled ? const Color(0xFF1F1712) : Colors.white;
    final subtitleColor = scrolled
        ? const Color(0xFF6B584D)
        : Colors.white.withValues(alpha: 0.76);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rhemalize',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                greeting,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A calm place to continue the Word.',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: scrolled
                ? const Color(0xFFF3E8D9)
                : Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const _SpinningRhemaLogo(size: 48, innerPadding: 9),
        ),
      ],
    );
  }

  String _buildGreeting(String firstName) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning, $firstName';
    }
    if (hour < 17) {
      return 'Good afternoon, $firstName';
    }
    if (hour < 22) {
      return 'Good evening, $firstName';
    }
    return 'Welcome back, $firstName';
  }

  Widget _buildEditorialHero({
    required AuthProvider authProvider,
    required Sermon? featuredSermon,
    required int totalMessages,
    required int playedCount,
    required int sundayCount,
    required int seriesCount,
  }) {
    final displayName = authProvider.user?.displayName?.trim();
    final firstName = (displayName == null || displayName.isEmpty)
        ? 'you'
        : displayName.split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B173A), Color(0xFF4F2A36), Color(0xFF8A5E34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'RHEMALIZE DAILY FEED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      featuredSermon?.title ?? 'Fresh messages ready for today',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      featuredSermon == null
                          ? 'Your content will show up here once sermons are available.'
                          : 'Start with ${featuredSermon.speaker} and keep building your listening rhythm, $firstName.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _buildArtworkTile(featuredSermon?.imageUrl, size: 92),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  value: '$totalMessages',
                  label: 'Messages Ready',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  value: '$playedCount',
                  label: 'Already Heard',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  value: '$sundayCount/$seriesCount',
                  label: 'Sunday / Series',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackErrorCard(AudioProvider audioProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFCACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 22,
          ),
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

  Widget _buildContinueListeningCard({
    required _ResumeTarget target,
    required Duration position,
    required List<Sermon> allSermons,
    required AudioProvider audioProvider,
  }) {
    final progressText = _formatPosition(position);

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        if (target.episode != null) {
          audioProvider.playEpisode(
            target.sermon,
            target.episode!,
            allSermons,
            PlaybackContext.home,
            resumeFromSavedPosition: true,
          );
          return;
        }

        audioProvider.playSermon(
          target.sermon,
          allSermons,
          PlaybackContext.home,
          resumeFromSavedPosition: true,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF4E3C7), Color(0xFFE7C89E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildArtworkTile(target.imageUrl, size: 78, radius: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Continue Listening',
                    style: TextStyle(
                      color: Color(0xFF6C5648),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    target.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF21140F),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    target.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF715A4C),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _estimateProgress(position),
                            minHeight: 8,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.55),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF4B2858),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        progressText,
                        style: const TextStyle(
                          color: Color(0xFF2C1A12),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF351F44),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySpotlight({
    required Sermon? featuredSermon,
    required List<Sermon> allSermons,
    required AudioProvider audioProvider,
    required int sundayCount,
    required int wednesdayCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6ECDD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFF9B6233),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Spotlight',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1611),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'A cleaner way to discover what to hear next.',
                      style: TextStyle(
                        color: Color(0xFF756254),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (featuredSermon != null) ...[
            Text(
              featuredSermon.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF21140F),
                height: 1.08,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${featuredSermon.speaker} - ${_categoryLabel(featuredSermon.category)}',
              style: const TextStyle(
                color: Color(0xFF765E4D),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _insightPill(
                    label: 'Sunday',
                    value: '$sundayCount',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _insightPill(
                    label: 'Wednesday',
                    value: '$wednesdayCount',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF351F44),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () => _openSermon(
                  context: context,
                  sermon: featuredSermon,
                  allSermons: allSermons,
                  playedIds: audioProvider.playedSermonIds,
                ),
                child: Text(
                  featuredSermon.messageType == MessageType.series
                      ? 'Open Series'
                      : 'Play Spotlight Message',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else ...[
            const Text(
              'No sermons yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF21140F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Once messages are uploaded, this area will highlight the best starting point for listeners.',
              style: TextStyle(
                color: Color(0xFF756254),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _insightPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A6558),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F1712),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(List<Sermon> sermons) {
    final seriesCount = sermons
        .where((sermon) => sermon.messageType == MessageType.series)
        .length;
    final singleCount = sermons
        .where((sermon) => sermon.messageType == MessageType.single)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse by lane',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E1611),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Use the filters below to shape the feed around what you want right now.',
          style: TextStyle(
            color: Color(0xFF7B6658),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _filterPill(
                label: 'Everything',
                isActive: _selectedCategory == FilterCategory.all,
                onTap: () =>
                    setState(() => _selectedCategory = FilterCategory.all),
              ),
              const SizedBox(width: 10),
              _filterPill(
                label: 'Sunday',
                isActive: _selectedCategory == FilterCategory.sunday,
                onTap: () =>
                    setState(() => _selectedCategory = FilterCategory.sunday),
              ),
              const SizedBox(width: 10),
              _filterPill(
                label: 'Wednesday',
                isActive: _selectedCategory == FilterCategory.wednesday,
                onTap: () => setState(
                  () => _selectedCategory = FilterCategory.wednesday,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _filterPill(
                label: 'All Types',
                isActive: _selectedType == FilterType.all,
                onTap: () => setState(() => _selectedType = FilterType.all),
              ),
              const SizedBox(width: 10),
              _filterPill(
                label: 'Series $seriesCount',
                isActive: _selectedType == FilterType.series,
                onTap: () => setState(() => _selectedType = FilterType.series),
              ),
              const SizedBox(width: 10),
              _filterPill(
                label: 'Single $singleCount',
                isActive: _selectedType == FilterType.single,
                onTap: () => setState(() => _selectedType = FilterType.single),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryPurple : const Color(0xFFF1E8DE),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? AppColors.primaryPurple : const Color(0xFFE2D5C7),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF654F42),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int resultCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sectionTitle(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1611),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Every message below keeps the same playback and favorites flow.',
                style: TextStyle(
                  color: Color(0xFF7B6658),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1E8DE),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$resultCount messages',
            style: const TextStyle(
              color: Color(0xFF6E594C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _sectionTitle() {
    final category = switch (_selectedCategory) {
      FilterCategory.sunday => 'Sunday',
      FilterCategory.wednesday => 'Wednesday',
      FilterCategory.all => 'All',
    };

    final type = switch (_selectedType) {
      FilterType.series => 'Series',
      FilterType.single => 'Single Messages',
      FilterType.all => 'Messages',
    };

    if (_selectedCategory == FilterCategory.all &&
        _selectedType == FilterType.all) {
      return 'Fresh For You';
    }

    return '$category $type';
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.headphones_rounded,
            size: 44,
            color: Color(0xFF8E735D),
          ),
          SizedBox(height: 14),
          Text(
            'Nothing matches these filters yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1611),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try switching the category or type filters to bring more messages into view.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B6658),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkTile(String? imageUrl,
      {required double size, double radius = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF2E2031),
        child: imageUrl != null && imageUrl.trim().isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                // Keep the layout stable even when remote artwork fails.
                errorBuilder: (_, __, ___) => _buildArtworkFallback(size),
              )
            : _buildArtworkFallback(size),
      ),
    );
  }

  Widget _buildArtworkFallback(double size) {
    return Container(
      color: const Color(0xFF2E2031),
      alignment: Alignment.center,
      child: Icon(
        Icons.multitrack_audio_rounded,
        color: Colors.white.withValues(alpha: 0.72),
        size: size * 0.38,
      ),
    );
  }

  String _categoryLabel(SermonCategory category) {
    switch (category) {
      case SermonCategory.sunday:
        return 'Sunday Service';
      case SermonCategory.wednesday:
        return 'Wednesday Service';
    }
  }

  double _estimateProgress(Duration position) {
    final seconds = position.inSeconds;
    if (seconds <= 0) return 0.08;
    if (seconds >= 3600) return 1.0;
    return (seconds / 3600).clamp(0.08, 1.0);
  }

  _ResumeTarget? _findResumeTarget(List<Sermon> sermons, String? contentId) {
    if (contentId == null || contentId.isEmpty) {
      return null;
    }

    // Episodes and single sermons share one resume entry point, so we resolve
    // the saved content id back to the exact playable item before building UI.
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
            subtitle: '${sermon.title} - ${episode.speaker}',
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
}

class _SpinningRhemaLogo extends StatefulWidget {
  const _SpinningRhemaLogo({required this.size, required this.innerPadding});

  final double size;
  final double innerPadding;

  @override
  State<_SpinningRhemaLogo> createState() => _SpinningRhemaLogoState();
}

class _SpinningRhemaLogoState extends State<_SpinningRhemaLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        height: widget.size,
        width: widget.size,
        padding: EdgeInsets.all(widget.innerPadding),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Image.asset(
          'assets/images/rhema-logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.auto_awesome, color: Colors.amber),
        ),
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
    required this.imageUrl,
    this.episode,
  });

  final String contentId;
  final Sermon sermon;
  final Episode? episode;
  final String title;
  final String subtitle;
  final String? imageUrl;
}
