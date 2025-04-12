import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class PDFViewerPage extends StatefulWidget {
  final String filePath;

  const PDFViewerPage({super.key, required this.filePath});

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  final Logger _logger = Logger();
  String? localPath;
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  Future<bool> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<void> loadPDF() async {
    if (!await _requestPermissions()) {
      setState(() {
        errorMessage = 'Storage permission is required to view PDF';
      });
      return;
    }
    try {
      final ByteData bytes = await rootBundle.load(widget.filePath);
      final Directory cacheDir = await getApplicationCacheDirectory();
      final String fileName = basename(widget.filePath);
      final File file = File('${cacheDir.path}/$fileName');

      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsBytes(bytes.buffer.asUint8List());
      }

      if (mounted) {
        setState(() {
          localPath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading PDF: ${e.toString()}';
        });
      }
      _logger.e('Error loading PDF: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    loadPDF();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Analysis Report'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (localPath != null && localPath!.isNotEmpty)
            PDFView(
              filePath: localPath!,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: true,
              pageSnap: true,
              onRender: (pages) {
                if (mounted) {
                  setState(() {
                    this.pages = pages;
                    isReady = true;
                  });
                }
              },
              onError: (error) {
                if (mounted) {
                  setState(() {
                    errorMessage = error.toString();
                  });
                }
                _logger.e('PDF Error: $error');
              },
              onPageError: (page, error) {
                if (mounted) {
                  setState(() {
                    errorMessage = '$page: ${error.toString()}';
                  });
                }
                _logger.e('PDF Page Error: $error');
              },
              onViewCreated: (PDFViewController pdfViewController) {
                // Controller available for further use
              },
              onPageChanged: (int? page, int? total) {
                if (mounted) {
                  setState(() {
                    currentPage = page;
                  });
                }
              },
            ),
          if (localPath == null || !isReady)
            const Center(child: CircularProgressIndicator()),
          if (errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (isReady && pages != null && pages! > 0)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Page ${(currentPage ?? 0) + 1} of $pages',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
