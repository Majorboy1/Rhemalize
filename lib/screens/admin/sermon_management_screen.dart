import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sermon_provider.dart';
import '../../widgets/modals/edit_sermon_modal.dart';
import '../../utils/dialog_utils.dart';

class SermonManagementPage extends StatelessWidget {
  const SermonManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SermonProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sermons = provider.sermons;
        if (sermons.isEmpty) {
          return const Center(child: Text('No sermons found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sermons.length,
          itemBuilder: (context, index) {
            final sermon = sermons[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    sermon.imageUrl ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.library_music_outlined),
                    ),
                  ),
                ),
                title: Text(sermon.title),
                subtitle: Text(sermon.speaker),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editSermon(context, sermon),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, sermon.id, sermon.title),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String docId, String title) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(context, title);
    if (!confirmed || !context.mounted) return;

    try {
      await context.read<SermonProvider>().deleteSermon(docId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sermon deleted successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting sermon: $e')),
      );
    }
  }

  void _editSermon(BuildContext context, dynamic sermon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSermonModal(sermon: sermon),
    );
  }
}
