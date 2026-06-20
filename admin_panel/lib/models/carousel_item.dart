import 'package:cloud_firestore/cloud_firestore.dart';

enum CarouselLinkType {
  inApp,
  external,
}

enum CarouselItemType {
  home,
  event,
  blog,
  sermon,
  library,
  donation,
  liveStream,
  video,
  other,
}

class CarouselItem {
  CarouselItem({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.linkUrl,
    this.linkType,
    required this.itemType,
    required this.createdAt,
    required this.isActive,
    required this.order,
    this.itemId,
    this.displayTitle = true,
  });

  factory CarouselItem.fromFirestore(Map<String, dynamic> data, String id) {
    CarouselLinkType? parsedLinkType;
    if (data['linkType'] != null) {
      if (data['linkType'] == 'inApp') parsedLinkType = CarouselLinkType.inApp;
      else if (data['linkType'] == 'external') parsedLinkType = CarouselLinkType.external;
    }

    CarouselItemType determinedItemType = CarouselItemType.other;
    if (data['linkUrl'] != null) {
      final String linkUrl = data['linkUrl'].toString();
      if (linkUrl.startsWith('/sermons')) determinedItemType = CarouselItemType.sermon;
      else if (linkUrl.startsWith('/blog')) determinedItemType = CarouselItemType.blog;
      else if (linkUrl.startsWith('/events')) determinedItemType = CarouselItemType.event;
    }

    return CarouselItem(
      id: id,
      title: data['title'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      linkUrl: data['linkUrl'],
      linkType: parsedLinkType,
      itemType: determinedItemType,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      itemId: data['itemId'],
      displayTitle: data['displayTitle'] ?? true,
    );
  }

  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? linkUrl;
  final CarouselLinkType? linkType;
  final CarouselItemType itemType;
  final DateTime createdAt;
  final bool isActive;
  final int order;
  final String? itemId;
  final bool displayTitle;

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'linkType': linkType?.toString().split('.').last.toLowerCase(),
      'itemType': itemType.toString().split('.').last.toLowerCase(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'order': order,
      'itemId': itemId,
      'displayTitle': displayTitle,
    };
  }
}
