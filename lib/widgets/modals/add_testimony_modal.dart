import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/testimony_provider.dart';
import '../../utils/app_colors.dart';

class AddTestimonyModal extends StatefulWidget {
  const AddTestimonyModal({super.key});

  @override
  State<AddTestimonyModal> createState() => _AddTestimonyModalState();
}

class _AddTestimonyModalState extends State<AddTestimonyModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _speakerController = TextEditingController();
  final _descriptionController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _isSuccess = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _speakerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _selectedFile = result.files.first;
    });
  }

  Future<void> _submit() async {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    final testimonyProvider = context.read<TestimonyProvider>();

    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      scaffoldMessenger?.showSnackBar(
        const SnackBar(content: Text('Select an audio file before uploading.')),
      );
      return;
    }

    final selectedBytes = _selectedFile!.bytes;
    String? filePath = _selectedFile!.path;
    late final Uint8List audioBytes;

    if (selectedBytes != null) {
      audioBytes = selectedBytes;
    } else if (filePath != null && !kIsWeb) {
      audioBytes = await File(filePath).readAsBytes();
    } else {
      if (!mounted) return;
      scaffoldMessenger?.showSnackBar(
        const SnackBar(
            content: Text('Unable to read the selected audio file.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      await testimonyProvider.uploadTestimony(
        title: _titleController.text,
        speaker: _speakerController.text,
        description: _descriptionController.text,
        audioBytes: audioBytes,
        fileName: _selectedFile!.name,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress.clamp(0.0, 1.0));
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
        _isSuccess = true;
      });

      scaffoldMessenger?.clearSnackBars();
      scaffoldMessenger?.showSnackBar(
        const SnackBar(content: Text('Testimony uploaded successfully.')),
      );

      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) {
          navigator.pop();
        }
      });
    } catch (error) {
      if (!mounted) return;
      scaffoldMessenger?.showSnackBar(
        SnackBar(content: Text('Upload failed: $error')),
      );
    } finally {
      if (mounted && !_isSuccess) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSuccess) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 56, color: Colors.green.shade500),
            const SizedBox(height: 16),
            Text(
              'Testimony uploaded successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The testimony is now live in the app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Upload Testimony',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 18),
              _buildField(
                controller: _titleController,
                label: 'Testimony title',
                hint: 'Grace carried me through',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _speakerController,
                label: 'Speaker name',
                hint: 'Jane Doe',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Speaker is required'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _descriptionController,
                label: 'Testimony summary',
                hint: 'Describe the testimony and its impact.',
                maxLines: 4,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Summary is required'
                    : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickAudioFile,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryPurple.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.attach_file_rounded,
                            color: AppColors.primaryPurple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFile == null
                              ? 'Choose audio file'
                              : _selectedFile!.name,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _uploadProgress == 0 ? null : _uploadProgress,
                        minHeight: 6,
                        backgroundColor:
                            AppColors.primaryPurple.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(_uploadProgress * 100).round()}% uploaded',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isUploading
                      ? const Text('Uploading...')
                      : const Text('Upload testimony'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        filled: true,
        fillColor:
            isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.primaryPurple, width: 1.3),
        ),
      ),
    );
  }
}
