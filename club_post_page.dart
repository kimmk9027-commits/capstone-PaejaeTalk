import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClubPostPage extends StatefulWidget {
  final int? clubId;
  const ClubPostPage({super.key, this.clubId});

  @override
  State<ClubPostPage> createState() => _ClubPostPageState();
}

class _ClubPostPageState extends State<ClubPostPage> {
  final TextEditingController _captionController = TextEditingController();
  Uint8List? _imageBytes;
  String? _base64Image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      Uint8List? bytes;

      if (kIsWeb || file.bytes != null) {
        bytes = file.bytes;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes != null) {
        setState(() {
          _imageBytes = bytes;
          _base64Image = base64Encode(bytes!);
        });
      }
    }
  }

  Future<void> _submitPost() async {
    final caption = _captionController.text.trim();
    if (_base64Image == null || _base64Image!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지는 필수입니다.')),
      );
      return;
    }
    if (widget.clubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('동아리 정보가 올바르지 않습니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final name = prefs.getString('name');

    if (email == null || email.isEmpty || name == null || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 이용해 주세요.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.45.62:5000/posts'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': email,
          'name': name,
          'image': _base64Image ?? "",
          'caption': caption,
          'club_id': widget.clubId, // 동아리 게시글로 등록
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("업로드 실패: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("업로드 중 예외 발생: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("게시글 업로드")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1) 캡션 입력
            TextField(
              controller: _captionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "내용을 입력하세요 (선택)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 2) 선택된 이미지 보여주기 (없으면 빈 공간)
            _imageBytes != null
                ? Image.memory(_imageBytes!, height: 200, fit: BoxFit.cover)
                : const SizedBox.shrink(),
            const SizedBox(height: 16),

            // 3) 이미지 선택 버튼
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text("이미지 선택 (선택)"),
            ),
            const SizedBox(height: 16),

            // 4) 업로드 버튼
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _submitPost,
                  child: const Text("업로드"),
                ),
          ],
        ),
      ),
    );
  }
}
