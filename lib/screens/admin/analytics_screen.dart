import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/sermon.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Analytics & Insights',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6A629E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('sermons').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildMessageState('Unable to load analytics right now.');
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sermons = snapshot.data!.docs
              .map((doc) => Sermon.fromFirestore(doc.data(), doc.id))
              .toList();

          if (sermons.isEmpty) {
            return _buildMessageState(
                'Analytics will appear once sermons exist.');
          }

          final sorted = [...sermons]
            ..sort((a, b) => b.playCount.compareTo(a.playCount));
          final topSermons = sorted.take(3).toList();

          final int total = sermons.length;
          final int seriesCount =
              sermons.where((s) => s.messageType == MessageType.series).length;
          final int singleCount = total - seriesCount;
          final int sundayCount =
              sermons.where((s) => s.category == SermonCategory.sunday).length;
          final int wednesdayCount = total - sundayCount;
          final int totalListens = sermons.fold<int>(
            0,
            (totalCount, sermon) => totalCount + sermon.playCount,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow(totalListens, total,
                    topSermons.isEmpty ? 0 : topSermons.first.playCount),
                const SizedBox(height: 20),
                _buildCard(
                  'Top Performing Sermons',
                  topSermons
                      .asMap()
                      .entries
                      .map(
                        (entry) => _topSermon(
                          '${entry.key + 1}',
                          entry.value.title,
                          '${entry.value.playCount}',
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                _buildCard(
                  'Sermon Type Distribution',
                  [
                    _distBar(
                      'Series',
                      total == 0 ? 0 : seriesCount / total,
                      const Color(0xFF6A629E),
                      '$seriesCount items',
                    ),
                    _distBar(
                      'One-Time',
                      total == 0 ? 0 : singleCount / total,
                      const Color(0xFF3F8CFF),
                      '$singleCount items',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildCard(
                  'Category Distribution',
                  [
                    _distBar(
                      'Sunday Service',
                      total == 0 ? 0 : sundayCount / total,
                      const Color(0xFF2FA38A),
                      '$sundayCount items',
                    ),
                    _distBar(
                      'Wednesday Service',
                      total == 0 ? 0 : wednesdayCount / total,
                      const Color(0xFF7E8AA2),
                      '$wednesdayCount items',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryRow(int totalListens, int totalSermons, int topPlayCount) {
    return Row(
      children: [
        Expanded(child: _summaryCard('Total Listens', '$totalListens')),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Sermons', '$totalSermons')),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Top Plays', '$topPlayCount')),
      ],
    );
  }

  Widget _summaryCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0D1B3E),
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      );

  Widget _topSermon(String rank, String title, String listens) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFFE7EAFE),
              child: Text(
                rank,
                style: const TextStyle(
                  color: Color(0xFF5B5FDE),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              listens,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A629E),
              ),
            ),
          ],
        ),
      );

  Widget _distBar(String label, double progress, Color col, String subtitle) =>
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            color: col,
            backgroundColor: Colors.grey.shade100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 20),
        ],
      );
}
