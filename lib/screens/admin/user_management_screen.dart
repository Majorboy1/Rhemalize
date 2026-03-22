import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum _UserFilter { all, active, admins, recent }

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _UserFilter _filter = _UserFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildErrorState(isDark, snapshot.error),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final totalUsers = users.length;
        final activeUsers = users.where(_isActive).length;
        final adminUsers = users.where((doc) {
          final data = doc.data();
          return _readRole(data) == 'admin';
        }).length;
        final recentUsers = users.where(_isRecent).length;
        final filteredUsers = _filterUsers(users);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statBox(totalUsers.toString(), 'Total', const Color(0xFFF8F7FF),
                      const Color(0xFF6A629E), Icons.people_alt_outlined),
                  _statBox(activeUsers.toString(), 'Active', const Color(0xFFE6FFFA),
                      const Color(0xFF38B2AC), Icons.bolt_rounded),
                  _statBox(adminUsers.toString(), 'Admins', const Color(0xFFEBF8FF),
                      const Color(0xFF3182CE), Icons.admin_panel_settings_outlined),
                  _statBox(recentUsers.toString(), 'Recent', const Color(0xFFFFF7ED),
                      const Color(0xFFEA580C), Icons.history_rounded),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search user name or email',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', _filter == _UserFilter.all,
                        () => setState(() => _filter = _UserFilter.all)),
                    _filterChip('Active', _filter == _UserFilter.active,
                        () => setState(() => _filter = _UserFilter.active)),
                    _filterChip('Admins', _filter == _UserFilter.admins,
                        () => setState(() => _filter = _UserFilter.admins)),
                    _filterChip('Recent', _filter == _UserFilter.recent,
                        () => setState(() => _filter = _UserFilter.recent)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registered Users (${filteredUsers.length})',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 30),
                    if (filteredUsers.isEmpty)
                      const Center(child: Text('No users found'))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final data = filteredUsers[index].data();
                          final String name = _readName(data);
                          final String email = _readEmail(data);
                          final String role = _readRole(data);
                          final String lastActive =
                              _formatTimestamp(_readTimestamp(data['lastActive']));
                          final bool isActiveUser = _isActive(filteredUsers[index]);

                          return _userTile(
                            name,
                            email,
                            role,
                            lastActive,
                            isActiveUser ? Colors.green : Colors.grey,
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

  Widget _buildErrorState(bool isDark, Object? error) {
    final String message = (error?.toString() ?? 'Unknown error').trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 30),
          const SizedBox(height: 12),
          Text(
            'Unable to load users right now.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterUsers(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> users) {
    return users.where((doc) {
      final data = doc.data();
      final name = _readName(data).toLowerCase();
      final email = _readEmail(data).toLowerCase();
      final role = _readRole(data);

      final matchesQuery =
          _query.isEmpty || name.contains(_query) || email.contains(_query);
      final matchesFilter = _filter == _UserFilter.all ||
          (_filter == _UserFilter.active && _isActive(doc)) ||
          (_filter == _UserFilter.admins && role == 'admin') ||
          (_filter == _UserFilter.recent && _isRecent(doc));

      return matchesQuery && matchesFilter;
    }).toList();
  }

  bool _isActive(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final timestamp = _readTimestamp(doc.data()['lastActive']);
    if (timestamp == null) return false;
    final diff = DateTime.now().difference(timestamp.toDate()).inDays;
    return diff <= 30;
  }

  bool _isRecent(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final timestamp = _readTimestamp(doc.data()['lastActive']);
    if (timestamp == null) return false;
    final diff = DateTime.now().difference(timestamp.toDate()).inDays;
    return diff <= 7;
  }

  String _readName(Map<String, dynamic> data) {
    final value = data['displayName'] ?? data['name'] ?? data['fullName'];
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Unknown User' : text;
  }

  String _readEmail(Map<String, dynamic> data) {
    final text = (data['email'] ?? '').toString().trim();
    return text.isEmpty ? 'No Email' : text;
  }

  String _readRole(Map<String, dynamic> data) {
    final text = (data['role'] ?? 'user').toString().trim().toLowerCase();
    return text.isEmpty ? 'user' : text;
  }

  Timestamp? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    return null;
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No activity yet';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _filterChip(String label, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _statBox(
      String val, String label, Color bg, Color col, IconData icon) {
    return SizedBox(
      width: 150,
      child: Container(
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
  }

  Widget _userTile(String name, String email, String role, String lastActive,
      Color statusCol, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6A629E).withOpacity(0.1),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Color(0xFF6A629E), fontWeight: FontWeight.bold)),
        ),
        title: Text(name,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text('$email\nLast active: $lastActive',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: statusCol.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(statusCol == Colors.green ? 'Active' : 'Idle',
                  style: TextStyle(
                      color: statusCol,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            Text(role.toUpperCase(),
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
