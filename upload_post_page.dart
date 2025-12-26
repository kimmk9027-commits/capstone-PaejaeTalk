import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UploadPostPage extends StatefulWidget {
  const UploadPostPage({super.key});

  @override
  State<UploadPostPage> createState() => _UploadPostPageState();
}

class _UploadPostPageState extends State<UploadPostPage> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      File imageFile = File(picked.path);

      // 🔹 이미지 크기 조절 (640 x 640)
      final bytes = await imageFile.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);

      int targetWidth = 640; // 원하는 너비
      int targetHeight =
          (decodedImage.height * targetWidth) ~/ decodedImage.width;

      setState(() {
        _selectedImage = imageFile;
      });
    }
  }

  String? _encodeImageToBase64(File imageFile) {
    try {
      final bytes = imageFile.readAsBytesSync();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitPost() async {
    final caption = _contentController.text.trim();
    if (caption.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내용과 이미지를 모두 입력해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    // 🔐 로그인한 사용자 정보 불러오기
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? 'anonymous@example.com';
    final name = prefs.getString('name') ?? 'Unknown User';

    final imageBase64 = _encodeImageToBase64(_selectedImage!);
    if (imageBase64 == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지 인코딩 실패')));
      return;
    }

    // 일반 게시글(동아리 게시글 아님) 업로드는 club_id 없이 전송
    final response = await http.post(
      Uri.parse("http://192.168.45.62:5000/posts"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'email': email,
        'name': name,
        'image': imageBase64,
        'caption': caption,
        // 'club_id': null, // 일반 게시글은 club_id 없이 전송
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("업로드 실패: ${response.body}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("게시글 업로드")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "게시글 내용을 입력하세요",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _selectedImage != null
                  ? Image.file(_selectedImage!, height: 200)
                  : const SizedBox.shrink(),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text("이미지 선택"),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _submitPost,
                    child: const Text("업로드"),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
