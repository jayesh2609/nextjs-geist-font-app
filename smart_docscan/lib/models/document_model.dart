import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class DocumentModel {
  final String id;
  final String title;
  final List<String> imagePaths;
  final String? pdfPath;
  final String? extractedText;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final bool isFavorite;
  final bool isLocked;
  final String? password;

  DocumentModel({
    required this.id,
    required this.title,
    required this.imagePaths,
    this.pdfPath,
    this.extractedText,
    this.folderId,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
    this.tags = const [],
    this.isFavorite = false,
    this.isLocked = false,
    this.password,
  });

  // Create copy with updated fields
  DocumentModel copyWith({
    String? id,
    String? title,
    List<String>? imagePaths,
    String? pdfPath,
    String? extractedText,
    String? folderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool? isFavorite,
    bool? isLocked,
    String? password,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePaths: imagePaths ?? this.imagePaths,
      pdfPath: pdfPath ?? this.pdfPath,
      extractedText: extractedText ?? this.extractedText,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
      password: password ?? this.password,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imagePaths': imagePaths,
      'pdfPath': pdfPath,
      'extractedText': extractedText,
      'folderId': folderId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'metadata': jsonEncode(metadata),
      'tags': tags,
      'isFavorite': isFavorite ? 1 : 0,
      'isLocked': isLocked ? 1 : 0,
      'password': password,
    };
  }

  // Create from JSON
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imagePaths: List<String>.from(json['imagePaths'] as List),
      pdfPath: json['pdfPath'] as String?,
      extractedText: json['extractedText'] as String?,
      folderId: json['folderId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(json['metadata'] as String))
          : {},
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'] as List)
          : [],
      isFavorite: (json['isFavorite'] as int?) == 1,
      isLocked: (json['isLocked'] as int?) == 1,
      password: json['password'] as String?,
    );
  }

  // Get file size in bytes
  Future<int> getFileSize() async {
    int totalSize = 0;
    
    try {
      // Calculate image files size
      for (final imagePath in imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }
      
      // Add PDF size if exists
      if (pdfPath != null) {
        final pdfFile = File(pdfPath!);
        if (await pdfFile.exists()) {
          totalSize += await pdfFile.length();
        }
      }
    } catch (e) {
      debugPrint('Error calculating file size: $e');
    }
    
    return totalSize;
  }

  // Get formatted file size
  Future<String> getFormattedFileSize() async {
    final sizeInBytes = await getFileSize();
    return _formatBytes(sizeInBytes);
  }

  // Format bytes to human readable format
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Get page count
  int get pageCount => imagePaths.length;

  // Check if document has OCR text
  bool get hasOCRText => extractedText != null && extractedText!.isNotEmpty;

  // Check if document has PDF
  bool get hasPDF => pdfPath != null;

  // Get document type based on content
  DocumentType get documentType {
    final titleLower = title.toLowerCase();
    
    if (titleLower.contains('id') || titleLower.contains('card') || titleLower.contains('license')) {
      return DocumentType.idCard;
    } else if (titleLower.contains('receipt') || titleLower.contains('bill')) {
      return DocumentType.receipt;
    } else if (titleLower.contains('contract') || titleLower.contains('agreement')) {
      return DocumentType.contract;
    } else if (titleLower.contains('report') || titleLower.contains('document')) {
      return DocumentType.report;
    } else if (titleLower.contains('note') || titleLower.contains('memo')) {
      return DocumentType.note;
    } else {
      return DocumentType.other;
    }
  }

  // Get document icon based on type
  IconData get documentIcon {
    switch (documentType) {
      case DocumentType.idCard:
        return Icons.badge;
      case DocumentType.receipt:
        return Icons.receipt;
      case DocumentType.contract:
        return Icons.description;
      case DocumentType.report:
        return Icons.article;
      case DocumentType.note:
        return Icons.note;
      case DocumentType.other:
        return Icons.insert_drive_file;
    }
  }

  // Check if document matches search query
  bool matchesSearch(String query) {
    final queryLower = query.toLowerCase();
    return title.toLowerCase().contains(queryLower) ||
           (extractedText?.toLowerCase().contains(queryLower) ?? false) ||
           tags.any((tag) => tag.toLowerCase().contains(queryLower));
  }

  @override
  String toString() {
    return 'DocumentModel(id: $id, title: $title, pageCount: $pageCount, hasOCR: $hasOCRText, hasPDF: $hasPDF)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum DocumentType {
  idCard,
  receipt,
  contract,
  report,
  note,
  other,
}

// Folder model for organizing documents
class FolderModel {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentId;
  final int documentCount;

  FolderModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.documentCount = 0,
  });

  FolderModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentId,
    int? documentCount,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentId: parentId ?? this.parentId,
      documentCount: documentCount ?? this.documentCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'parentId': parentId,
      'documentCount': documentCount,
    };
  }

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      parentId: json['parentId'] as String?,
      documentCount: json['documentCount'] as int? ?? 0,
    );
  }
}
