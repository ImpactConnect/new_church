import 'dart:io' show Platform, File, Directory;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../services/gallery_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Download image to device
  Future<void> _downloadImage(String imageUrl, String fileName) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final result = await ImageGallerySaverPlus.saveImage(
        response.bodyBytes,
        quality: 100,
        name: fileName,
      );
      
      if (result['isSuccess'] == true) {
        // Record download in Firebase
        if (fileName.contains('|ID:')) {
          final id = fileName.split('|ID:').last;
          await GalleryService().incrementDownloadCount(id);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery')),
        );
      } else {
        throw Exception('Failed to save image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  // Share image
  Future<void> _shareImage(String imageUrl, String title) async {
    try {
      // Download image temporarily
      final response = await http.get(Uri.parse(imageUrl));
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/shared_image.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Share
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: title,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  // Show full image in a popup
  void _showFullImagePopup(BuildContext context, String imageId, Map<String, dynamic> imageData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              // Full Image
              InteractiveViewer(
                child: Hero(
                  tag: imageData['imageUrl'],
                  child: CachedNetworkImage(
                    imageUrl: imageData['imageUrl'],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),

              // Like Icon (Bottom Left - Center)
              Positioned(
                bottom: 20,
                left: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                        onPressed: () async {
                          final success = await GalleryService().likeImage(imageId);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Image liked!')),
                            );
                          }
                        },
                      ),
                      Text('${imageData['likes'] ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // Download Icon (Bottom Left)
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.white),
                        onPressed: () => _downloadImage(
                          imageData['imageUrl'], 
                          '${imageData['title'] ?? 'church_image'}|ID:$imageId'
                        ),
                      ),
                      Text('${imageData['downloads'] ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // Share Icon (Bottom Right)
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => _shareImage(
                      imageData['imageUrl'], 
                      imageData['title'] ?? 'Church Image'
                    ),
                  ),
                ),
              ),

              // Close Button
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Church Gallery', style: TextStyle(color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/gallery_header.jpg',
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay for better text visibility
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by title, category, or tags',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('gallery').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('No images in gallery')),
                  );
                }

                // Filter images based on search query
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] as String? ?? '').toLowerCase();
                  final category = (data['category'] as String? ?? '').toLowerCase();
                  final tags = (data['tags'] as List? ?? [])
                      .map((tag) => tag.toString().toLowerCase())
                      .toList();

                  return _searchQuery.isEmpty || 
                         title.contains(_searchQuery) || 
                         category.contains(_searchQuery) ||
                         tags.any((tag) => tag.contains(_searchQuery));
                }).toList();

                if (filteredDocs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'No images match your search',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  );
                }

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final imageData = filteredDocs[index].data() as Map<String, dynamic>;

                      final imageId = filteredDocs[index].id;

                      return GestureDetector(
                        onTap: () => _showFullImagePopup(context, imageId, imageData),
                        child: Hero(
                          tag: imageData['imageUrl'],
                          child: CachedNetworkImage(
                            imageUrl: imageData['imageUrl'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                      );
                    },
                    childCount: filteredDocs.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
