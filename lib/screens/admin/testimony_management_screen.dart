import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/testimony.dart';
import '../../providers/audio_provider.dart';
import '../../providers/testimony_provider.dart';

class TestimonyManagementScreen extends StatelessWidget {
  const TestimonyManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestimonyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.testimonies.isEmpty) {
      return Center(
        child: Text(
          'No testimonies uploaded yet.',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 15,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.testimonies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final testimony = provider.testimonies[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1D1D1D) : const Color(0xFFF7F7FB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.record_voice_over_rounded,
                    color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimony.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${testimony.speaker} • ${DateFormat.yMMMd().format(testimony.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: () =>
                    context.read<AudioProvider>().playTestimony(testimony),
              ),
              IconButton(
                icon:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                onPressed: () => _confirmDelete(context, testimony),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Testimony testimony) async {
    final testimonyProvider = context.read<TestimonyProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete testimony'),
        content:
            Text('Remove "${testimony.title}" from the testimonies catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await testimonyProvider.deleteTestimony(testimony.id);
    }
  }
}
