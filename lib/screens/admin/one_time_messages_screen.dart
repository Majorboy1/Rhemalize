import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sermon.dart';
import '../../providers/sermon_provider.dart';
import '../../providers/audio_provider.dart';
import '../../widgets/modals/add_sermon_modal.dart';
import '../../widgets/modals/edit_sermon_modal.dart';
import '../../utils/dialog_utils.dart';

enum _SingleSortMode { newest, oldest, mostPlayed, alphabetical }

class OneTimeMessagesScreen extends StatefulWidget {
  const OneTimeMessagesScreen({super.key});

  @override
  State<OneTimeMessagesScreen> createState() => _OneTimeMessagesScreenState();
}

class _OneTimeMessagesScreenState extends State<OneTimeMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _SingleSortMode _sortMode = _SingleSortMode.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Consumer<SermonProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filtered = _filteredMessages(provider.oneTimeMessages);

                  return Column(
                    children: [
                      _buildTools(provider.oneTimeMessages.length),
                      if (filtered.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final sermon = filtered[index];
                            return _buildMessageCard(context, sermon, filtered);
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Sermon> _filteredMessages(List<Sermon> docs) {
    final filtered = docs.where((sermon) {
      final matchesQuery = _query.isEmpty ||
          sermon.title.toLowerCase().contains(_query) ||
          sermon.speaker.toLowerCase().contains(_query) ||
          sermon.description.toLowerCase().contains(_query);

      return matchesQuery;
    }).toList();

    switch (_sortMode) {
      case _SingleSortMode.newest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SingleSortMode.oldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _SingleSortMode.mostPlayed:
        filtered.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case _SingleSortMode.alphabetical:
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return filtered;
  }

  Widget _buildTools(int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  label: 'Singles',
                  value: totalCount.toString(),
                  color: const Color(0xFF4A458C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search title, speaker, description',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
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
                child: DropdownButtonFormField<_SingleSortMode>(
                  initialValue: _sortMode,
                  decoration: _dropdownDecoration('Sort'),
                  items: const [
                    DropdownMenuItem(
                        value: _SingleSortMode.newest, child: Text('Newest')),
                    DropdownMenuItem(
                        value: _SingleSortMode.oldest, child: Text('Oldest')),
                    DropdownMenuItem(
                        value: _SingleSortMode.mostPlayed,
                        child: Text('Most Played')),
                    DropdownMenuItem(
                        value: _SingleSortMode.alphabetical,
                        child: Text('A-Z')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _sortMode = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(
      BuildContext context, Sermon sermon, List<Sermon> allSermons) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () {
          context
              .read<AudioProvider>()
              .playSermon(sermon, allSermons, PlaybackContext.library);
        },
        leading: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                sermon.imageUrl ?? '',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[200],
                  child: const Icon(Icons.mic),
                ),
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white70, size: 26),
          ],
        ),
        title: Text(sermon.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sermon.speaker),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _infoChip(Icons.bar_chart_rounded, '${sermon.playCount} plays',
                    Colors.blueGrey),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') _openEditSheet(context, sermon);
            if (val == 'delete') _confirmDelete(context, sermon);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit Info')
                ])),
            PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red))
                ])),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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

  Widget _summaryCard(
      {required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Sermon Library',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ElevatedButton.icon(
            onPressed: () => _showAddModal(context),
            icon: const Icon(Icons.add),
            label: const Text('New Upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A458C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context, Sermon sermon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSermonModal(sermon: sermon),
    );
  }

  void _confirmDelete(BuildContext context, Sermon sermon) async {
    final provider = context.read<SermonProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed =
        await DialogUtils.showDeleteConfirmation(context, sermon.title);
    if (!context.mounted || !confirmed) {
      return;
    }
    try {
      await provider.deleteSermon(sermon.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Sermon deleted successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error deleting sermon: ')),
      );
    }
  }

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSermonModal(),
    );
  }
}

