import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class AddSingleSermonModal extends StatefulWidget {
  const AddSingleSermonModal({super.key});

  @override
  State<AddSingleSermonModal> createState() => _AddSingleSermonModalState();
}

class _AddSingleSermonModalState extends State<AddSingleSermonModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedSpeaker = 'Pastor Bright Elliot';
  String _selectedCategory = 'sunday';

  File? _selectedAudioFile;
  Uint8List? _webAudioBytes;
  String? _selectedFileName;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isSuccess = false;

  void _handleUpload() async {
    final bool hasAudio =
        kIsWeb ? _webAudioBytes != null : _selectedAudioFile != null;

    if (_titleController.text.isEmpty || !hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Audio file are required')),
      );
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
            audioFile: _selectedAudioFile,
            audioBytes: _webAudioBytes,
            imageUrl: '',
            category: _selectedCategory,
            onProgress: (p) => setState(() => _uploadProgress = p),
          );

      if (!mounted) return;
      setState(() => _isSuccess = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFileName = result.files.single.name;
        if (kIsWeb) {
          _webAudioBytes = result.files.single.bytes;
          _selectedAudioFile = null;
        } else {
          _selectedAudioFile = File(result.files.single.path!);
          _webAudioBytes = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSuccess) return _buildSuccessState(isDark);

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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            Text('New Single Message',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 28),
            _buildSectionLabel('MESSAGE DETAILS'),
            _buildField(_titleController, 'Message Title', Icons.title, isDark),
            const SizedBox(height: 10),
            _buildSectionLabel('SPEAKER & CATEGORY'),
            _buildDropdowns(isDark),
            const SizedBox(height: 20),
            _buildSectionLabel('DESCRIPTION'),
            _buildField(_descController, 'What is this message about?',
                Icons.notes, isDark,
                maxLines: 2),
            const SizedBox(height: 10),
            _buildAudioPicker(isDark),
            if (_isUploading) _buildProgress(isDark),
            const SizedBox(height: 30),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4, top: 2),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
                letterSpacing: 1.1)),
      );

  Widget _buildDropdowns(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useColumn = constraints.maxWidth < 430;
        final speaker = _buildSimpleDropdown(
          ['Pastor Bright Elliot', 'Ma Judith Elliot'],
          _selectedSpeaker,
          (v) => setState(() => _selectedSpeaker = v!),
          isDark,
          'Speaker',
        );
        final category = _buildSimpleDropdown(
          ['sunday', 'wednesday'],
          _selectedCategory,
          (v) => setState(() => _selectedCategory = v!),
          isDark,
          'Category',
        );

        if (useColumn) {
          return Column(
            children: [
              speaker,
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

  Widget _buildField(
      TextEditingController controller, String hint, IconData icon, bool isDark,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryPurple, size: 20),
          filled: true,
          fillColor:
              isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F8FA),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSimpleDropdown(List<String> items, String value,
      Function(String?) onChanged, bool isDark, String label) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor:
            isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F8FA),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAudioPicker(bool isDark) {
    final bool hasFile = _selectedFileName != null;
    return InkWell(
      onTap: _pickAudio,
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
                width: 1),
            borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Icon(hasFile ? Icons.check_circle : Icons.cloud_upload_outlined,
                color: hasFile ? Colors.green : AppColors.primaryPurple,
                size: 30),
            const SizedBox(height: 8),
            Text(_selectedFileName ?? 'Tap to select audio file',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: hasFile ? Colors.green : AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(bool isDark) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          LinearProgressIndicator(
              value: _uploadProgress,
              color: AppColors.primaryPurple,
              backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.1)),
          const SizedBox(height: 5),
          Text('${(_uploadProgress * 100).toInt()}% uploaded',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54)),
        ],
      ));

  Widget _buildActionButton() => SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15))),
          onPressed: _isUploading ? null : _handleUpload,
          child: _isUploading
              ? const Text('UPLOADING...',
                  style: TextStyle(color: Colors.white70))
              : const Text('PUBLISH SERMON',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))));

  Widget _buildSuccessState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Colors.green, size: 80),
          const SizedBox(height: 20),
          Text('Published!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 10),
          Text('The message is now live for the congregation.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 30),
          SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DONE',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }
}

