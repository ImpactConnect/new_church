import 'dart:io' show Platform, File, Directory;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../models/gallery_category.dart';
import '../../services/gallery_service.dart';
import 'gallery_album_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<GalleryCategory> _fetchedCategories = [];
  bool _isLoadingCategories = true;
  Set<String> _likedImages = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadLikedImages();
  }

  Future<void> _loadLikedImages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _likedImages =
          (prefs.getStringList('liked_gallery_images') ?? []).toSet();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore.collection('gallery_categories').get();
      if (mounted) {
        setState(() {
          _fetchedCategories = snapshot.docs
              .map((doc) => GalleryCategory.fromFirestore(doc))
              .toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

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
  void _showFullImagePopup(
      BuildContext context, String imageId, Map<String, dynamic> imageData) {
    bool isLiked = _likedImages.contains(imageId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  // Full Image
                  InteractiveViewer(
                    child: Hero(
                      tag: imageId,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.redAccent : Colors.white,
                            ),
                            onPressed: () async {
                              if (isLiked) return;
                              final success =
                                  await GalleryService().likeImage(imageId);
                              if (success) {
                                setStateDialog(() {
                                  isLiked = true;
                                  imageData['likes'] =
                                      (imageData['likes'] ?? 0) + 1;
                                });
                                _likedImages.add(imageId);
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setStringList(
                                    'liked_gallery_images',
                                    _likedImages.toList());
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Image liked!')),
                                  );
                                }
                              }
                            },
                          ),
                          Text('${imageData['likes'] ?? 0}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  // Download Icon (Bottom Left)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.download, color: Colors.white),
                            onPressed: () => _downloadImage(
                                imageData['imageUrl'],
                                '${imageData['title'] ?? 'church_image'}|ID:$imageId'),
                          ),
                          Text('${imageData['downloads'] ?? 0}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
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
                        onPressed: () => _shareImage(imageData['imageUrl'],
                            imageData['title'] ?? 'Church Image'),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 150.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Church Gallery',
                      style: TextStyle(color: Colors.white)),
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
                              Colors.black.withValues(alpha: 0.7),
                              Colors.black.withValues(alpha: 0.3),
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

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15),
                      ),
                      labelColor: Theme.of(context).colorScheme.primary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      unselectedLabelColor: Colors.grey.shade600,
                      unselectedLabelStyle:
                          const TextStyle(fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'All Photos'),
                        Tab(text: 'Albums'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('gallery').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No images in gallery'));
              }

              // Filter images based on search query
              final filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final imageUrl = data['imageUrl'] as String? ?? '';
                if (imageUrl.isEmpty) return false;

                final title = (data['title'] as String? ?? '').toLowerCase();
                final category =
                    (data['category'] as String? ?? '').toLowerCase();
                final tags = (data['tags'] as List? ?? [])
                    .map((tag) => tag.toString().toLowerCase())
                    .toList();

                return _searchQuery.isEmpty ||
                    title.contains(_searchQuery) ||
                    category.contains(_searchQuery) ||
                    tags.any((tag) => tag.contains(_searchQuery));
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Text(
                    'No images match your search',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }

              return TabBarView(
                children: [
                  _buildPhotoGrid(filteredDocs),
                  _buildAlbumGrid(filteredDocs),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(List<DocumentSnapshot> filteredDocs) {
    final featuredDocs = filteredDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isFeatured'] == true;
    }).toList();

    return CustomScrollView(
      slivers: [
        if (featuredDocs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text('Featured',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: CarouselSlider.builder(
              itemCount: featuredDocs.length,
              options: CarouselOptions(
                height: 180,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                enlargeCenterPage: true,
                viewportFraction: 0.85,
              ),
              itemBuilder: (context, index, realIndex) {
                final imageData =
                    featuredDocs[index].data() as Map<String, dynamic>;
                final imageId = featuredDocs[index].id;
                return GestureDetector(
                  onTap: () => _showFullImagePopup(context, imageId, imageData),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageData['imageUrl'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${imageData['likes'] ?? 0}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final imageData =
                  filteredDocs[index].data() as Map<String, dynamic>;
              final imageId = filteredDocs[index].id;

              return GestureDetector(
                onTap: () => _showFullImagePopup(context, imageId, imageData),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      Hero(
                        tag: imageId,
                        child: CachedNetworkImage(
                          imageUrl: imageData['imageUrl'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox(
                              height: 150,
                              child:
                                  Center(child: CircularProgressIndicator())),
                          errorWidget: (context, url, error) => const SizedBox(
                              height: 150, child: Icon(Icons.error)),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${imageData['likes'] ?? 0}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumGrid(List<DocumentSnapshot> filteredDocs) {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    // Combine explicit categories with virtual ones from images
    final existingCategoryNames =
        _fetchedCategories.map((c) => c.name.toLowerCase()).toSet();
    final combinedCategories = List<GalleryCategory>.from(_fetchedCategories);

    for (var doc in filteredDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final cat = (data['category'] as String? ?? '').trim();
      if (cat.isNotEmpty &&
          !existingCategoryNames.contains(cat.toLowerCase())) {
        existingCategoryNames.add(cat.toLowerCase());
        combinedCategories.add(GalleryCategory(
            id: 'virtual_$cat', name: cat, imageUrl: '', description: ''));
      }
    }

    if (combinedCategories.isEmpty) {
      return const Center(child: Text('No albums available'));
    }

    // Sort categories alphabetically by name
    final sortedCategories = combinedCategories
      ..sort((a, b) => a.name.compareTo(b.name));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final photosInAlbum = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final cat = (data['category'] as String? ?? '').trim().toLowerCase();
          return cat == category.name.toLowerCase();
        }).toList();

        final coverImageUrl = category.imageUrl;
        final colors = Theme.of(context).colorScheme;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GalleryAlbumScreen(
                  albumName: category.name,
                  photos: photosInAlbum,
                  onPhotoTap: _showFullImagePopup,
                  coverImageUrl: coverImageUrl,
                  description: category.description,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        coverImageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: coverImageUrl, fit: BoxFit.cover)
                            : Container(
                                color: colors.primary.withValues(alpha: 0.1)),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7)
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Row(
                            children: [
                              const Icon(Icons.photo_library,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text('${photosInAlbum.length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      if (category.description.isNotEmpty)
                        Text(category.description,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)
                      else
                        Text('Album',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
