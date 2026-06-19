import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GalleryAlbumScreen extends StatelessWidget {
  final String albumName;
  final List<DocumentSnapshot> photos;
  final Function(BuildContext, String, Map<String, dynamic>) onPhotoTap;
  final String? coverImageUrl;
  final String? description;

  const GalleryAlbumScreen({
    Key? key,
    required this.albumName,
    required this.photos,
    required this.onPhotoTap,
    this.coverImageUrl,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstPhoto =
        photos.isNotEmpty ? photos.first.data() as Map<String, dynamic> : null;
    final displayImageUrl = (coverImageUrl != null && coverImageUrl!.isNotEmpty)
        ? coverImageUrl!
        : firstPhoto?['imageUrl'] ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                albumName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              background: displayImageUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: displayImageUrl,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ],
                    )
                  : Container(
                      color: colors.primary,
                      child: const Icon(Icons.photo_library,
                          size: 80, color: Colors.white54),
                    ),
            ),
          ),
          if (description != null && description!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                '${photos.length} Photos',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final imageData =
                      photos[index].data() as Map<String, dynamic>;
                  final imageId = photos[index].id;

                  return GestureDetector(
                    onTap: () => onPhotoTap(context, imageId, imageData),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: imageId,
                          child: CachedNetworkImage(
                            imageUrl: imageData['imageUrl'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite,
                                    color: Colors.white, size: 10),
                                const SizedBox(width: 2),
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
                  );
                },
                childCount: photos.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
