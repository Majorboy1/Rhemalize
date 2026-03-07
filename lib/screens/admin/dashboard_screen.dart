// lib/screens/admin/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dashboard Overview",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3E))),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.4,
            children: [
              _streamStatCard("Total Sermons", "one_time_messages",
                  Icons.music_note, Colors.indigo),
              _streamStatCard("Total Listens", "listens",
                  Icons.play_circle_outline, Colors.red),
              _streamStatCard("Total Users", "users", Icons.people_outline,
                  Colors.deepPurple),
              _streamStatCard(
                  "Active Pastors", "pastors", Icons.trending_up, Colors.green),
            ],
          ),
          const SizedBox(height: 25),
          const Text("Recent Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('one_time_messages')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return _recentItem(data['title'], data['pastor'],
                      data['views']?.toString() ?? "0");
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _streamStatCard(
      String title, String collection, IconData icon, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        String val =
            snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
        return _statCard(title, val, icon, color);
      },
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(val,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            child: Icon(Icons.music_note, color: Colors.grey)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(author),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(views, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text("plays",
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
