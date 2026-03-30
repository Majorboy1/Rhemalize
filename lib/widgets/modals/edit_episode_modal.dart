import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sermon.dart';
import '../../providers/sermon_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/pastor_directory.dart';

class EditEpisodeModal extends StatefulWidget {
  final String seriesId;
  final Episode episode;

  const EditEpisodeModal({
    super.key,
    required this.seriesId,
    required this.episode,
  });

  @override
  State<EditEpisodeModal> createState() => _EditEpisodeModalState();
}

class _EditEpisodeModalState extends State<EditEpisodeModal> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedSpeaker;

  List<String> _speakerOptions = PastorDirectory.fallbackSpeakerNames;

  File? _newAudioFile;
  Uint8List? _webAudioBytes;
  String? _selectedFileName;

  bool _isSaving = false;
  bool _isPicking = false;
  bool _isLoadingPastors = true;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.episode.title);
    _descController = TextEditingController(text: widget.episode.description);
    _selectedSpeaker = widget.episode.speaker;
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
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        withData: kIsWeb,
      );

      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          if (kIsWeb) {
            _webAudioBytes = result.files.single.bytes;
            _newAudioFile = null;
          } else {
            _newAudioFile = File(result.files.single.path!);
            _webAudioBytes = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Picker Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
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
      await context.read<SermonProvider>().updateEpisode(
            seriesId: widget.seriesId,
            episodeId: widget.episode.id,
            title: _titleController.text.trim(),
            speaker: _selectedSpeaker,
            description: _descController.text.trim(),
            newAudioFile: _newAudioFile,
            newWebAudioBytes: _webAudioBytes,
            onProgress: (progress) {
              setState(() => _uploadProgress = progress);
            },
          );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Episode updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating episode: $e')),
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
        top: 12,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              'Edit Episode',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 25),
            _buildField(
              _titleController,
              'Episode Title',
              Icons.title,
              isDarkMode,
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedSpeaker,
              dropdownColor:
                  isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(
                'Speaker',
                Icons.person_outline,
                isDarkMode,
              ),
              items: _speakerOptions
                  .map(
                    (pastor) => DropdownMenuItem<String>(
                      value: pastor,
                      child: Text(
                        pastor,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (_isSaving || _isLoadingPastors)
                  ? null
                  : (value) => setState(() => _selectedSpeaker = value!),
            ),
            if (_isLoadingPastors)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            const SizedBox(height: 15),
            _buildField(
              _descController,
              'Description',
              Icons.notes,
              isDarkMode,
              maxLines: 2,
            ),
            _buildAudioPicker(isDarkMode),
            if (_isSaving &&
                (_newAudioFile != null || _webAudioBytes != null)) ...[
              const SizedBox(height: 25),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  minHeight: 8,
                  backgroundColor:
                      isDarkMode ? Colors.white10 : Colors.grey[200],
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${(_uploadProgress * 100).toStringAsFixed(0)}% Uploaded',
                  style: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
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
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                onPressed: (_isSaving || _isPicking || _isLoadingPastors)
                    ? null
                    : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
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
      prefixIcon: Icon(icon, color: AppColors.primaryPurple),
      filled: true,
      fillColor:
          isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isDarkMode, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: _inputDecoration(label, icon, isDarkMode),
      ),
    );
  }

  Widget _buildAudioPicker(bool isDarkMode) {
    return InkWell(
      onTap: (_isSaving || _isPicking) ? null : _pickAudio,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppColors.primaryPurple.withValues(alpha: 0.1)
              : const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            _isPicking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.audiotrack_outlined,
                    color: AppColors.primaryPurple,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFileName ?? 'Update Audio File',
                    style: TextStyle(
                      color: _selectedFileName != null
                          ? AppColors.primaryPurple
                          : (isDarkMode ? Colors.white70 : Colors.black87),
                      fontWeight: _selectedFileName != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_selectedFileName == null)
                    Text(
                      'Current file will be kept if none selected',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.white38 : Colors.black38,
                      ),
                    ),
                ],
              ),
            ),
            if (_selectedFileName != null)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryPurple,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
