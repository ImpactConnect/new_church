import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/book.dart';
import '../../services/book_service.dart';
import 'pdf_reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({
    Key? key,
    required this.book,
  }) : super(key: key);
  
  final Book book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BookService _bookService = BookService();
  bool _isBookmarked = false;
  bool _isDownloaded = false;
  
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _readingProgress = 1;

  @override
  void initState() {
    super.initState();
    _loadBookStatus();
  }

  Future<void> _loadBookStatus() async {
    final bookmarkedBooks = await _bookService.getBookmarkedBooks();
    final localPath = await _bookService.getLocalPdfPath(widget.book.id);
    final progressInfo = await _bookService.getReadingProgress(widget.book.id);

    if (mounted) {
      setState(() {
        _isBookmarked = bookmarkedBooks.any((b) => b.id == widget.book.id);
        _isDownloaded = localPath != null;
        _readingProgress = progressInfo['currentPage'] ?? 1;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    await _bookService.toggleBookmark(widget.book.id);
    setState(() => _isBookmarked = !_isBookmarked);
  }

  Future<void> _downloadBook() async {
    if (widget.book.pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This book is not available for download.')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await _bookService.downloadPdf(
        widget.book.id,
        widget.book.pdfUrl,
        (progress) {
          if (mounted) {
            setState(() => _downloadProgress = progress);
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloaded = true;
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book downloaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download book.')),
        );
      }
    }
  }

  void _shareBook() {
    Share.share(
      'Check out this book: ${widget.book.title} by ${widget.book.author}\nRead it on the Impact Connect App!',
      subject: widget.book.title,
    );
  }

  void _openReader() async {
    // Navigate and await return to update reading progress
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfReaderScreen(book: widget.book),
      ),
    );
    _loadBookStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred Background
                  CachedNetworkImage(
                    imageUrl: widget.book.coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade200),
                    errorWidget: (context, url, error) => Container(color: Colors.grey.shade200),
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.6), // Dim the blurred bg
                  ),
                  // Foreground actual cover
                  Align(
                    alignment: Alignment.center,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40, bottom: 20),
                        child: Hero(
                          tag: 'book-${widget.book.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: widget.book.coverUrl,
                                fit: BoxFit.cover,
                                width: 150,
                                height: 220,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0.0, -20.0, 0.0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.book.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'By ${widget.book.author}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          label: 'Save',
                          color: _isBookmarked ? Theme.of(context).primaryColor : Colors.grey.shade700,
                          onPressed: _toggleBookmark,
                        ),
                        _buildActionButton(
                          icon: _isDownloaded ? Icons.download_done : (_isDownloading ? Icons.downloading : Icons.download),
                          label: _isDownloaded ? 'Saved' : 'Download',
                          color: _isDownloaded ? Theme.of(context).primaryColor : Colors.grey.shade700,
                          onPressed: _isDownloaded || _isDownloading ? null : _downloadBook,
                        ),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          color: Colors.grey.shade700,
                          onPressed: _shareBook,
                        ),
                      ],
                    ),
                    
                    if (_isDownloading) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _downloadProgress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(child: Text('${(_downloadProgress * 100).toStringAsFixed(0)}% Downloaded', style: const TextStyle(color: Colors.grey, fontSize: 12))),
                    ],

                    const SizedBox(height: 32),
                    
                    // Tags
                    if (widget.book.topics.isNotEmpty) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: widget.book.topics.map((topic) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(topic, style: const TextStyle(fontSize: 12)),
                                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Synopsis',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.book.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 100), // Space for floating button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _openReader,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book),
                const SizedBox(width: 12),
                Text(
                  _readingProgress > 1 ? 'Continue Reading (Page $_readingProgress)' : 'Read Now',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
