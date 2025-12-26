import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class ClubCreatePage extends StatefulWidget {
  const ClubCreatePage({super.key});

  @override
  State<ClubCreatePage> createState() => _ClubCreatePageState();
}

class _ClubCreatePageState extends State<ClubCreatePage> {
  final TextEditingController _nameController = TextEditingController();
  int _memberCount = 10;
  bool _isLoading = false;
  final int currentUserId = 1;

  File? _clubImageFile;
  Uint8List? _clubImageBytes;
  String? _base64Image;

  Future<void> _pickImage() async {
    // 'withData: true' to ensure bytes are available on Web
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      Uint8List? bytes;

      if (kIsWeb || file.bytes != null) {
        // On Web or if bytes provided
        bytes = file.bytes;
        _clubImageBytes = bytes;
      } else if (file.path != null) {
        // On Mobile/Desktop, use the file path
        bytes = await File(file.path!).readAsBytes();
        _clubImageFile = File(file.path!);
        _clubImageBytes = null;
      }

      if (bytes != null) {
        setState(() {
          // Convert to base64 for upload
          _base64Image = base64Encode(bytes!);
        });
      }
    }
  }

  Future<void> _createClub() async {
    if (_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('동아리 프로필 이미지를 등록해 주세요.')),
      );
      return;
    }

    final uri = Uri.parse('http://192.168.45.62:5000/clubs');
    final body = jsonEncode({
      'name': _nameController.text.trim(),
      'description': '${_nameController.text.trim()} 동아리입니다.',
      'member_count': _memberCount,
      'president_id': currentUserId,
      'image': _base64Image,
    });

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('동아리가 생성되었습니다!')),
          );
        }
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 존재하는 동아리 이름입니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('동아리 생성 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;
    if (_clubImageBytes != null) {
      avatarImage = MemoryImage(_clubImageBytes!);
    } else if (_clubImageFile != null) {
      avatarImage = FileImage(_clubImageFile!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('동아리 만들기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.black,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 32,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('동아리 이름', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '동아리 이름 입력',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 24, color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 32),
            const Text('동아리 인원수', style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _memberCount.toDouble(),
              min: 2,
              max: 100,
              divisions: 98,
              label: '$_memberCount명',
              onChanged: (value) => setState(() => _memberCount = value.round()),
            ),
            Center(
              child: Text('$_memberCount명', style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                '동아리 이름은 개설 후에도 변경할 수 있어요',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('이전'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_nameController.text.trim().isEmpty || _isLoading)
                        ? null
                        : _createClub,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      disabledBackgroundColor: Colors.pink[100],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('동아리 생성'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}