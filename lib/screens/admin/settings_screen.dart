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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Settings",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6A629E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. APP CONFIGURATION SECTION
          _buildSectionTitle("App Configuration"),
          Container(
            decoration: _boxDecoration(),
            child: Column(
              children: [
                _buildSettingTile("App Name", "RHEMAlize", showEdit: true),
                const Divider(height: 1),
                _buildSettingTile("App Version", "1.0.0", showEdit: false),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text("Enable Notifications",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: const Text("Push notifications for new sermons",
                      style: TextStyle(fontSize: 12)),
                  value: _notificationsEnabled,
                  activeColor: Colors.green,
                  onChanged: (val) =>
                      setState(() => _notificationsEnabled = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // 2. DATA MANAGEMENT SECTION
          _buildSectionTitle("Data Management"),
          Container(
            decoration: _boxDecoration(),
            child: Column(
              children: [
                _buildActionTile("Export All Data",
                    Icons.cloud_download_outlined, Colors.blue),
                const Divider(height: 1),
                _buildActionTile(
                    "Backup Database", Icons.save_outlined, Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // 3. ACCOUNT SECTION
          _buildSectionTitle("Account"),
          Container(
            decoration: _boxDecoration(),
            child: ListTile(
              onTap: () => _handleLogout(context),
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout",
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.redAccent),
            ),
          ),

          const SizedBox(height: 40),
          const Center(
            child: Text(
              "Logged in as Admin",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
      );

  BoxDecoration _boxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      );

  Widget _buildSettingTile(String title, String value,
      {required bool showEdit}) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: const TextStyle(color: Colors.grey)),
      trailing: showEdit
          ? const Text("Edit",
              style: TextStyle(
                  color: Color(0xFF6A629E), fontWeight: FontWeight.bold))
          : null,
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Icon(icon, color: color, size: 20),
      onTap: () {
        // Implement logic for export/backup
      },
    );
  }
}
