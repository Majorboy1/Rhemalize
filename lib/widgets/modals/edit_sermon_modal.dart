import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../models/sermon.dart';
import '../../providers/sermon_provider.dart';

class EditSermonModal extends StatefulWidget {
  final Sermon sermon;

  const EditSermonModal({super.key, required this.sermon});

  @override
  State<EditSermonModal> createState() => _EditSermonModalState();
}

class _EditSermonModalState extends State<EditSermonModal> {
  late TextEditingController _titleController;
  late TextEditingController _speakerController;
  late TextEditingController _descController;
  late SermonCategory _selectedCategory;

  File? _newAudio;
  bool _isSaving = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.sermon.title);
    _speakerController = TextEditingController(text: widget.sermon.speaker);
    _descController = TextEditingController(text: widget.sermon.description);
    _selectedCategory = widget.sermon.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _speakerController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _newAudio = File(result.files.single.path!));
    }
  }

  void _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title cannot be empty")),
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
            speaker: _speakerController.text.trim(),
            description: _descController.text.trim(),
            category: _selectedCategory,
            newAudioFile: _newAudio,
            onProgress: (progress) {
              setState(() => _uploadProgress = progress);
            },
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sermon updated successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating sermon: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 12,
          left: 24,
          right: 24),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text("Edit Sermon",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),

            _buildTextField(_titleController, "Title", Icons.title),
            _buildTextField(_speakerController, "Speaker", Icons.person),
            _buildTextField(_descController, "Description", Icons.description,
                maxLines: 2),

            // Category Dropdown
            DropdownButtonFormField<SermonCategory>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: "Category",
                prefixIcon: const Icon(Icons.category),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              items: SermonCategory.values.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat.name));
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),

            const SizedBox(height: 15),

            // Audio Selector
            ListTile(
              leading: const Icon(Icons.audiotrack, color: Color(0xFF4A458C)),
              title: Text(
                _newAudio == null
                    ? "Change Audio (Optional)"
                    : _newAudio!.path.split('/').last,
                style: TextStyle(
                  color: _newAudio == null
                      ? Colors.black87
                      : const Color(0xFF4A458C),
                  fontWeight:
                      _newAudio == null ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: _newAudio != null
                  ? const Text("New file selected")
                  : const Text("Current audio will be kept"),
              onTap: _pickAudio,
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),

            // Progress Bar
            if (_isSaving && _newAudio != null) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF4A458C),
              ),
              const SizedBox(height: 8),
              Text(
                "${(_uploadProgress * 100).toStringAsFixed(0)}% Uploaded",
                style: const TextStyle(
                    color: Color(0xFF4A458C), fontWeight: FontWeight.bold),
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A458C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 0),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ))),
    );
  }
}
