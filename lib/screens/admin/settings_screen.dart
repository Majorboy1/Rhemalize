import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6A629E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sermons').snapshots(),
        builder: (context, sermonSnapshot) {
          final sermonCount = sermonSnapshot.data?.docs.length ?? 0;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              final userCount = userSnapshot.data?.docs.length ?? 0;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Admin Account'),
                  Container(
                    decoration: _boxDecoration(),
                    child: Column(
                      children: [
                        _buildInfoTile(
                            'Signed In As', auth.user?.displayName ?? 'Admin'),
                        const Divider(height: 1),
                        _buildInfoTile('Email', auth.user?.email ?? '-'),
                        const Divider(height: 1),
                        _buildInfoTile(
                            'Role', (auth.userRole ?? 'admin').toUpperCase()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle('Application'),
                  Container(
                    decoration: _boxDecoration(),
                    child: Column(
                      children: [
                        _buildInfoTile('App Name', 'Rhemalize'),
                        const Divider(height: 1),
                        _buildInfoTile('Version', '1.2.0'),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text(
                            'Enable Notifications',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Local admin preference for update prompts',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _notificationsEnabled,
                          activeThumbColor: Colors.green,
                          onChanged: (val) {
                            setState(() => _notificationsEnabled = val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  val
                                      ? 'Notifications preference enabled.'
                                      : 'Notifications preference disabled.',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle('Live Overview'),
                  Row(
                    children: [
                      Expanded(
                          child: _statCard('Sermons', '$sermonCount',
                              Icons.library_music_outlined, Colors.deepPurple)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard('Users', '$userCount',
                              Icons.people_outline, Colors.blueAccent)),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle('Session'),
                  Container(
                    decoration: _boxDecoration(),
                    child: ListTile(
                      onTap: () => _handleLogout(context),
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('Exit the admin panel securely'),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    await auth.signOut();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      );

  BoxDecoration _boxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
        ],
      );

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(value, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
