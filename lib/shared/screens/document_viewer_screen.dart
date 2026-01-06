import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String documentUrl;
  final String title;

  const DocumentViewerScreen({
    super.key,
    required this.documentUrl,
    required this.title,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.documentUrl));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lesson.pdf');
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load document';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : PDFView(
              filePath: _localPath!,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: true,
              pageFling: true,
            ),
    );
  }
}
