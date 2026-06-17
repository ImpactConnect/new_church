class ImageProxy {
  static String proxy(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    if (originalUrl.contains('firebasestorage.googleapis.com')) return originalUrl;
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(originalUrl)}';
  }
}
