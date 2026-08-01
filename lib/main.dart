import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final List<XFile> _imageList = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _imageList.addAll(pickedFiles);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('選取圖片失敗或取消: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('圖片局部觀察館 (2 Column)'),
        elevation: 2,
      ),
      body: _imageList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.crop_free, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('點擊右下角按鈕選擇照片\n可用雙指在視窗內放大/縮小檢視局部',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            )
          // 雙排網格固定視窗 (2 Column)
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 Column 雙排
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.85, // 固定小視窗的比例
              ),
              itemCount: _imageList.length,
              itemBuilder: (context, index) { summer:
                return WindowImageCard(
                  key: ValueKey(_imageList[index].path),
                  imageFile: _imageList[index],
                  onDelete: () {
                    setState(() {
                      _imageList.removeAt(index);
                    });
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickImageFromGallery,
        icon: const Icon(Icons.photo_library),
        label: const Text('選擇照片'),
      ),
    );
  }
}

class WindowImageCard extends StatefulWidget {
  final XFile imageFile;
  final VoidCallback onDelete;

  const WindowImageCard({
    super.key,
    required this.imageFile,
    required this.onDelete,
  });

  @override
  State<WindowImageCard> createState() => _WindowImageCardState();
}

class _WindowImageCardState extends State<WindowImageCard> {
  final TransformationController _transformationController =
      TransformationController();

  // 雙擊照片重置縮放狀態
  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias, // 把超過視窗邊界的圖片剪裁掉 (視窗效果)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple.shade100, width: 1.5),
      ),
      child: Stack(
        children: [
          // 1. 小視窗內部的「觀察鏡頭」：可以縮放、移動圖片
          GestureDetector(
            onDoubleTap: _resetZoom, // 雙擊恢復預設比例
            child: Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformationController,
                clipBehavior: Clip.hardEdge, // 關鍵：把圖片限制在視窗內部，不溢出
                minScale: 0.5, // 允許縮小看全貌
                maxScale: 6.0, // 允許放大到 6 倍看細節
                panEnabled: true, // 允許滑動看局部
                scaleEnabled: true, // 允許雙指縮放
                child: Center(
                  child: Image.file(
                    File(widget.imageFile.path),
                    fit: BoxFit.contain, // 預設呈現全貌，縮放時可看局部
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // 2. 懸浮提示與控制按鈕
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              children: [
                // 重置按鈕 (還原預設大小)
                GestureDetector(
                  onTap: _resetZoom,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 刪除按鈕
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
