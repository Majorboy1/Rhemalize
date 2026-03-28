import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class PastorManagementScreen extends StatefulWidget {
  const PastorManagementScreen({super.key});

  @override
  State<PastorManagementScreen> createState() => _PastorManagementScreenState();
}

class _PastorManagementScreenState extends State<PastorManagementScreen> {
  static const List<Map<String, String>> _defaultPinnedPastors = [
    {
      'id': 'virtual-bright',
      'name': 'Pastor Bright Elliot',
      'role': 'Lead Pastor',
    },
    {
      'id': 'virtual-judith',
      'name': 'Ma Judith Elliot',
      'role': 'Associate Pastor',
    },
  ];

  void _showPastorModal(BuildContext context,
      {String? docId, String? name, String? role, bool readOnly = false}) {
    final nameController = TextEditingController(text: name);
    final roleController = TextEditingController(text: role);
    final isEditing = docId != null && !readOnly;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 12,
          left: 24,
          right: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                readOnly
                    ? 'Pinned Speaker'
                    : (isEditing ? 'Edit Speaker Details' : 'Register New Speaker'),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: nameController,
                enabled: !readOnly,
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: _inputDecoration(
                    'Full Name', Icons.person_outline, isDarkMode),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                enabled: !readOnly,
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: _inputDecoration(
                    'Title/Role (e.g. Senior Pastor)',
                    Icons.work_outline,
                    isDarkMode),
              ),
              const SizedBox(height: 24),
              if (readOnly)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close'),
                  ),
                )
              else
                Row(
                  children: [
                    if (isEditing)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.read<AuthProvider>().deletePastor(docId);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                    if (isEditing) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          if (isEditing) {
                            context.read<AuthProvider>().updatePastor(
                                docId: docId,
                                name: nameController.text.trim(),
                                role: roleController.text.trim());
                          } else {
                            context.read<AuthProvider>().createNewPastor(
                                name: nameController.text.trim(),
                                role: roleController.text.trim());
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isEditing ? 'Save Changes' : 'Add Speaker'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String label, IconData icon, bool isDarkMode) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(color: isDarkMode ? Colors.white60 : Colors.black54),
      prefixIcon: Icon(icon, color: AppColors.primaryPurple),
      filled: true,
      fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              child: Text('Speaker Directory',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF1A1A1A))),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('pastors').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(isDarkMode, snapshot.error);
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = [...?snapshot.data?.docs];
                  final mergedCards = _buildPastorCards(docs);

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: mergedCards.length + 1,
                    itemBuilder: (context, index) {
                      if (index == mergedCards.length) {
                        return _addPastorCard(context, isDarkMode);
                      }
                      final card = mergedCards[index];
                      return _pastorCard(
                        context,
                        card['id']!,
                        card['name']!,
                        card['role']!,
                        isDarkMode,
                        readOnly: card['readOnly'] == 'true',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _buildPastorCards(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final List<Map<String, String>> cards = docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': (data['name'] ?? 'Unknown').toString(),
        'role': (data['role'] ?? data['title'] ?? 'Speaker').toString(),
        'readOnly': 'false',
      };
    }).toList();

    final existingNames = cards
        .map((card) => _normalizeName(card['name'] ?? ''))
        .toSet();

    for (final pinned in _defaultPinnedPastors) {
      if (!existingNames.contains(_normalizeName(pinned['name']!))) {
        cards.add({...pinned, 'readOnly': 'true'});
      }
    }

    cards.sort((a, b) {
      final priorityCompare = _sortPriority(a['name'] ?? '')
          .compareTo(_sortPriority(b['name'] ?? ''));
      if (priorityCompare != 0) return priorityCompare;
      return (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase());
    });

    return cards;
  }

  Widget _buildErrorState(bool isDarkMode, Object? error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            const Text(
              'Unable to load speakers right now.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _sortPriority(String name) {
    final normalized = _normalizeName(name);
    if (normalized.contains('bright elliot')) return 0;
    if (normalized.contains('judith elliot')) return 1;
    return 2;
  }

  bool _isPinnedName(String name) {
    final normalized = _normalizeName(name);
    return normalized.contains('bright elliot') ||
        normalized.contains('judith elliot');
  }

  String _normalizeName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '').trim();
  }

  Widget _pastorCard(BuildContext context, String id, String name, String role,
      bool isDarkMode,
      {bool readOnly = false}) {
    final bool isPinned = _isPinnedName(name);
    final bool isLead = _normalizeName(name).contains('bright elliot');

    return InkWell(
      onTap: () => _showPastorModal(context,
          docId: readOnly ? null : id,
          name: name,
          role: role,
          readOnly: readOnly),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isPinned
                ? Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.5), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Stack(
          children: [
            if (isPinned)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified,
                          size: 14, color: AppColors.primaryPurple),
                      const SizedBox(width: 4),
                      Text(isLead ? 'PINNED' : 'SECOND',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPurple)),
                    ],
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isPinned
                              ? AppColors.primaryPurple
                              : AppColors.primaryPurple.withValues(alpha: 0.1),
                          width: 2),
                    ),
                    child: CircleAvatar(
                        radius: 35,
                        backgroundColor: isDarkMode
                            ? Colors.white10
                            : const Color(0xFFF0EEFF),
                        child: const Icon(Icons.person,
                            color: AppColors.primaryPurple, size: 40)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDarkMode ? Colors.white : Colors.black)),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(role,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color:
                                isDarkMode ? Colors.white54 : Colors.grey[600],
                            fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addPastorCard(BuildContext context, bool isDarkMode) {
    return InkWell(
      onTap: () => _showPastorModal(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.3),
                width: 2,
                style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(24),
            color: AppColors.primaryPurple.withValues(alpha: 0.02)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: AppColors.primaryPurple.withValues(alpha: 0.5), size: 40),
            const SizedBox(height: 8),
            Text('Add New',
                style: TextStyle(
                    color: AppColors.primaryPurple.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}



