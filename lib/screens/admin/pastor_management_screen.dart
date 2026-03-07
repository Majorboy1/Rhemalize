import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class PastorManagementScreen extends StatelessWidget {
  const PastorManagementScreen({super.key});

  static const String pinnedPastorName = "Pastor Bright Elliot";

  void _showPastorModal(BuildContext context,
      {String? docId, String? name, String? role}) {
    final nameController = TextEditingController(text: name);
    final roleController = TextEditingController(text: role);
    final isEditing = docId != null;
    final isPinnedPastor = name == pinnedPastorName;
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
              Text(isEditing ? "Edit Speaker Details" : "Register New Speaker",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black)),
              const SizedBox(height: 25),
              TextField(
                  controller: nameController,
                  enabled:
                      !isPinnedPastor, // Prevent renaming the pinned pastor
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                  decoration: _inputDecoration(
                      "Full Name", Icons.person_outline, isDarkMode)),
              const SizedBox(height: 16),
              TextField(
                  controller: roleController,
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                  decoration: _inputDecoration(
                      "Title/Role (e.g. Senior Pastor)",
                      Icons.work_outline,
                      isDarkMode)),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (isEditing &&
                      !isPinnedPastor) // Hide delete for the pinned pastor
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
                        child: const Text("Delete"),
                      ),
                    ),
                  if (isEditing && !isPinnedPastor) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isEmpty) return;
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
                      child: Text(isEditing ? "Save Changes" : "Add Speaker"),
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
      fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50],
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
              child: Text("Speaker Directory",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF1A1A1A))),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pastors')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // LOGIC: Sort to keep Bright Elliot at the top
                  List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];
                  docs.sort((a, b) {
                    String nameA =
                        (a.data() as Map<String, dynamic>)['name'] ?? '';
                    String nameB =
                        (b.data() as Map<String, dynamic>)['name'] ?? '';
                    if (nameA == pinnedPastorName) return -1;
                    if (nameB == pinnedPastorName) return 1;
                    return 0;
                  });

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.82),
                    itemCount: docs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == docs.length)
                        return _addPastorCard(context, isDarkMode);
                      var data = docs[index].data() as Map<String, dynamic>;
                      return _pastorCard(
                          context,
                          docs[index].id,
                          data['name'] ?? 'Unknown',
                          data['role'] ?? 'Speaker',
                          isDarkMode);
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

  Widget _pastorCard(BuildContext context, String id, String name, String role,
      bool isDarkMode) {
    final bool isPinned = name == pinnedPastorName;

    return InkWell(
      onTap: () => _showPastorModal(context, docId: id, name: name, role: role),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isPinned
                ? Border.all(
                    color: AppColors.primaryPurple.withOpacity(0.5), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Stack(
          children: [
            // Pinned Badge
            if (isPinned)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified,
                          size: 14, color: AppColors.primaryPurple),
                      SizedBox(width: 4),
                      Text("LEAD",
                          style: TextStyle(
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
                              : AppColors.primaryPurple.withOpacity(0.1),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDarkMode ? Colors.white : Colors.black)),
                  ),
                  const SizedBox(height: 4),
                  Text(role,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.grey[600],
                          fontSize: 12)),
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
                color: AppColors.primaryPurple.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(24),
            color: AppColors.primaryPurple.withOpacity(0.02)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: AppColors.primaryPurple.withOpacity(0.5), size: 40),
            const SizedBox(height: 8),
            Text("Add New",
                style: TextStyle(
                    color: AppColors.primaryPurple.withOpacity(0.7),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
