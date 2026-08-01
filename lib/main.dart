import 'package:flutter/material.dart';

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
  final List<String> _imageList = [];

  void _addMockImage() {
    setState(() {
      int id = _imageList.length + 1;
      _imageList.add('https://picsum.photos/id/${id * 15}/800/1000');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('動態相片展覽館 (支援縮放)'),
        elevation: 2,
      ),
      body: _imageList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('點擊右下角按鈕，動態新增卡片小視窗',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              itemCount: _imageList.length,
              itemBuilder: (context, index) {
                return DynamicImageCard(
                  imageUrl: _imageList[index],
                  index: index + 1,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMockImage,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('加載相冊圖片'),
      ),
    );
  }
}

class DynamicImageCard extends StatelessWidget {
  final String imageUrl;
  final int index;

  const DynamicImageCard({
    super.key,
    required this.imageUrl,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(right: 16, top: 20, bottom: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('小視窗 #$index',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Icon(Icons.zoom_in, size: 18, color: Colors.grey),
              ],
            ),
            const Divider(),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(20.0),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
