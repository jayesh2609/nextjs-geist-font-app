import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

import '../models/document_model.dart';
import '../services/database_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';
import '../services/image_processing_service.dart';

class DocumentProvider extends ChangeNotifier {
  List<DocumentModel> _documents = [];
  List<DocumentModel> _filteredDocuments = [];
  bool _isLoading = false;
  String _searchQuery = '';
  DocumentSortType _sortType = DocumentSortType.dateDesc;
  String? _selectedFolderId;

  // Getters
  List<DocumentModel> get documents => _filteredDocuments;
  List<DocumentModel> get allDocuments => _documents;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DocumentSortType get sortType => _sortType;
  String? get selectedFolderId => _selectedFolderId;

  // Initialize documents
  Future<void> initializeDocuments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await DatabaseService.instance.getAllDocuments();
      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Error initializing documents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new document
  Future<DocumentModel?> addDocument({
    required String title,
    required List<String> imagePaths,
    String? folderId,
    Map<String, dynamic>? metadata,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final document = DocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        imagePaths: imagePaths,
        folderId: folderId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      await DatabaseService.instance.insertDocument(document);
      _documents.insert(0, document);
      _applyFiltersAndSort();
      
      return document;
    } catch (e) {
      debugPrint('Error adding document: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update document
  Future<bool> updateDocument(DocumentModel document) async {
    try {
      final updatedDocument = document.copyWith(updatedAt: DateTime.now());
      await DatabaseService.instance.updateDocument(updatedDocument);
      
      final index = _documents.indexWhere((doc) => doc.id == document.id);
      if (index != -1) {
        _documents[index] = updatedDocument;
        _applyFiltersAndSort();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating document: $e');
      return false;
    }
  }

  // Delete document
  Future<bool> deleteDocument(String documentId) async {
    try {
      final document = _documents.firstWhere((doc) => doc.id == documentId);
      
      // Delete associated files
      for (final imagePath in document.imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Delete PDF if exists
      if (document.pdfPath != null) {
        final pdfFile = File(document.pdfPath!);
        if (await pdfFile.exists()) {
          await pdfFile.delete();
        }
      }
      
      await DatabaseService.instance.deleteDocument(documentId);
      _documents.removeWhere((doc) => doc.id == documentId);
      _applyFiltersAndSort();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }

  // Process document with OCR
  Future<bool> processDocumentOCR(String documentId, String languageCode) async {
    try {
      final document = _documents.firstWhere((doc) => doc.id == documentId);
      
      String extractedText = '';
      for (final imagePath in document.imagePaths) {
        final text = await OCRService.instance.extractText(imagePath, languageCode);
        extractedText += text + '\n\n';
      }
      
      final updatedDocument = document.copyWith(
        extractedText: extractedText.trim(),
        updatedAt: DateTime.now(),
      );
      
      return await updateDocument(updatedDocument);
    } catch (e) {
      debugPrint('Error processing OCR: $e');
      return false;
    }
  }

  // Generate PDF for document
  Future<bool> generatePDF(String documentId) async {
    try {
      final document = _documents.firstWhere((doc) => doc.id == documentId);
      
      final pdfPath = await PDFService.instance.generatePDF(
        title: document.title,
        imagePaths: document.imagePaths,
        extractedText: document.extractedText,
      );
      
      if (pdfPath != null) {
        final updatedDocument = document.copyWith(
          pdfPath: pdfPath,
          updatedAt: DateTime.now(),
        );
        
        return await updateDocument(updatedDocument);
      }
      
      return false;
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      return false;
    }
  }

  // Apply image filter
  Future<bool> applyImageFilter(
    String documentId,
    int imageIndex,
    ImageFilter filter,
  ) async {
    try {
      final document = _documents.firstWhere((doc) => doc.id == documentId);
      
      if (imageIndex >= document.imagePaths.length) return false;
      
      final originalPath = document.imagePaths[imageIndex];
      final filteredPath = await ImageProcessingService.instance.applyFilter(
        originalPath,
        filter,
      );
      
      if (filteredPath != null) {
        final updatedPaths = List<String>.from(document.imagePaths);
        updatedPaths[imageIndex] = filteredPath;
        
        final updatedDocument = document.copyWith(
          imagePaths: updatedPaths,
          updatedAt: DateTime.now(),
        );
        
        return await updateDocument(updatedDocument);
      }
      
      return false;
    } catch (e) {
      debugPrint('Error applying filter: $e');
      return false;
    }
  }

  // Search documents
  void searchDocuments(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // Sort documents
  void sortDocuments(DocumentSortType sortType) {
    _sortType = sortType;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // Filter by folder
  void filterByFolder(String? folderId) {
    _selectedFolderId = folderId;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // Apply filters and sorting
  void _applyFiltersAndSort() {
    List<DocumentModel> filtered = List.from(_documents);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        return doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (doc.extractedText?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply folder filter
    if (_selectedFolderId != null) {
      filtered = filtered.where((doc) => doc.folderId == _selectedFolderId).toList();
    }

    // Apply sorting
    switch (_sortType) {
      case DocumentSortType.dateDesc:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case DocumentSortType.dateAsc:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case DocumentSortType.titleAsc:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case DocumentSortType.titleDesc:
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
      case DocumentSortType.sizeDesc:
        filtered.sort((a, b) => b.imagePaths.length.compareTo(a.imagePaths.length));
        break;
    }

    _filteredDocuments = filtered;
  }

  // Get documents by folder
  List<DocumentModel> getDocumentsByFolder(String? folderId) {
    return _documents.where((doc) => doc.folderId == folderId).toList();
  }

  // Get recent documents
  List<DocumentModel> getRecentDocuments({int limit = 5}) {
    final recent = List<DocumentModel>.from(_documents);
    recent.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return recent.take(limit).toList();
  }

  // Get document statistics
  Map<String, int> getDocumentStats() {
    return {
      'total': _documents.length,
      'withOCR': _documents.where((doc) => doc.extractedText != null).length,
      'withPDF': _documents.where((doc) => doc.pdfPath != null).length,
      'thisMonth': _documents.where((doc) {
        final now = DateTime.now();
        return doc.createdAt.year == now.year && doc.createdAt.month == now.month;
      }).length,
    };
  }

  // Clear all documents (for testing)
  Future<void> clearAllDocuments() async {
    try {
      for (final document in _documents) {
        await deleteDocument(document.id);
      }
    } catch (e) {
      debugPrint('Error clearing documents: $e');
    }
  }
}

enum DocumentSortType {
  dateDesc,
  dateAsc,
  titleAsc,
  titleDesc,
  sizeDesc,
}

enum ImageFilter {
  none,
  blackWhite,
  grayscale,
  magicColor,
  lighten,
  darken,
  contrast,
  brightness,
}
