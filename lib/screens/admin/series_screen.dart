import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sermon.dart';
import '../../providers/sermon_provider.dart';
import '../../widgets/modals/add_sermon_modal.dart';
import '../../widgets/modals/edit_sermon_modal.dart';
import '../../utils/dialog_utils.dart';
import 'series_detail_screen.dart';
import '../../utils/app_colors.dart';

enum _SeriesSortMode { newest, oldest, mostEpisodes, alphabetical }
enum _SeriesHealthFilter { all, healthy, needsAttention }

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _SeriesSortMode _sortMode = _SeriesSortMode.newest;
  _SeriesHealthFilter _healthFilter = _SeriesHealthFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _editSeries(BuildContext context, Sermon sermon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSermonModal(sermon: sermon),
    );
  }

  void _confirmDelete(BuildContext context, Sermon sermon) async {
    bool confirmed = await DialogUtils.showDeleteConfirmation(
        context, "series '${sermon.title}'");

    if (confirmed) {
      if (!context.mounted) return;

      try {
        await context.read<SermonProvider>().deleteSermon(sermon.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Series and all episodes removed immediately'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8F9FB),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sermon Series',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black)),
                ElevatedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddSermonModal(),
                  ),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('New Series'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SermonProvider>(
              builder: (context, provider, child) {
                final docs = _filteredSeries(provider.seriesMessages);
                final attentionCount = provider.seriesMessages
                    .where((sermon) => _needsAttention(sermon))
                    .length;

                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    _buildTools(provider.seriesMessages.length, attentionCount,
                        isDarkMode),
                    Expanded(
                      child: docs.isEmpty
                          ? Center(
                              child: Text('No series found.',
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white54
                                          : Colors.grey)),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final sermon = docs[index];
                                return InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SeriesDetailScreen(series: sermon),
                                    ),
                                  ),
                                  child: _buildSeriesCard(
                                      context, sermon, isDarkMode),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Sermon> _filteredSeries(List<Sermon> docs) {
    final filtered = docs.where((sermon) {
      final matchesQuery = _query.isEmpty ||
          sermon.title.toLowerCase().contains(_query) ||
          sermon.speaker.toLowerCase().contains(_query);
      final needsAttention = _needsAttention(sermon);
      final matchesHealth = _healthFilter == _SeriesHealthFilter.all ||
          (_healthFilter == _SeriesHealthFilter.healthy && !needsAttention) ||
          (_healthFilter == _SeriesHealthFilter.needsAttention && needsAttention);
      return matchesQuery && matchesHealth;
    }).toList();

    switch (_sortMode) {
      case _SeriesSortMode.newest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SeriesSortMode.oldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _SeriesSortMode.mostEpisodes:
        filtered.sort((a, b) => b.episodes.length.compareTo(a.episodes.length));
        break;
      case _SeriesSortMode.alphabetical:
        filtered.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return filtered;
  }

  bool _needsAttention(Sermon sermon) {
    final bool missingCover = sermon.imageUrl == null || sermon.imageUrl!.isEmpty;
    final bool noEpisodes = sermon.episodes.isEmpty;
    final bool missingEpisodeAudio = sermon.episodes.any((e) => e.audioUrl.isEmpty);
    return missingCover || noEpisodes || missingEpisodeAudio;
  }

  Widget _buildTools(int totalCount, int attentionCount, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryCard('Series', totalCount.toString(),
                    AppColors.primaryPurple, isDarkMode),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard('Need Attention', attentionCount.toString(),
                    Colors.orange, isDarkMode),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search title or speaker',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<_SeriesSortMode>(
                  value: _sortMode,
                  decoration: _dropdownDecoration(isDarkMode, 'Sort'),
                  dropdownColor:
                      isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  items: const [
                    DropdownMenuItem(
                        value: _SeriesSortMode.newest, child: Text('Newest')),
                    DropdownMenuItem(
                        value: _SeriesSortMode.oldest, child: Text('Oldest')),
                    DropdownMenuItem(
                        value: _SeriesSortMode.mostEpisodes,
                        child: Text('Most Episodes')),
                    DropdownMenuItem(
                        value: _SeriesSortMode.alphabetical,
                        child: Text('A-Z')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _sortMode = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<_SeriesHealthFilter>(
                  value: _healthFilter,
                  decoration: _dropdownDecoration(isDarkMode, 'Health'),
                  dropdownColor:
                      isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  items: const [
                    DropdownMenuItem(
                        value: _SeriesHealthFilter.all, child: Text('All')),
                    DropdownMenuItem(
                        value: _SeriesHealthFilter.healthy,
                        child: Text('Healthy')),
                    DropdownMenuItem(
                        value: _SeriesHealthFilter.needsAttention,
                        child: Text('Needs Attention')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _healthFilter = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(bool isDarkMode, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white60 : Colors.grey)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildSeriesCard(
      BuildContext context, Sermon sermon, bool isDarkMode) {
    final needsAttention = _needsAttention(sermon);
    final int missingEpisodeAudio =
        sermon.episodes.where((e) => e.audioUrl.isEmpty).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: needsAttention
            ? Border.all(color: Colors.orange.withOpacity(0.35))
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.04),
              blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              sermon.imageUrl ?? '',
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: isDarkMode ? Colors.white10 : Colors.grey[200],
                width: 70,
                height: 70,
                child: const Icon(Icons.folder),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sermon.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                Text('${sermon.episodes.length} Episodes',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                        fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip(Icons.bar_chart_rounded, '${sermon.playCount} plays',
                        Colors.blueGrey),
                    if (needsAttention)
                      _chip(Icons.warning_amber_rounded, 'Needs attention',
                          Colors.orange),
                    if (missingEpisodeAudio > 0)
                      _chip(Icons.audiotrack,
                          '$missingEpisodeAudio missing audio', Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: isDarkMode ? Colors.white70 : Colors.black54),
            onSelected: (val) {
              if (val == 'edit') _editSeries(context, sermon);
              if (val == 'delete') _confirmDelete(context, sermon);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Series'),
                    ],
                  )),
              PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  )),
            ],
          )
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
