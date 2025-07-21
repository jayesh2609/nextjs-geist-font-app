import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PDFService {
  static final PDFService instance = PDFService._init();
  
  PDFService._init();

  // Generate PDF from images and text
  Future<String?> generatePDF({
    required String title,
    required List<String> imagePaths,
    String? extractedText,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Add cover page if there's extracted text
      if (extractedText != null && extractedText.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Generated on: ${DateTime.now().toString().split('.')[0]}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Extracted Text:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Expanded(
                    child: pw.Text(
                      extractedText,
                      style: const pw.TextStyle(fontSize: 12),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Add image pages
      for (int i = 0; i < imagePaths.length; i++) {
        final imageFile = File(imagePaths[i]);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          final image = pw.MemoryImage(imageBytes);
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Column(
                  children: [
                    if (extractedText != null && extractedText.isNotEmpty)
                      pw.Header(
                        level: 1,
                        child: pw.Text('Page ${i + 1}'),
                      ),
                    pw.Expanded(
                      child: pw.Center(
                        child: pw.Image(
                          image,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      }

      // Save PDF
      final pdfPath = await _savePDF(pdf, title);
      return pdfPath;
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      return null;
    }
  }

  // Generate PDF with custom layout
  Future<String?> generateCustomPDF({
    required String title,
    required List<String> imagePaths,
    String? extractedText,
    PDFLayout layout = PDFLayout.singlePage,
    bool includeTextPage = true,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final pdf = pw.Document();

      switch (layout) {
        case PDFLayout.singlePage:
          await _addSinglePageLayout(pdf, title, imagePaths, extractedText);
          break;
        case PDFLayout.multiPage:
          await _addMultiPageLayout(pdf, title, imagePaths, extractedText);
          break;
        case PDFLayout.grid:
          await _addGridLayout(pdf, title, imagePaths, extractedText);
          break;
      }

      final pdfPath = await _savePDF(pdf, title);
      return pdfPath;
    } catch (e) {
      debugPrint('Error generating custom PDF: $e');
      return null;
    }
  }

  // Add single page layout
  Future<void> _addSinglePageLayout(
    pw.Document pdf,
    String title,
    List<String> imagePaths,
    String? extractedText,
  ) async {
    for (int i = 0; i < imagePaths.length; i++) {
      final imageFile = File(imagePaths[i]);
      if (await imageFile.exists()) {
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$title - Page ${i + 1}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Expanded(
                    child: pw.Image(
                      image,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    }
  }

  // Add multi-page layout
  Future<void> _addMultiPageLayout(
    pw.Document pdf,
    String title,
    List<String> imagePaths,
    String? extractedText,
  ) async {
    // Add title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated on ${DateTime.now().toString().split('.')[0]}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Total Pages: ${imagePaths.length}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Add image pages
    await _addSinglePageLayout(pdf, title, imagePaths, extractedText);

    // Add text page if available
    if (extractedText != null && extractedText.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Extracted Text',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Expanded(
                  child: pw.Text(
                    extractedText,
                    style: const pw.TextStyle(fontSize: 12),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  // Add grid layout (multiple images per page)
  Future<void> _addGridLayout(
    pw.Document pdf,
    String title,
    List<String> imagePaths,
    String? extractedText,
  ) async {
    const imagesPerPage = 4; // 2x2 grid
    
    for (int i = 0; i < imagePaths.length; i += imagesPerPage) {
      final pageImages = <pw.MemoryImage>[];
      
      for (int j = i; j < i + imagesPerPage && j < imagePaths.length; j++) {
        final imageFile = File(imagePaths[j]);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          pageImages.add(pw.MemoryImage(imageBytes));
        }
      }
      
      if (pageImages.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$title - Pages ${i + 1}-${(i + pageImages.length).clamp(0, imagePaths.length)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Expanded(
                    child: pw.GridView(
                      crossAxisCount: 2,
                      children: pageImages.map((image) => 
                        pw.Container(
                          margin: const pw.EdgeInsets.all(5),
                          child: pw.Image(image, fit: pw.BoxFit.contain),
                        ),
                      ).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    }
  }

  // Save PDF to file
  Future<String> _savePDF(pw.Document pdf, String title) async {
    final directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path.join(directory.path, 'pdfs'));
    
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}_$timestamp.pdf';
    final pdfPath = path.join(pdfDir.path, fileName);
    
    final file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());
    
    return pdfPath;
  }

  // Share PDF
  Future<void> sharePDF(String pdfPath, {String? subject}) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(pdfPath)],
          subject: subject ?? 'Scanned Document',
          text: 'Sharing scanned document from Smart DocScan',
        );
      }
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    }
  }

  // Print PDF
  Future<void> printPDF(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
        );
      }
    } catch (e) {
      debugPrint('Error printing PDF: $e');
    }
  }

  // Get PDF info
  Future<PDFInfo?> getPDFInfo(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        final stat = await file.stat();
        final size = await file.length();
        
        return PDFInfo(
          path: pdfPath,
          fileName: path.basename(pdfPath),
          fileSize: size,
          createdAt: stat.modified,
        );
      }
    } catch (e) {
      debugPrint('Error getting PDF info: $e');
    }
    return null;
  }

  // Merge multiple PDFs
  Future<String?> mergePDFs(List<String> pdfPaths, String outputTitle) async {
    try {
      final mergedPdf = pw.Document();
      
      for (final pdfPath in pdfPaths) {
        final file = File(pdfPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          // Note: This is a simplified merge - in a real implementation,
          // you would need a proper PDF parsing library
          // For now, we'll just add a page indicating the merged file
          mergedPdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Text(
                    'Merged from: ${path.basename(pdfPath)}',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          );
        }
      }
      
      final mergedPath = await _savePDF(mergedPdf, '${outputTitle}_merged');
      return mergedPath;
    } catch (e) {
      debugPrint('Error merging PDFs: $e');
      return null;
    }
  }

  // Convert PDF to images (extract pages as images)
  Future<List<String>?> pdfToImages(String pdfPath) async {
    try {
      // This would require a PDF rendering library
      // For now, return null as placeholder
      debugPrint('PDF to images conversion not implemented');
      return null;
    } catch (e) {
      debugPrint('Error converting PDF to images: $e');
      return null;
    }
  }

  // Add password protection to PDF
  Future<String?> addPasswordToPDF(String pdfPath, String password) async {
    try {
      // This would require PDF encryption capabilities
      // For now, return the original path as placeholder
      debugPrint('PDF password protection not implemented');
      return pdfPath;
    } catch (e) {
      debugPrint('Error adding password to PDF: $e');
      return null;
    }
  }

  // Get PDF page count
  Future<int> getPDFPageCount(String pdfPath) async {
    try {
      // This would require PDF parsing
      // For now, return 1 as placeholder
      return 1;
    } catch (e) {
      debugPrint('Error getting PDF page count: $e');
      return 0;
    }
  }

  // Compress PDF
  Future<String?> compressPDF(String pdfPath, {double quality = 0.8}) async {
    try {
      // This would require PDF compression capabilities
      // For now, return the original path as placeholder
      debugPrint('PDF compression not implemented');
      return pdfPath;
    } catch (e) {
      debugPrint('Error compressing PDF: $e');
      return null;
    }
  }

  // Clean up old PDFs
  Future<void> cleanupOldPDFs({int daysOld = 30}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pdfDir = Directory(path.join(directory.path, 'pdfs'));
      
      if (!await pdfDir.exists()) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      await for (final entity in pdfDir.list()) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old PDFs: $e');
    }
  }

  // Get all PDFs in directory
  Future<List<String>> getAllPDFs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pdfDir = Directory(path.join(directory.path, 'pdfs'));
      
      if (!await pdfDir.exists()) return [];

      final pdfPaths = <String>[];
      
      await for (final entity in pdfDir.list()) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          pdfPaths.add(entity.path);
        }
      }
      
      return pdfPaths;
    } catch (e) {
      debugPrint('Error getting all PDFs: $e');
      return [];
    }
  }
}

// PDF Layout options
enum PDFLayout {
  singlePage,
  multiPage,
  grid,
}

// PDF Info class
class PDFInfo {
  final String path;
  final String fileName;
  final int fileSize;
  final DateTime createdAt;

  PDFInfo({
    required this.path,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
  });

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
