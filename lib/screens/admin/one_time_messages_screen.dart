import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sermon.dart';
import '../../providers/sermon_provider.dart';
import '../../providers/audio_provider.dart';
import '../../widgets/modals/add_sermon_modal.dart';
import '../../widgets/modals/edit_sermon_modal.dart';
import '../../utils/dialog_utils.dart';

class OneTimeMessagesScreen extends StatelessWidget {
  const OneTimeMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Consumer<SermonProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = provider.oneTimeMessages;

                if (docs.isEmpty) {
                  return const Center(
                      child: Text("No one-time sermons found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final sermon = docs[index];
                    return _buildMessageCard(context, sermon, docs);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Sermon Library",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ElevatedButton.icon(
            onPressed: () => _showAddModal(context),
            icon: const Icon(Icons.add),
            label: const Text("New Upload"),
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

  Widget _buildMessageCard(
      BuildContext context, Sermon sermon, List<Sermon> allSermons) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: ListTile(
        onTap: () {
          // ADMIN TEST PLAYBACK ON TAP
          context
              .read<AudioProvider>()
              .playSermon(sermon, allSermons, PlaybackContext.library);
        },
        leading: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(sermon.imageUrl ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Icon(Icons.mic))),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white70, size: 25),
          ],
        ),
        title: Text(sermon.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sermon.speaker),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') _openEditSheet(context, sermon);
            if (val == 'delete') _confirmDelete(context, sermon);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text("Edit Info")
                ])),
            const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Delete", style: TextStyle(color: Colors.red))
                ])),
          ],
        ),
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
    bool confirmed =
        await DialogUtils.showDeleteConfirmation(context, sermon.title);
    if (confirmed && context.mounted) {
      try {
        await context.read<SermonProvider>().deleteSermon(sermon.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sermon deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting sermon: $e")),
        );
      }
    }
  }

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddSermonModal());
  }
}
