import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PDFViewerScreen extends StatefulWidget {
  final String title;
  final String? localPath;

  const PDFViewerScreen({
    super.key,
    required this.title,
    required this.localPath,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String? error;
  PDFViewController? controller;
  int currentPage = 0;
  int totalPages = 0;

  @override
  void initState() {
    super.initState();
    if (widget.localPath != null) {
      localPath = widget.localPath;
      isLoading = false;
    } else {
      error = 'PDF not found';
      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
              : error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 20),
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Transform.scale(
                      scale: 1.25,
                      child: PDFView(
                        filePath: localPath!,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: false,
                        pageFling: false,
                        fitEachPage: true,
                        fitPolicy: FitPolicy.WIDTH,
                        onViewCreated: (PDFViewController pdfViewController) {
                          controller = pdfViewController;
                        },
                        onPageChanged: (int? page, int? total) {
                          setState(() {
                            currentPage = page ?? 0;
                            totalPages = total ?? 0;
                          });
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentPage + 1}/$totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
