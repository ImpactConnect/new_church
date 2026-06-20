import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/book_service.dart';
import '../../widgets/library/book_card.dart';
import '../../widgets/library/book_grid.dart';
import '../../widgets/library/filter_section.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final BookService _bookService = BookService();
  late TabController _tabController;
  
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedAuthor;
  List<String>? _selectedTopics;

  // State
  bool _isLoading = true;
  List<Book> _trendingBooks = [];
  List<Book> _downloadedBooks = [];
  List<Book> _recommendedBooks = [];

  bool get _hasActiveFilters =>
      _selectedCategory != null ||
      _selectedAuthor != null ||
      (_selectedTopics?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _bookService.getTrendingBooks(),
        _bookService.getMostDownloadedBooks(),
        _bookService.getRecommendedBooks(),
      ]);
      if (mounted) {
        setState(() {
          _trendingBooks = results[0];
          _downloadedBooks = results[1];
          _recommendedBooks = results[2];
        });
      }
    } catch (e) {
      print('Error loading library dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Books',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilterSection(
                selectedCategory: _selectedCategory,
                selectedAuthor: _selectedAuthor,
                selectedTopics: _selectedTopics,
                onCategorySelected: (category) {
                  setState(() => _selectedCategory = category);
                },
                onAuthorSelected: (author) {
                  setState(() => _selectedAuthor = author);
                },
                onTopicsSelected: (topics) {
                  setState(() => _selectedTopics = topics);
                },
                onClearFilters: () {
                  setState(() {
                    _selectedCategory = null;
                    _selectedAuthor = null;
                    _selectedTopics = null;
                  });
                },
                hasActiveFilters: _hasActiveFilters,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookSection(String title, List<Book> books) {
    if (books.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 150,
                  child: BookCard(book: books[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280.0,
              pinned: true,
              stretch: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Library', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/library_bg.jpg',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
              
            // Search and Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search books, authors...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _showFilterBottomSheet,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _hasActiveFilters ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.tune, 
                            color: _hasActiveFilters ? Colors.white : Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Active Filters Display
              if (_hasActiveFilters)
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (_selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text(_selectedCategory!),
                              onDeleted: () => setState(() => _selectedCategory = null),
                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              deleteIconColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        if (_selectedAuthor != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text(_selectedAuthor!),
                              onDeleted: () => setState(() => _selectedAuthor = null),
                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              deleteIconColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        if (_selectedTopics != null)
                          ..._selectedTopics!.map((t) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(t),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedTopics!.remove(t);
                                      if (_selectedTopics!.isEmpty) _selectedTopics = null;
                                    });
                                  },
                                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  deleteIconColor: Theme.of(context).primaryColor,
                                ),
                              )),
                      ],
                    ),
                  ),
                ),

              // Carousels
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildBookSection('Trending Books', _trendingBooks),
                      _buildBookSection('Most Downloaded', _downloadedBooks),
                      _buildBookSection('Recommended', _recommendedBooks),
                    ],
                  ),
                ),

              // TabBar Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  Material(
                    elevation: 1,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).primaryColor,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'All Books'),
                        Tab(text: 'Bookmarked'),
                        Tab(text: 'Downloaded'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _AllBooksTab(
                searchQuery: _searchQuery,
                category: _selectedCategory,
                author: _selectedAuthor,
                topics: _selectedTopics,
                bookService: _bookService,
              ),
              _BookmarkedBooksTab(bookService: _bookService),
              _DownloadedBooksTab(bookService: _bookService),
            ],
          ),
        ),
    );
  }
}

class _AllBooksTab extends StatelessWidget {
  final String searchQuery;
  final String? category;
  final String? author;
  final List<String>? topics;
  final BookService bookService;

  const _AllBooksTab({
    required this.searchQuery,
    this.category,
    this.author,
    this.topics,
    required this.bookService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Book>>(
      // We still use FutureBuilder here for the filtered results so it updates dynamically
      future: bookService.getBooks(
        searchQuery: searchQuery,
        category: category,
        author: author,
        topics: topics,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context, 'No books found', Icons.search_off);
        }
        return BookGrid(books: snapshot.data!);
      },
    );
  }
}

class _BookmarkedBooksTab extends StatelessWidget {
  final BookService bookService;
  const _BookmarkedBooksTab({required this.bookService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Book>>(
      future: bookService.getBookmarkedBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context, 'No bookmarked books yet', Icons.bookmark_border);
        }
        return BookGrid(books: snapshot.data!);
      },
    );
  }
}

class _DownloadedBooksTab extends StatelessWidget {
  final BookService bookService;
  const _DownloadedBooksTab({required this.bookService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Book>>(
      future: bookService.getDownloadedBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context, 'No downloaded books yet', Icons.download_done);
        }
        return BookGrid(books: snapshot.data!);
      },
    );
  }
}

Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this.child);
  final Widget child;

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
