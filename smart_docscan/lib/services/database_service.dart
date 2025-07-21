import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/document_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_docscan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Documents table
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        imagePaths TEXT NOT NULL,
        pdfPath TEXT,
        extractedText TEXT,
        folderId TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        metadata TEXT,
        tags TEXT,
        isFavorite INTEGER DEFAULT 0,
        isLocked INTEGER DEFAULT 0,
        password TEXT,
        FOREIGN KEY (folderId) REFERENCES folders (id)
      )
    ''');

    // Folders table
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        parentId TEXT,
        documentCount INTEGER DEFAULT 0,
        FOREIGN KEY (parentId) REFERENCES folders (id)
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_documents_created_at ON documents(createdAt)');
    await db.execute('CREATE INDEX idx_documents_folder_id ON documents(folderId)');
    await db.execute('CREATE INDEX idx_documents_title ON documents(title)');
    await db.execute('CREATE INDEX idx_folders_parent_id ON folders(parentId)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  // Document operations
  Future<void> insertDocument(DocumentModel document) async {
    final db = await database;
    final data = document.toJson();
    
    // Convert lists to JSON strings for storage
    data['imagePaths'] = document.imagePaths.join(',');
    data['tags'] = document.tags.join(',');
    
    await db.insert('documents', data, conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Update folder document count
    if (document.folderId != null) {
      await _updateFolderDocumentCount(document.folderId!);
    }
  }

  Future<List<DocumentModel>> getAllDocuments() async {
    final db = await database;
    final result = await db.query('documents', orderBy: 'createdAt DESC');
    
    return result.map((json) {
      // Convert comma-separated strings back to lists
      final data = Map<String, dynamic>.from(json);
      data['imagePaths'] = (json['imagePaths'] as String).split(',');
      data['tags'] = json['tags'] != null && (json['tags'] as String).isNotEmpty
          ? (json['tags'] as String).split(',')
          : <String>[];
      
      return DocumentModel.fromJson(data);
    }).toList();
  }

  Future<DocumentModel?> getDocument(String id) async {
    final db = await database;
    final result = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      final data = Map<String, dynamic>.from(result.first);
      data['imagePaths'] = (result.first['imagePaths'] as String).split(',');
      data['tags'] = result.first['tags'] != null && (result.first['tags'] as String).isNotEmpty
          ? (result.first['tags'] as String).split(',')
          : <String>[];
      
      return DocumentModel.fromJson(data);
    }
    
    return null;
  }

  Future<void> updateDocument(DocumentModel document) async {
    final db = await database;
    final data = document.toJson();
    
    // Convert lists to JSON strings for storage
    data['imagePaths'] = document.imagePaths.join(',');
    data['tags'] = document.tags.join(',');
    
    await db.update(
      'documents',
      data,
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    
    // Get document to check folder
    final document = await getDocument(id);
    
    await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Update folder document count
    if (document?.folderId != null) {
      await _updateFolderDocumentCount(document!.folderId!);
    }
  }

  Future<List<DocumentModel>> getDocumentsByFolder(String? folderId) async {
    final db = await database;
    final result = await db.query(
      'documents',
      where: folderId != null ? 'folderId = ?' : 'folderId IS NULL',
      whereArgs: folderId != null ? [folderId] : null,
      orderBy: 'createdAt DESC',
    );
    
    return result.map((json) {
      final data = Map<String, dynamic>.from(json);
      data['imagePaths'] = (json['imagePaths'] as String).split(',');
      data['tags'] = json['tags'] != null && (json['tags'] as String).isNotEmpty
          ? (json['tags'] as String).split(',')
          : <String>[];
      
      return DocumentModel.fromJson(data);
    }).toList();
  }

  Future<List<DocumentModel>> searchDocuments(String query) async {
    final db = await database;
    final result = await db.query(
      'documents',
      where: 'title LIKE ? OR extractedText LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    
    return result.map((json) {
      final data = Map<String, dynamic>.from(json);
      data['imagePaths'] = (json['imagePaths'] as String).split(',');
      data['tags'] = json['tags'] != null && (json['tags'] as String).isNotEmpty
          ? (json['tags'] as String).split(',')
          : <String>[];
      
      return DocumentModel.fromJson(data);
    }).toList();
  }

  // Folder operations
  Future<void> insertFolder(FolderModel folder) async {
    final db = await database;
    await db.insert('folders', folder.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FolderModel>> getAllFolders() async {
    final db = await database;
    final result = await db.query('folders', orderBy: 'name ASC');
    
    return result.map((json) => FolderModel.fromJson(json)).toList();
  }

  Future<FolderModel?> getFolder(String id) async {
    final db = await database;
    final result = await db.query(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return FolderModel.fromJson(result.first);
    }
    
    return null;
  }

  Future<void> updateFolder(FolderModel folder) async {
    final db = await database;
    await db.update(
      'folders',
      folder.toJson(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<void> deleteFolder(String id) async {
    final db = await database;
    
    // Move documents in this folder to root
    await db.update(
      'documents',
      {'folderId': null},
      where: 'folderId = ?',
      whereArgs: [id],
    );
    
    // Delete the folder
    await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _updateFolderDocumentCount(String folderId) async {
    final db = await database;
    
    // Count documents in folder
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM documents WHERE folderId = ?',
      [folderId],
    );
    
    final count = result.first['count'] as int;
    
    // Update folder document count
    await db.update(
      'folders',
      {'documentCount': count},
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }

  // Settings operations
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    
    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    
    return null;
  }

  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // Database maintenance
  Future<void> initDatabase() async {
    await database; // This will initialize the database
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('documents');
    await db.delete('folders');
    await db.delete('settings');
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final documentsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM documents'),
    ) ?? 0;
    
    final foldersCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM folders'),
    ) ?? 0;
    
    final settingsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM settings'),
    ) ?? 0;
    
    return {
      'documents': documentsCount,
      'folders': foldersCount,
      'settings': settingsCount,
    };
  }

  // Export database (for backup)
  Future<String?> exportDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final sourcePath = join(dbPath, 'smart_docscan.db');
      
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupPath = join(documentsDir.path, 'backup_${DateTime.now().millisecondsSinceEpoch}.db');
      
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(backupPath);
        return backupPath;
      }
    } catch (e) {
      print('Error exporting database: $e');
    }
    
    return null;
  }
}
