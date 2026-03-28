import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sermon.dart';
import '../providers/audio_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/sermon_provider.dart';
import '../utils/app_colors.dart';
import 'series_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _addToHistory(String term) async {
    if (term.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _searchHistory
        .removeWhere((item) => item.toLowerCase() == term.toLowerCase());
    _searchHistory.insert(0, term);
    if (_searchHistory.length > 5) {
      _searchHistory = _searchHistory.sublist(0, 5);
    }
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final favs = context.watch<FavoritesProvider>();
    final allSermons = context.watch<SermonProvider>().sermons;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Sermon> results = searchQuery.isEmpty
        ? []
        : allSermons.where((s) {
            final q = searchQuery.toLowerCase();
            return s.title.toLowerCase().contains(q) ||
                s.speaker.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(isDark),
            Expanded(
              child: searchQuery.isEmpty
                  ? _buildDefaultState(allSermons, audio, isDark)
                  : _buildResultsList(results, allSermons, audio, favs, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 84, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => searchQuery = v),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search titles or pastors...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryPurple,
                ),
                filled: true,
                fillColor:
                    isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: isDark
                      ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                      : BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: isDark
                      ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                      : BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(
    List<Sermon> results,
    List<Sermon> allSermons,
    AudioProvider audio,
    FavoritesProvider favs,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final sermon = results[index];
        final isSeries = sermon.messageType == MessageType.series;
        final accentColor =
            isSeries ? AppColors.primaryPurple : Colors.orangeAccent;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _addToHistory(searchQuery);
                  if (isSeries) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SeriesDetailPage(
                          series: sermon,
                          onBack: () => Navigator.pop(context),
                          allSermons: allSermons,
                          playedSermons: audio.playedSermonIds,
                        ),
                      ),
                    );
                  } else {
                    audio.playSermon(
                      sermon,
                      results.cast<Sermon>(),
                      PlaybackContext.home,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 75,
                            width: 75,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: const DecorationImage(
                                image:
                                    AssetImage('assets/images/rhema-logo.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              height: 12,
                              width: 12,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF1A1A1A)
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSeries ? 'SERIES' : 'SINGLE',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sermon.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSeries
                                  ? '${sermon.speaker} - ${sermon.episodes.length} episodes'
                                  : '${sermon.speaker} - Single Message',
                              style: TextStyle(
                                color:
                                    isDark ? Colors.white60 : Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          favs.isFavorite(sermon.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: favs.isFavorite(sermon.id)
                              ? Colors.redAccent
                              : Colors.grey.withValues(alpha: 0.5),
                        ),
                        onPressed: () => favs.toggleFavorite(sermon.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultState(
      List<Sermon> all, AudioProvider audio, bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (_searchHistory.isNotEmpty) _buildHistoryChips(isDark),
        _buildSectionTitle('Popular Searches', isDark),
        ...all
            .take(5)
            .map((s) => _buildSimpleDiscoveryCard(s, all, audio, isDark)),
      ],
    );
  }

  Widget _buildHistoryChips(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 42,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _searchHistory.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ActionChip(
                label: Text(
                  _searchHistory[index],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () =>
                    setState(() => searchQuery = _searchHistory[index]),
                backgroundColor:
                    isDark ? const Color(0xFF222222) : Colors.white,
                elevation: 0,
                side: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSimpleDiscoveryCard(
    Sermon s,
    List<Sermon> allSermons,
    AudioProvider audio,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/rhema-logo.png',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          s.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          s.messageType == MessageType.series
              ? '${s.speaker} - Series - ${s.episodes.length} episodes'
              : '${s.speaker} - Single Message',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        trailing: Icon(
          s.messageType == MessageType.series
              ? Icons.arrow_forward_ios_rounded
              : Icons.play_circle_fill_rounded,
          color: AppColors.primaryPurple,
          size: s.messageType == MessageType.series ? 20 : 32,
        ),
        onTap: () {
          if (s.messageType == MessageType.series) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SeriesDetailPage(
                  series: s,
                  onBack: () => Navigator.pop(context),
                  allSermons: allSermons,
                  playedSermons: audio.playedSermonIds,
                ),
              ),
            );
          } else {
            audio.playSermon(s, [s], PlaybackContext.home);
          }
        },
      ),
    );
  }
}

