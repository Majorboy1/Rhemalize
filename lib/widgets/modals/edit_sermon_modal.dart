import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sermon.dart';
import '../../providers/sermon_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/pastor_directory.dart';

class EditSermonModal extends StatefulWidget {
  final Sermon sermon;

  const EditSermonModal({super.key, required this.sermon});

  @override
  State<EditSermonModal> createState() => _EditSermonModalState();
}

class _EditSermonModalState extends State<EditSermonModal> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late SermonCategory _selectedCategory;
  late String _selectedSpeaker;

  List<String> _speakerOptions = PastorDirectory.fallbackSpeakerNames;

  File? _newAudio;
  bool _isSaving = false;
  bool _isLoadingPastors = true;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.sermon.title);
    _descController = TextEditingController(text: widget.sermon.description);
    _selectedCategory = widget.sermon.category;
    _selectedSpeaker = widget.sermon.speaker;
    _loadSpeakers();
  }

  Future<void> _loadSpeakers() async {
    final speakerOptions = await PastorDirectory.loadSpeakerNames();
    if (!mounted) return;

    setState(() {
      _speakerOptions = speakerOptions;
      if (!_speakerOptions.contains(_selectedSpeaker)) {
        _selectedSpeaker = _speakerOptions.first;
      }
      _isLoadingPastors = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _newAudio = File(result.files.single.path!));
    }
  }

  void _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
    });

    try {
      await context.read<SermonProvider>().updateSermon(
            id: widget.sermon.id,
            title: _titleController.text.trim(),
            speaker: _selectedSpeaker,
            description: _descController.text.trim(),
            category: _selectedCategory,
            newAudioFile: _newAudio,
            onProgress: (progress) {
              setState(() => _uploadProgress = progress);
            },
          );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sermon updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating sermon: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Edit Sermon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 28),
            _buildSectionLabel('MESSAGE DETAILS'),
            _buildTextField(
              _titleController,
              'Title',
              Icons.title,
              isDarkMode,
            ),
            const SizedBox(height: 10),
            _buildSectionLabel('SPEAKER & CATEGORY'),
            _buildDropdownRow(isDarkMode),
            const SizedBox(height: 20),
            _buildSectionLabel('DESCRIPTION'),
            _buildTextField(
              _descController,
              'Description',
              Icons.notes,
              isDarkMode,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            _buildAudioPicker(isDarkMode),
            if (_isSaving && _newAudio != null) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: isDarkMode ? Colors.white10 : Colors.grey[200],
                color: AppColors.primaryPurple,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}% Uploaded',
                style: const TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                onPressed:
                    (_isSaving || _isLoadingPastors) ? null : _handleSave,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
        padding: EdgeInsets.only(bottom: 10, left: 4, top: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
            letterSpacing: 1.1,
          ),
        ),
      );

  Widget _buildDropdownRow(bool isDarkMode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumn = constraints.maxWidth < 430;
        final speaker = _buildDropdownField<String>(
          label: 'Speaker',
          icon: Icons.person_outline,
          initialValue: _selectedSpeaker,
          items: _speakerOptions,
          isDarkMode: isDarkMode,
          onChanged: (_isSaving || _isLoadingPastors)
              ? null
              : (value) => setState(() => _selectedSpeaker = value!),
        );
        final category = DropdownButtonFormField<SermonCategory>(
          initialValue: _selectedCategory,
          dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          decoration: _inputDecoration('Category', Icons.category, isDarkMode),
          items: SermonCategory.values
              .map(
                (cat) => DropdownMenuItem<SermonCategory>(
                  value: cat,
                  child: Text(cat.name),
                ),
              )
              .toList(),
          onChanged: _isSaving
              ? null
              : (value) => setState(() => _selectedCategory = value!),
        );

        if (useColumn) {
          return Column(
            children: [
              speaker,
              if (_isLoadingPastors)
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              const SizedBox(height: 12),
              category,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: speaker),
            const SizedBox(width: 12),
            Expanded(child: category),
          ],
        );
      },
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T initialValue,
    required List<T> items,
    required bool isDarkMode,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      isExpanded: true,
      dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
      decoration: _inputDecoration(label, icon, isDarkMode),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    bool isDarkMode,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDarkMode ? Colors.white60 : Colors.black54,
      ),
      prefixIcon: Icon(icon, color: AppColors.primaryPurple, size: 20),
      filled: true,
      fillColor: isDarkMode
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF7F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    bool isDarkMode, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: _inputDecoration(hint, icon, isDarkMode),
      ),
    );
  }

  Widget _buildAudioPicker(bool isDarkMode) {
    final hasFile = _newAudio != null;
    return InkWell(
      onTap: _isSaving ? null : _pickAudio,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasFile
              ? Colors.green.withValues(alpha: 0.05)
              : AppColors.primaryPurple.withValues(alpha: 0.05),
          border: Border.all(
            color: hasFile
                ? Colors.green
                : AppColors.primaryPurple.withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(
              hasFile ? Icons.check_circle : Icons.cloud_upload_outlined,
              color: hasFile ? Colors.green : AppColors.primaryPurple,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              _newAudio?.path.split('/').last ?? 'Tap to change audio file',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasFile ? Colors.green : AppColors.primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasFile ? 'New file selected' : 'Current audio will be kept',
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
