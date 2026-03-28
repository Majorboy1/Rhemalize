import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/sermon_provider.dart';
import '../../utils/app_constants.dart';

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
  String _selectedSpeaker = AppConstants.availablePastors.first;

  File? _audioFile;
  Uint8List? _webAudioBytes;
  String? _fileName;

  bool _isLoading = false;
  double _uploadProgress = 0;

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
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
    bool hasAudio = kIsWeb ? _webAudioBytes != null : _audioFile != null;

    if (_titleController.text.trim().isEmpty || !hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please provide a title and select an audio file."),
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

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Episode uploaded successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              "Add Episode ${widget.nextEpisodeNumber}",
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 20),
            _buildTextField(_titleController, "Episode Title", Icons.title),

            // DROP DOWN FOR PASTOR
            DropdownButtonFormField<String>(
              initialValue: _selectedSpeaker,
              decoration: _inputDecoration("Speaker/Pastor", Icons.person),
              items: AppConstants.availablePastors.map((String pastor) {
                return DropdownMenuItem(value: pastor, child: Text(pastor));
              }).toList(),
              onChanged: (val) => setState(() => _selectedSpeaker = val!),
            ),
            const SizedBox(height: 15),

            _buildTextField(_descController, "Description", Icons.description,
                maxLines: 2),
            const SizedBox(height: 10),
            const Text(
              "Audio Content",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            _buildAudioPicker(),

            if (_isLoading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF4A458C),
              ),
              const SizedBox(height: 5),
              Center(
                  child:
                      Text("${(_uploadProgress * 100).toStringAsFixed(0)}%")),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A458C),
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
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Upload Episode",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black),
        decoration: _inputDecoration(label, icon),
      ),
    );
  }

  Widget _buildAudioPicker() {
    return InkWell(
      onTap: _isLoading ? null : _pickAudio,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4A458C).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.audio_file, color: Color(0xFF4A458C)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _fileName ?? "Tap to select audio file",
                style: TextStyle(
                  color: const Color(0xFF4A458C),
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

