import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../models/sermon.dart';
import '../../utils/app_colors.dart';
import '../../providers/auth_provider.dart';

class UploadSeriesScreen extends StatefulWidget {
  const UploadSeriesScreen({super.key});

  @override
  State<UploadSeriesScreen> createState() => _UploadSeriesScreenState();
}

class _UploadSeriesScreenState extends State<UploadSeriesScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  final List<String> _speakers = [
    'Pastor Bright Elliot',
    'Ma Judith Elliot',
  ];
  String? _selectedSpeaker;

  SermonCategory _selectedCategory = SermonCategory.sunday;
  MessageType _selectedMessageType = MessageType.series;

  List<EpisodeDraft> _episodeDrafts = [];

  @override
  void initState() {
    super.initState();
    _selectedSpeaker = _speakers[0];
    _addEpisode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    for (final draft in _episodeDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addEpisode() {
    setState(() {
      _episodeDrafts.add(EpisodeDraft(id: const Uuid().v4()));
    });
  }

  void _removeEpisode(int index) {
    if (_episodeDrafts.length > 1) {
      setState(() {
        final draft = _episodeDrafts.removeAt(index);
        draft.dispose();
      });
    }
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;

    final bool missingAudio = _episodeDrafts.any((e) {
      if (kIsWeb) return e.webAudioBytes == null;
      return e.audioFile == null;
    });

    if (missingAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an audio file for all episodes')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final authProv = Provider.of<AuthProvider>(context, listen: false);

    try {
      final String finalImageUrl = _imageUrlController.text.trim().isEmpty
          ? 'https://via.placeholder.com/300'
          : _imageUrlController.text.trim();

      if (_selectedMessageType == MessageType.series) {
        final List<Map<String, dynamic>> episodesData = [];

        for (int i = 0; i < _episodeDrafts.length; i++) {
          final e = _episodeDrafts[i];
          episodesData.add({
            'title': e.titleController.text.trim(),
            'audioFile': e.audioFile,
            'audioBytes': e.webAudioBytes,
            'speaker': _selectedSpeaker!,
            'description': _descriptionController.text.trim(),
            'order': i + 1,
          });
        }

        await authProv.uploadSeriesSermon(
          title: _titleController.text.trim(),
          pastor: _selectedSpeaker!,
          imageUrl: finalImageUrl,
          description: _descriptionController.text.trim(),
          episodes: episodesData,
          category: _selectedCategory.name,
          onProgress: (progress) {
            setState(() => _uploadProgress = progress);
          },
        );
      } else {
        final firstDraft = _episodeDrafts.first;
        await authProv.uploadOneTimeSermon(
          title: _titleController.text.trim(),
          pastor: _selectedSpeaker!,
          audioFile: firstDraft.audioFile,
          audioBytes: firstDraft.webAudioBytes,
          imageUrl: finalImageUrl,
          description: _descriptionController.text.trim(),
          category: _selectedCategory.name,
          onProgress: (progress) {
            setState(() => _uploadProgress = progress);
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content Published Successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAudioForEpisode(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: true,
    );

    if (result != null) {
      setState(() {
        final platformFile = result.files.single;
        _episodeDrafts[index].fileName = platformFile.name;

        if (kIsWeb) {
          _episodeDrafts[index].webAudioBytes = platformFile.bytes;
        } else {
          if (platformFile.path != null) {
            _episodeDrafts[index].audioFile = File(platformFile.path!);
          }
          _episodeDrafts[index].webAudioBytes = platformFile.bytes;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fieldColor =
        isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50]!;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Upload Content',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isUploading
          ? _buildUploadProgressUI(isDark)
          : Form(
              key: _formKey,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                children: [
                  _buildTypeSelector(isDark),
                  const SizedBox(height: 25),
                  _buildCategoryDropdown(fieldColor, isDark),
                  const SizedBox(height: 15),
                  Text(
                    _selectedMessageType == MessageType.series
                        ? 'Series Overview'
                        : 'Sermon Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(_titleController, 'Title', Icons.title,
                      fieldColor, isDark),
                  _buildSpeakerDropdown(fieldColor, isDark),
                  _buildTextField(_descriptionController, 'Description',
                      Icons.description_outlined, fieldColor, isDark,
                      maxLines: 3),
                  const Divider(height: 40),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final addButton = TextButton.icon(
                        onPressed: _addEpisode,
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppColors.primaryPurple),
                        label: const Text('Add Episode',
                            style: TextStyle(color: AppColors.primaryPurple)),
                      );

                      if (_selectedMessageType != MessageType.series) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Episodes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      }

                      if (constraints.maxWidth < 420) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Episodes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            addButton,
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Episodes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          addButton,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _episodeDrafts.length,
                    itemBuilder: (context, index) =>
                        _buildEpisodeCard(index, fieldColor, isDark),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _handlePublish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text(
                        'Publish Content',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _buildUploadProgressUI(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  strokeWidth: 8,
                  color: AppColors.primaryPurple,
                  backgroundColor: AppColors.primaryPurple.withOpacity(0.2),
                ),
              ),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text('Uploading content, please wait...',
              style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _typeBtn('Single', MessageType.single, Icons.mic, isDark),
          _typeBtn('Series', MessageType.series, Icons.library_music, isDark),
        ],
      ),
    );
  }

  Widget _typeBtn(String label, MessageType type, IconData icon, bool isDark) {
    final bool isSelected = _selectedMessageType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedMessageType = type;
          if (type == MessageType.single && _episodeDrafts.length > 1) {
            final firstDraft = _episodeDrafts.first;
            final extras = _episodeDrafts.skip(1).toList();
            for (final draft in extras) {
              draft.dispose();
            }
            _episodeDrafts = [firstDraft];
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : Colors.grey, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(Color bgColor, bool isDark) {
    return DropdownButtonFormField<SermonCategory>(
      isExpanded: true,
      value: _selectedCategory,
      dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration:
          _inputDecoration('Select Service Type', Icons.calendar_today, bgColor),
      items: const [
        DropdownMenuItem(
            value: SermonCategory.sunday, child: Text('Sunday Service')),
        DropdownMenuItem(
            value: SermonCategory.wednesday,
            child: Text('Wednesday Service')),
      ],
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }

  Widget _buildSpeakerDropdown(Color bgColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: _selectedSpeaker,
        dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration:
            _inputDecoration('Select Speaker', Icons.person_outline, bgColor),
        items: _speakers
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (val) => setState(() => _selectedSpeaker = val),
      ),
    );
  }

  Widget _buildEpisodeCard(int index, Color bgColor, bool isDark) {
    final draft = _episodeDrafts[index];
    final bool canDelete =
        _selectedMessageType == MessageType.series && _episodeDrafts.length > 1;

    return Card(
      key: ValueKey(draft.id),
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const Spacer(),
                if (canDelete)
                  IconButton(
                    onPressed: () => _removeEpisode(index),
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTextField(draft.titleController, 'Episode Title',
                Icons.subtitles_outlined, bgColor, isDark),
            const SizedBox(height: 2),
            InkWell(
              onTap: () => _pickAudioForEpisode(index),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: draft.fileName != null
                      ? Colors.green.withOpacity(0.05)
                      : bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: draft.fileName != null
                          ? Colors.green.withOpacity(0.5)
                          : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.audio_file_outlined,
                      color: draft.fileName != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        draft.fileName ?? 'Tap to Select Audio',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: draft.fileName != null
                              ? Colors.green
                              : Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (draft.fileName != null)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check_circle,
                            color: Colors.green, size: 18),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color bgColor) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: AppColors.primaryPurple),
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      filled: true,
      fillColor: bgColor,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, Color bgColor, bool isDark,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      validator: (val) =>
          (val == null || val.isEmpty) ? 'Field Required' : null,
      decoration: _inputDecoration(label, icon, bgColor),
    );
  }
}

class EpisodeDraft {
  final String id;
  final TextEditingController titleController = TextEditingController();
  File? audioFile;
  Uint8List? webAudioBytes;
  String? fileName;

  EpisodeDraft({required this.id});

  void dispose() {
    titleController.dispose();
  }
}
