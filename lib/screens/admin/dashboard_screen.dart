import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Dashboard Overview',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6A629E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.4,
              children: [
                _collectionCountCard(
                  'Total Sermons',
                  'sermons',
                  Icons.music_note,
                  const Color(0xFF5B5FDE),
                ),
                _collectionCountCard(
                  'Total Listens',
                  'listens',
                  Icons.play_circle_outline,
                  const Color(0xFF3F8CFF),
                ),
                _collectionCountCard(
                  'Total Users',
                  'users',
                  Icons.people_outline,
                  const Color(0xFF6A629E),
                ),
                _collectionCountCard(
                  'Active Pastors',
                  'pastors',
                  Icons.trending_up,
                  const Color(0xFF2FA38A),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Text(
              'Recent Sermons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sermons')
                  .orderBy('date', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No sermons uploaded yet.'),
                    ),
                  );
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _recentItem(
                      (data['title'] ?? 'Untitled').toString(),
                      (data['speaker'] ?? 'Unknown speaker').toString(),
                      ((data['playCount'] ?? 0) as num).toString(),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _collectionCountCard(
    String title,
    String collection,
    IconData icon,
    Color color,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final val =
            snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
        return _statCard(title, val, icon, color);
      },
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
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
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            val,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentItem(String title, String author, String views) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF0F0F0),
          child: Icon(Icons.music_note, color: Color(0xFF6A629E)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(author),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              views,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5B5FDE),
              ),
            ),
            const Text(
              'plays',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
