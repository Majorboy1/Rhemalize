import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/sermon_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/pastor_directory.dart';

class AddEpisodeModal extends StatefulWidget {
  final String seriesId;
  final int nextEpisodeNumber;

  const AddEpisodeModal({
    super.key,
    required this.seriesId,
    required this.nextEpisodeNumber,
  });

  @override
  State<AddEpisodeModal> createState() => _AddEpisodeModalState();
}

class _AddEpisodeModalState extends State<AddEpisodeModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  List<String> _speakerOptions = PastorDirectory.fallbackSpeakerNames;
  String _selectedSpeaker = PastorDirectory.fallbackSpeakerNames.first;

  File? _audioFile;
  Uint8List? _webAudioBytes;
  String? _fileName;

  bool _isLoading = false;
  bool _isLoadingPastors = true;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: kIsWeb,
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        if (kIsWeb) {
          _webAudioBytes = result.files.single.bytes;
        } else {
          _audioFile = File(result.files.single.path!);
        }
      });
    }
  }

  void _submit() async {
    final hasAudio = kIsWeb ? _webAudioBytes != null : _audioFile != null;

    if (_titleController.text.trim().isEmpty || !hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a title and select an audio file.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
    });

    try {
      await context.read<SermonProvider>().addEpisodeToSeries(
            seriesId: widget.seriesId,
            title: _titleController.text.trim(),
            speaker: _selectedSpeaker,
            description: _descController.text.trim(),
            audioFile: _audioFile,
            webAudioBytes: _webAudioBytes,
            episodeNumber: widget.nextEpisodeNumber,
            onProgress: (progress) {
              setState(() => _uploadProgress = progress);
            },
          );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Episode uploaded successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
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
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              'Add Episode ${widget.nextEpisodeNumber}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              _titleController,
              'Episode Title',
              Icons.title,
              isDarkMode,
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedSpeaker,
              decoration: _inputDecoration(
                'Speaker/Pastor',
                Icons.person_outline,
                isDarkMode,
              ),
              dropdownColor:
                  isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
              style: TextStyle(color: textColor),
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
              onChanged: (_isLoading || _isLoadingPastors)
                  ? null
                  : (value) => setState(() => _selectedSpeaker = value!),
            ),
            if (_isLoadingPastors)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            const SizedBox(height: 15),
            _buildTextField(
              _descController,
              'Description',
              Icons.notes,
              isDarkMode,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            _buildAudioPicker(isDarkMode),
            if (_isLoading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: isDarkMode ? Colors.white10 : Colors.grey[200],
                color: AppColors.primaryPurple,
              ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                  '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_isLoading || _isLoadingPastors) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Upload Episode',
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
          isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isDarkMode, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
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
      onTap: _isLoading ? null : _pickAudio,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppColors.primaryPurple.withValues(alpha: 0.1)
              : const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.audio_file, color: AppColors.primaryPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _fileName ?? 'Tap to select audio file',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight:
                      _fileName == null ? FontWeight.normal : FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_fileName != null)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }
}
