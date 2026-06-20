import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book.dart';
import '../services/fcm_admin_service.dart';
import '../utils/image_proxy.dart';

class LibraryManager extends StatefulWidget {
  const LibraryManager({super.key});

  @override
  State<LibraryManager> createState() => _LibraryManagerState();
}

class _LibraryManagerState extends State<LibraryManager> {
  String _searchQuery = '';
  int _currentPage = 0;
  final int _rowsPerPage = 20;

  final Set<String> _selectedBookIds = {};
  bool _isPerformingAction = false;

  Set<String> _allCategories = {'All'};
  Set<String> _allAuthors = {'All'};

  String _selectedCategory = 'All';
  String _selectedAuthor = 'All';

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) setState(() => _currentPage++);
  }

  void _prevPage() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  void _showBookDetails(Book book, Map<String, dynamic> rawData) {
    showDialog(
      context: context,
      builder: (context) {
        bool isActive = book.isActive;
        bool isTrending = book.isTrending;
        bool isMostRead = book.isMostRead;
        bool isRecommended = book.isRecommended;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Book Details'),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book.coverUrl.isEmpty
                          ? Container(width: 150, height: 200, color: Colors.grey.shade200, child: const Icon(Icons.book, size: 50, color: Colors.grey))
                          : Image.network(
                              ImageProxy.proxy(book.coverUrl),
                              width: 150,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 150,
                                height: 200,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow('Title:', book.title),
                  _DetailRow('Author:', book.author),
                  _DetailRow('Category:', book.category),
                  _DetailRow('Topics:', book.topics.join(', ')),
                  _DetailRow('Pages:', book.totalPages.toString()),
                  _DetailRow('Published:', '${book.publishedDate.toLocal()}'.split(' ')[0]),
                  _DetailRow('Status:', book.isActive ? 'Active' : 'Inactive'),
                  const SizedBox(height: 8),
                  const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(book.description, style: const TextStyle(height: 1.5)),
                  ),
                  const Divider(height: 32),
                  const Text('Flags (Toggle to update immediately)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (val) async {
                      setDialogState(() => isActive = val);
                      await FirebaseFirestore.instance.collection('books').doc(book.id).update({'isActive': val});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Trending'),
                    value: isTrending,
                    onChanged: (val) async {
                      setDialogState(() => isTrending = val);
                      await FirebaseFirestore.instance.collection('books').doc(book.id).update({'isTrending': val});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Most Read'),
                    value: isMostRead,
                    onChanged: (val) async {
                      setDialogState(() => isMostRead = val);
                      await FirebaseFirestore.instance.collection('books').doc(book.id).update({'isMostRead': val});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Recommended'),
                    value: isRecommended,
                    onChanged: (val) async {
                      setDialogState(() => isRecommended = val);
                      await FirebaseFirestore.instance.collection('books').doc(book.id).update({'isRecommended': val});
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete Book'),
                    content: const Text('Are you sure you want to delete this book?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirebaseFirestore.instance.collection('books').doc(book.id).delete();
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() => _selectedBookIds.remove(book.id));
                  }
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
              onPressed: () {
                Navigator.pop(context);
                _showUploadDialog(book: book);
              },
            ),
          ],
        );
      });
      },
    );
  }

  void _showUploadDialog({Book? book}) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: book?.title ?? '');
    final authorCtrl = TextEditingController(text: book?.author ?? '');
    final categoryCtrl = TextEditingController(text: book?.category ?? '');
    final topicsCtrl = TextEditingController(text: book?.topics.join(', ') ?? '');
    final descCtrl = TextEditingController(text: book?.description ?? '');
    final pagesCtrl = TextEditingController(text: book?.totalPages.toString() ?? '0');
    
    DateTime selectedDate = book?.publishedDate ?? DateTime.now();
    bool isActive = book?.isActive ?? true;
    bool isTrending = book?.isTrending ?? false;
    bool isMostRead = book?.isMostRead ?? false;
    bool isRecommended = book?.isRecommended ?? false;

    String coverMode = 'url';
    String pdfMode = 'url';
    final coverUrlCtrl = TextEditingController(text: book?.coverUrl ?? '');
    final pdfUrlCtrl = TextEditingController(text: book?.pdfUrl ?? '');

    Uint8List? coverBytes;
    String? coverFileName;
    Uint8List? pdfBytes;
    String? pdfFileName;

    bool isSaving = false;
    double uploadProgress = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(book == null ? 'Upload New Book' : 'Edit Book', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 600,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                          validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: authorCtrl,
                                decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
                                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: categoryCtrl,
                                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: topicsCtrl,
                          decoration: const InputDecoration(labelText: 'Topics (comma separated)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: pagesCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Total Pages', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ListTile(
                                title: const Text('Published Date', style: TextStyle(fontSize: 12)),
                                subtitle: Text('${selectedDate.toLocal()}'.split(' ')[0]),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime(2050),
                                  );
                                  if (date != null) setDialogState(() => selectedDate = date);
                                },
                                tileColor: Colors.grey[50],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade400)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true),
                        ),
                        
                        const Divider(height: 32),
                        const Text('Flags', style: TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 16,
                          children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Checkbox(value: isActive, onChanged: (v) => setDialogState(() => isActive = v!)),
                              const Text('Active'),
                            ]),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Checkbox(value: isTrending, onChanged: (v) => setDialogState(() => isTrending = v!)),
                              const Text('Trending'),
                            ]),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Checkbox(value: isMostRead, onChanged: (v) => setDialogState(() => isMostRead = v!)),
                              const Text('Most Read'),
                            ]),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Checkbox(value: isRecommended, onChanged: (v) => setDialogState(() => isRecommended = v!)),
                              const Text('Recommended'),
                            ]),
                          ],
                        ),

                        const Divider(height: 32),
                        const Text('Cover Image', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Radio(value: 'url', groupValue: coverMode, onChanged: (v) => setDialogState(() => coverMode = v.toString())),
                            const Text('URL'),
                            Radio(value: 'file', groupValue: coverMode, onChanged: (v) => setDialogState(() => coverMode = v.toString())),
                            const Text('Upload File'),
                          ],
                        ),
                        if (coverMode == 'url')
                          TextFormField(
                            controller: coverUrlCtrl,
                            decoration: const InputDecoration(labelText: 'Cover Image URL', border: OutlineInputBorder()),
                          )
                        else
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  FilePickerResult? res = await FilePicker.pickFiles(type: FileType.image, withData: true);
                                  if (res != null) setDialogState(() { coverBytes = res.files.first.bytes; coverFileName = res.files.first.name; });
                                },
                                icon: const Icon(Icons.image), label: const Text('Select Image'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(coverFileName ?? 'No image selected', overflow: TextOverflow.ellipsis)),
                            ],
                          ),

                        const SizedBox(height: 16),
                        const Text('PDF Document', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Radio(value: 'url', groupValue: pdfMode, onChanged: (v) => setDialogState(() => pdfMode = v.toString())),
                            const Text('URL'),
                            Radio(value: 'file', groupValue: pdfMode, onChanged: (v) => setDialogState(() => pdfMode = v.toString())),
                            const Text('Upload File'),
                          ],
                        ),
                        if (pdfMode == 'url')
                          TextFormField(
                            controller: pdfUrlCtrl,
                            decoration: const InputDecoration(labelText: 'PDF URL', border: OutlineInputBorder()),
                          )
                        else
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  FilePickerResult? res = await FilePicker.pickFiles(
                                    type: FileType.custom, 
                                    allowedExtensions: ['pdf'],
                                    withData: true
                                  );
                                  if (res != null) setDialogState(() { pdfBytes = res.files.first.bytes; pdfFileName = res.files.first.name; });
                                },
                                icon: const Icon(Icons.picture_as_pdf), label: const Text('Select PDF'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(pdfFileName ?? 'No PDF selected', overflow: TextOverflow.ellipsis)),
                            ],
                          ),

                        if (isSaving) ...[
                          const SizedBox(height: 16),
                          LinearProgressIndicator(value: uploadProgress),
                          const SizedBox(height: 4),
                          Text('Saving... ${(uploadProgress * 100).toStringAsFixed(1)}%'),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (!isSaving) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                if (!isSaving) ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    String finalCoverUrl = coverUrlCtrl.text.trim();
                    String finalPdfUrl = pdfUrlCtrl.text.trim();

                    if (coverMode == 'file' && coverBytes == null) {
                      if (book == null) finalCoverUrl = '';
                    } else if (coverMode == 'url' && finalCoverUrl.isEmpty) {
                      finalCoverUrl = book?.coverUrl ?? '';
                    }

                    if (pdfMode == 'file' && pdfBytes == null) {
                      if (book == null && finalPdfUrl.isEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF file or provide a URL')));
                         return;
                      }
                    }

                    setDialogState(() => isSaving = true);
                    
                    try {
                      if (coverMode == 'file' && coverBytes != null) {
                        final coverRef = FirebaseStorage.instance.ref('library/covers/${DateTime.now().millisecondsSinceEpoch}_$coverFileName');
                        await coverRef.putData(coverBytes!);
                        finalCoverUrl = await coverRef.getDownloadURL();
                      }

                      if (pdfMode == 'file' && pdfBytes != null) {
                        final pdfRef = FirebaseStorage.instance.ref('library/pdfs/${DateTime.now().millisecondsSinceEpoch}_$pdfFileName');
                        final uploadTask = pdfRef.putData(pdfBytes!);
                        uploadTask.snapshotEvents.listen((event) {
                          setDialogState(() => uploadProgress = event.bytesTransferred / event.totalBytes);
                        });
                        await uploadTask;
                        finalPdfUrl = await pdfRef.getDownloadURL();
                      }

                      final tagsList = topicsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                      
                      final data = {
                        'title': titleCtrl.text.trim(),
                        'author': authorCtrl.text.trim(),
                        'category': categoryCtrl.text.trim(),
                        'topics': tagsList,
                        'description': descCtrl.text.trim(),
                        'totalPages': int.tryParse(pagesCtrl.text.trim()) ?? 0,
                        'publishedDate': Timestamp.fromDate(selectedDate),
                        'coverUrl': finalCoverUrl,
                        'pdfUrl': finalPdfUrl,
                        'isActive': isActive,
                        'isTrending': isTrending,
                        'isMostRead': isMostRead,
                        'isRecommended': isRecommended,
                      };

                      if (book == null) {
                        data['trendingOrder'] = 0;
                        data['mostReadOrder'] = 0;
                        data['recommendedOrder'] = 0;
                        await FirebaseFirestore.instance.collection('books').add(data);
                        
                        await FcmAdminService.sendNotification(
                          title: 'New Book Added: ${titleCtrl.text}',
                          content: 'Check out the new book by ${authorCtrl.text} in our Library!',
                        );
                      } else {
                        await FirebaseFirestore.instance.collection('books').doc(book.id).update(data);
                      }
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(book == null ? 'Book published!' : 'Book updated!')));
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Operation failed: $e')));
                    } finally {
                      if (mounted) setDialogState(() => isSaving = false);
                    }
                  },
                  child: Text(book == null ? 'Publish' : 'Update'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _applyBatchAction(String action) async {
    if (_selectedBookIds.isEmpty) return;
    
    setState(() => _isPerformingAction = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      if (action == 'Delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Confirm Bulk Delete'),
            content: Text('Delete ${_selectedBookIds.length} books?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Delete')),
            ],
          ),
        );

        if (confirm != true) {
          setState(() => _isPerformingAction = false);
          return;
        }

        for (final id in _selectedBookIds) {
          batch.delete(FirebaseFirestore.instance.collection('books').doc(id));
        }
      } else if (action == 'Deactivate') {
        for (final id in _selectedBookIds) {
          batch.update(FirebaseFirestore.instance.collection('books').doc(id), {'isActive': false});
        }
      } else if (action == 'Activate') {
        for (final id in _selectedBookIds) {
          batch.update(FirebaseFirestore.instance.collection('books').doc(id), {'isActive': true});
        }
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action applied.')));
        setState(() => _selectedBookIds.clear());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPerformingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Row(
            children: [
              const Text('Library Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showUploadDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Upload New Book'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search books by title, author...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => setState(() { _searchQuery = val.toLowerCase(); _currentPage = 0; }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _allCategories.contains(_selectedCategory) ? _selectedCategory : 'All',
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                            items: _allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() { _selectedCategory = v!; _currentPage = 0; }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _allAuthors.contains(_selectedAuthor) ? _selectedAuthor : 'All',
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                            items: _allAuthors.map((a) => DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() { _selectedAuthor = v!; _currentPage = 0; }),
                          ),
                        ),
                        if (_selectedBookIds.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Text('${_selectedBookIds.length} selected', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          PopupMenuButton<String>(
                            onSelected: _applyBatchAction,
                            child: ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.settings),
                              label: const Text('Bulk Actions'),
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'Activate', child: Text('Mark Active')),
                              const PopupMenuItem(value: 'Deactivate', child: Text('Mark Inactive')),
                              const PopupMenuItem(value: 'Delete', child: Text('Delete Selected', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('books').orderBy('publishedDate', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        var docs = snapshot.data!.docs;

                        // Populate filters
                        _allCategories = {'All'};
                        _allAuthors = {'All'};
                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          _allCategories.add(data['category']?.toString() ?? 'Unknown');
                          _allAuthors.add(data['author']?.toString() ?? 'Unknown');
                        }

                        // Filter docs
                        var filteredDocs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final title = (data['title'] ?? '').toString().toLowerCase();
                          final author = (data['author'] ?? '').toString().toLowerCase();
                          final cat = (data['category'] ?? '').toString();
                          
                          if (_searchQuery.isNotEmpty && !title.contains(_searchQuery) && !author.contains(_searchQuery)) {
                            return false;
                          }
                          if (_selectedCategory != 'All' && cat != _selectedCategory) return false;
                          if (_selectedAuthor != 'All' && author != _selectedAuthor) return false;
                          
                          return true;
                        }).toList();

                        final totalItems = filteredDocs.length;
                        final totalPages = (totalItems / _rowsPerPage).ceil();
                        
                        if (_currentPage >= totalPages && totalPages > 0) {
                          _currentPage = totalPages - 1;
                        }

                        final startIndex = _currentPage * _rowsPerPage;
                        final endIndex = (startIndex + _rowsPerPage > totalItems) ? totalItems : startIndex + _rowsPerPage;
                        final pagedDocs = filteredDocs.sublist(startIndex, endIndex);

                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                                    columns: [
                                      DataColumn(
                                        label: Checkbox(
                                          value: _selectedBookIds.length == pagedDocs.length && pagedDocs.isNotEmpty,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedBookIds.addAll(pagedDocs.map((d) => d.id));
                                              } else {
                                                _selectedBookIds.clear();
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const DataColumn(label: Text('Cover')),
                                      const DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Author', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('Status')),
                                      const DataColumn(label: Text('Published')),
                                    ],
                                    rows: pagedDocs.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      final book = Book.fromFirestore(doc);
                                      final isSelected = _selectedBookIds.contains(book.id);

                                      return DataRow(
                                        selected: isSelected,
                                        onSelectChanged: (_) => _showBookDetails(book, data),
                                        cells: [
                                          DataCell(
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedBookIds.add(book.id);
                                                  } else {
                                                    _selectedBookIds.remove(book.id);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: book.coverUrl.isEmpty
                                                    ? Container(width: 40, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.book, size: 20))
                                                    : Image.network(ImageProxy.proxy(book.coverUrl), width: 40, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 40, height: 60, color: Colors.grey.shade200)),
                                              ),
                                            ),
                                            onTap: () => _showBookDetails(book, data),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 250,
                                              child: Text(book.title, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 2),
                                            ),
                                            onTap: () => _showBookDetails(book, data),
                                          ),
                                          DataCell(
                                            Text(book.author),
                                            onTap: () => _showBookDetails(book, data),
                                          ),
                                          DataCell(
                                            Text(book.category),
                                            onTap: () => _showBookDetails(book, data),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: book.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(book.isActive ? 'Active' : 'Inactive', style: TextStyle(color: book.isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12)),
                                            ),
                                            onTap: () => _showBookDetails(book, data),
                                          ),
                                          DataCell(
                                            Text('${book.publishedDate.toLocal()}'.split(' ')[0]),
                                            onTap: () => _showBookDetails(book, data),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            
                            if (totalItems > 0)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Showing ${startIndex + 1} to $endIndex of $totalItems entries', style: TextStyle(color: Colors.grey.shade600)),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: _currentPage > 0 ? _prevPage : null,
                                        ),
                                        Text('Page ${_currentPage + 1} of ${totalPages > 0 ? totalPages : 1}'),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: _currentPage < totalPages - 1 ? () => _nextPage(totalPages) : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
