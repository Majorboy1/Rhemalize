import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6A629E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {},
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Announcements",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _announceCard(
              "Annual Thanksgiving Service",
              "Join us this Sunday for our special thanksgiving...",
              "2024-02-10"),
          _announceCard("Mid-week Breakthrough",
              "Don't miss the fire this Wednesday at 6 PM.", "2024-02-08"),
        ],
      ),
    );
  }

  Widget _announceCard(String title, String body, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(body,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
