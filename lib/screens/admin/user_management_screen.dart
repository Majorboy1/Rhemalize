import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

        final users =
            snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final filteredUsers = _filterUsers(users);
        final metrics = [
          _MetricData(
            value: users.length.toString(),
            label: 'Total',
            background: const Color(0xFFF8F7FF),
            color: const Color(0xFF6A629E),
            icon: Icons.people_alt_outlined,
          ),
          _MetricData(
            value: users.where(_isActive).length.toString(),
            label: 'Active',
            background: const Color(0xFFE6FFFA),
            color: const Color(0xFF38B2AC),
            icon: Icons.bolt_rounded,
          ),
          _MetricData(
            value: users.where((doc) => _readRole(doc.data()) == 'admin').length
                .toString(),
            label: 'Admins',
            background: const Color(0xFFEBF8FF),
            color: const Color(0xFF3182CE),
            icon: Icons.admin_panel_settings_outlined,
          ),
          _MetricData(
            value: users.where(_isRecent).length.toString(),
            label: 'Recent',
            background: const Color(0xFFFFF7ED),
            color: const Color(0xFFEA580C),
            icon: Icons.history_rounded,
          ),
        ];

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
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool useTwoColumns = constraints.maxWidth >= 520;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: metrics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: useTwoColumns ? 4 : 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: useTwoColumns ? 1.6 : 1.45,
                    ),
                    itemBuilder: (context, index) =>
                        _metricCard(metrics[index]),
                  );
                },
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
                width: double.infinity,
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
                    Text(
                      'Registered Users (${filteredUsers.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 30),
                    if (filteredUsers.isEmpty)
                      const Center(child: Text('No users found'))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final data = filteredUsers[index].data();
                          return _userCard(
                            name: _readName(data),
                            email: _readEmail(data),
                            role: _readRole(data),
                            lastActive:
                                _formatTimestamp(_readTimestamp(data['lastActive'])),
                            isActiveUser: _isActive(filteredUsers[index]),
                            isDark: isDark,
                          );
                        },
                      ),
                  ],
                ),
              ),
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

  Widget _metricCard(_MetricData metric) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: metric.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(metric.icon, color: metric.color, size: 20),
          const SizedBox(height: 12),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _userCard({
    required String name,
    required String email,
    required String role,
    required String lastActive,
    required bool isActiveUser,
    required bool isDark,
  }) {
    final Color statusColor = isActiveUser ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF6A629E).withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF6A629E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last active: $lastActive',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActiveUser ? 'Active' : 'Idle',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  role.toUpperCase(),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterUsers(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> users) {
    final filtered = users.where((doc) {
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

    filtered.sort((a, b) {
      final aTime = _readTimestamp(a.data()['lastActive'])?.toDate();
      final bTime = _readTimestamp(b.data()['lastActive'])?.toDate();
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return filtered;
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
}

class _MetricData {
  final String value;
  final String label;
  final Color background;
  final Color color;
  final IconData icon;

  const _MetricData({
    required this.value,
    required this.label,
    required this.background,
    required this.color,
    required this.icon,
  });
}
