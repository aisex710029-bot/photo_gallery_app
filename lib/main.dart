import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const ImageGalleryScreen(),
    );
  }
}

class ImageGalleryScreen extends StatefulWidget {
  const ImageGalleryScreen({super.key});

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  List<String> _imagePaths = []; // 改為儲存路徑字串
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedImages(); // App 開啟時讀取舊資料
  }

  // 讀取原本存好的照片路徑
  Future<void> _loadSavedImages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _imagePaths = prefs.getStringList('saved_image_paths') ?? [];
      _isLoading = false;
    });
  }

  // 儲存照片路徑到手機本地
  Future<void> _saveImagesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_image_paths', _imagePaths);
  }

  // 選擇新照片
  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            if (!_imagePaths.contains(file.path)) {
              _imagePaths.add(file.path);
            }
          }
        });
        await _saveImagesToStorage(); // 儲存更新後的清單
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('選取圖片失敗或取消: $e')),
      );
    }
  }

  // 刪除照片
  Future<void> _deleteImage(int index) async {
    setState(() {
      _imagePaths.removeAt(index);
    });
    await _saveImagesToStorage(); // 刪除後同步更新本地記憶
  }

  // 開啟全螢幕預覽與縮放
  void _openFullScreenViewer(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(imagePath: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手機相冊展覽館'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _imagePaths.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('點擊右下角按鈕選擇照片\n照片會自動儲存，重開 App 不會消失',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 Column 雙排小視窗
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) {
                    final path = _imagePaths[index];
                    return WindowImageCard(
                      key: ValueKey(path),
                      imagePath: path,
                      onTap: () => _openFullScreenViewer(path),
                      onDelete: () => _deleteImage(index),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickImageFromGallery,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('選擇照片'),
      ),
    );
  }
}

// 雙排小視窗卡片
class WindowImageCard extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const WindowImageCard({
    super.key,
    required this.imagePath,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple.shade100, width: 1.5),
      ),
      child: Stack(
        children: [
          // 點擊小視窗直接開啟全螢幕檢視
          InkWell(
            onTap: onTap,
            child: SizedBox.expand(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover, // 小視窗填滿預覽
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          // 右上角刪除按鈕
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 全螢幕大圖縮放頁面
class FullScreenImagePage extends StatelessWidget {
  final String imagePath;

  const FullScreenImagePage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('圖片檢視 (雙指可縮放)', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0, // 支援最高 5 倍放大檢視
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
