import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';

class AddSeriesModal extends StatefulWidget {
  const AddSeriesModal({super.key});

  @override
  State<AddSeriesModal> createState() => _AddSeriesModalState();
}

class _AddSeriesModalState extends State<AddSeriesModal> {
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;

  final List<String> _speakers = [
    "Pastor Bright Elliot",
    "Pastor Judith Elliot"
  ];
  String? _selectedSpeaker;
  String _selectedCategory = 'sunday';

  @override
  void initState() {
    super.initState();
    _selectedSpeaker = _speakers[0];
  }

  Future<void> _createSeries() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('sermons').add({
        'title': _titleController.text.trim(),
        'speaker': _selectedSpeaker,
        'imageUrl': _imageUrlController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'date': Timestamp.now(),
        'messageType': 'series',
        'category': _selectedCategory,
        'episodes': [],
        'playCount': 0,
        'description': 'New series collection',
        'duration': '',
        'audioUrl': '',
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text("Create New Series",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 25),
            _buildLabel("SERIES NAME"),
            _buildTextField(_titleController, "e.g. The Power of Faith",
                Icons.folder_outlined, isDark),
            _buildLabel("ASSIGNMENT"),
            Row(
              children: [
                Expanded(
                    child: _buildDropdown(_speakers, _selectedSpeaker!,
                        (v) => setState(() => _selectedSpeaker = v), isDark)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDropdown(
                        ['sunday', 'wednesday'],
                        _selectedCategory,
                        (v) => setState(() => _selectedCategory = v!),
                        isDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryPurple,
              letterSpacing: 1.1)));

  Widget _buildTextField(TextEditingController controller, String hint,
      IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: AppColors.primaryPurple),
          filled: true,
          fillColor:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF7F8FA),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String value,
      Function(String?) onChanged, bool isDark) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      decoration: InputDecoration(
          filled: true,
          fillColor:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF7F8FA),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none)),
      items: items
          .map((s) => DropdownMenuItem(
              value: s,
              child: Text(s.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600))))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createSeries,
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text("CREATE COLLECTION",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
