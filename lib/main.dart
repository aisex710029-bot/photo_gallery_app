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
                  const Text('點擊右下角按鈕選擇照片\n可在小視窗內雙指縮放移動觀察',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            )
          // 2 Column 雙排網格
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 Column
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8, // 視窗長寬比
              ),
              itemCount: _imageList.length,
              itemBuilder: (context, index) {
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

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias, // 把溢出的圖片剪裁掉 (小視窗效果)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple.shade100, width: 1.5),
      ),
      child: Stack(
        children: [
          // 1. 關鍵修復：用 LayoutBuilder 強制鎖死寬高，絕不讓圖片變 0 像素
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onDoubleTap: _resetZoom, // 雙擊還原大小
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    clipBehavior: Clip.hardEdge, // 鎖在小視窗內
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Image.file(
                        File(widget.imageFile.path),
                        fit: BoxFit.contain, // 圖片預設完整顯示在視窗內
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. 右上角懸浮按鈕 (重置/刪除)
          Positioned(
            top: 6,
            right: 6,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _resetZoom,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
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
                GestureDetector(
                  onTap: widget.onDelete,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
