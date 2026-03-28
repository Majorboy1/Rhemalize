import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics & Insights",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6A629E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard("Top Performing Sermons", [
              _topSermon("1", "Kingdom Living Series", "2156"),
              _topSermon("2", "Walking in Faith", "1245"),
              _topSermon("3", "The Power of Prayer", "892"),
            ]),
            const SizedBox(height: 20),
            _buildCard("Sermon Type Distribution", [
              _distBar("Series", 0.7, Colors.purpleAccent, "2 active"),
              _distBar("One-Time", 0.4, Colors.blueAccent, "1 active"),
            ]),
            const SizedBox(height: 20),
            _buildCard("Category Distribution", [
              _distBar("Sunday Service", 0.8, Colors.green, "2 items"),
              _distBar("Wednesday Service", 0.3, Colors.deepOrange, "1 item"),
            ]),
          ],
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0D1B3E))),
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
                backgroundColor: Colors.amber.shade100,
                child: Text(rank,
                    style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12))),
            const SizedBox(width: 15),
            Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
            Text(listens,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF6A629E))),
          ],
        ),
      );

  Widget _distBar(String label, double progress, Color col, String subtitle) =>
      Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey))
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            color: col,
            backgroundColor: Colors.grey.shade100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 20),
        ],
      );
}

