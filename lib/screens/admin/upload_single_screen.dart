import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class UploadSingleScreen extends StatefulWidget {
  const UploadSingleScreen({super.key});

  @override
  State<UploadSingleScreen> createState() => _UploadSingleScreenState();
}

class _UploadSingleScreenState extends State<UploadSingleScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _imageController = TextEditingController();

  String _selectedSpeaker = "Pastor Bright Elliot";
  String _selectedCategory = "sunday";

  File? _audioFile;
  Uint8List? _webAudioBytes;
  String? _selectedFileName;

  bool _isUploading = false;
  double _uploadProgress = 0.0; // Added for progress tracking

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFileName = result.files.single.name;
        if (kIsWeb) {
          _webAudioBytes = result.files.single.bytes;
          _audioFile = null;
        } else {
          _audioFile = File(result.files.single.path!);
          _webAudioBytes = null;
        }
      });
    }
  }

  void _handlePublish() async {
    final bool hasAudio = kIsWeb ? _webAudioBytes != null : _audioFile != null;

    if (_titleController.text.isEmpty || !hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Required: Title & Audio")));
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      await context.read<AuthProvider>().uploadOneTimeSermon(
            title: _titleController.text.trim(),
            pastor: _selectedSpeaker,
            description: _descController.text.trim(),
            audioFile: _audioFile,
            audioBytes: _webAudioBytes,
            imageUrl: _imageController.text.isEmpty
                ? ""
                : _imageController.text,
            category: _selectedCategory,
            onProgress: (progress) {
              setState(() => _uploadProgress = progress);
            },
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sermon Published Successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fieldBg =
        isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text("Upload Single Message",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isUploading
          ? _buildUploadProgressUI(isDark)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sermon Details",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 24),
                  _buildTextField(
                      _titleController, "Title", Icons.title, fieldBg, isDark),
                  _buildTextField(_imageController, "Image URL", Icons.image,
                      fieldBg, isDark),
                  _buildTextField(_descController, "Description",
                      Icons.description, fieldBg, isDark,
                      maxLines: 3),
                  const SizedBox(height: 10),
                  _buildAudioCard(isDark),
                  const SizedBox(height: 40),
                  _buildPublishButton(),
                ],
              ),
            ),
    );
  }

  // Progress UI matching the Series screen
  Widget _buildUploadProgressUI(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: _uploadProgress,
                    strokeWidth: 8,
                    backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                    color: AppColors.primaryPurple,
                  ),
                ),
                Text(
                  "${(_uploadProgress * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              "Uploading sermon...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please keep the app open",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon,
      Color bg, bool isDark,
      {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: isDark ? Colors.white10 : Colors.transparent)),
      child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: AppColors.primaryPurple),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          )),
    );
  }

  Widget _buildAudioCard(bool isDark) {
    bool hasFile = _selectedFileName != null;
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color:
                hasFile ? Colors.green.withOpacity(0.05) : Colors.transparent,
            border: Border.all(
              color: hasFile
                  ? Colors.green
                  : AppColors.primaryPurple.withOpacity(0.3),
              style: hasFile ? BorderStyle.solid : BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(15)),
        child: Column(children: [
          Icon(hasFile ? Icons.check_circle : Icons.cloud_upload_outlined,
              size: 40,
              color: hasFile ? Colors.green : AppColors.primaryPurple),
          const SizedBox(height: 10),
          Text(
            _selectedFileName ?? "Tap to Select Audio",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: hasFile
                    ? Colors.green
                    : (isDark ? Colors.white70 : Colors.black54)),
          )
        ]),
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _handlePublish,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: const Text("Publish Sermon",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }
}


