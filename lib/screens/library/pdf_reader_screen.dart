import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/book.dart';
import '../../services/book_service.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({
    Key? key,
    required this.book,
  }) : super(key: key);
  final Book book;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final BookService _bookService = BookService();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  
  bool _isLoading = true;
  String? _localPath;
  int _savedPage = 1;

  @override
  void initState() {
    super.initState();
    _initReader();
  }

  @override
  void dispose() {
    _saveProgressSilently();
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<void> _initReader() async {
    final localPath = await _bookService.getLocalPdfPath(widget.book.id);
    final progressInfo = await _bookService.getReadingProgress(widget.book.id);
    
    if (mounted) {
      setState(() {
        _localPath = localPath;
        _savedPage = progressInfo['currentPage'] ?? 1;
        _isLoading = false;
      });
    }
  }

  void _saveProgressSilently() {
    if (_pdfViewerController.pageNumber > 0) {
      _bookService.updateReadingProgress(widget.book.id, _pdfViewerController.pageNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title, overflow: TextOverflow.ellipsis),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _localPath != null
              ? SfPdfViewer.file(
                  File(_localPath!),
                  controller: _pdfViewerController,
                  canShowScrollHead: false,
                  canShowScrollStatus: false,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    if (_savedPage > 1) {
                      _pdfViewerController.jumpToPage(_savedPage);
                    }
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    _saveProgressSilently();
                  },
                )
              : SfPdfViewer.network(
                  widget.book.pdfUrl,
                  controller: _pdfViewerController,
                  canShowScrollHead: false,
                  canShowScrollStatus: false,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    if (_savedPage > 1) {
                      _pdfViewerController.jumpToPage(_savedPage);
                    }
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    _saveProgressSilently();
                  },
                ),
    );
  }
}
