import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];
        final totalUsers = users.length;
        // Logic for "Active" (e.g., users logged in within last 30 days)
        final activeUsers = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Active' || data['status'] == 'active';
        }).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "User Management",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // LIVE STAT BOXES
              Row(
                children: [
                  _statBox(
                      totalUsers.toString(),
                      "Total",
                      const Color(0xFFF8F7FF),
                      const Color(0xFF6A629E),
                      Icons.people_alt_outlined),
                  _statBox(
                      activeUsers.toString(),
                      "Active",
                      const Color(0xFFE6FFFA),
                      const Color(0xFF38B2AC),
                      Icons.person_outline),
                  _statBox("New", "Live", const Color(0xFFEBF8FF),
                      const Color(0xFF3182CE), Icons.bolt_rounded),
                ],
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 10)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Registered Users",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 30),

                    // LIVE USER LIST
                    if (users.isEmpty)
                      const Center(child: Text("No users found"))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final data =
                              users[index].data() as Map<String, dynamic>;
                          return _userTile(
                            data['displayName'] ?? 'Unknown User',
                            data['email'] ?? 'No Email',
                            data['status'] ?? 'Active',
                            (data['status'] == 'Inactive')
                                ? Colors.grey
                                : Colors.green,
                            isDark,
                          );
                        },
                      ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(
          String val, String label, Color bg, Color col, IconData icon) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              Icon(icon, color: col, size: 20),
              const SizedBox(height: 8),
              Text(val,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _userTile(String name, String email, String status, Color statusCol,
          bool isDark) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF6A629E).withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: const TextStyle(
                    color: Color(0xFF6A629E), fontWeight: FontWeight.bold)),
          ),
          title: Text(name,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87)),
          subtitle: Text(email,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusCol.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(status,
                style: TextStyle(
                    color: statusCol,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      );
}
