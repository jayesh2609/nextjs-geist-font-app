import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../providers/document_provider.dart';

class ImageProcessingService {
  static final ImageProcessingService instance = ImageProcessingService._init();
  
  ImageProcessingService._init();

  // Apply filter to image
  Future<String?> applyFilter(String imagePath, ImageFilter filter) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      img.Image processedImage;

      switch (filter) {
        case ImageFilter.blackWhite:
          processedImage = _applyBlackWhiteFilter(image);
          break;
        case ImageFilter.grayscale:
          processedImage = _applyGrayscaleFilter(image);
          break;
        case ImageFilter.magicColor:
          processedImage = _applyMagicColorFilter(image);
          break;
        case ImageFilter.lighten:
          processedImage = _applyBrightnessFilter(image, 30);
          break;
        case ImageFilter.darken:
          processedImage = _applyBrightnessFilter(image, -30);
          break;
        case ImageFilter.contrast:
          processedImage = _applyContrastFilter(image, 1.5);
          break;
        case ImageFilter.brightness:
          processedImage = _applyBrightnessFilter(image, 20);
          break;
        case ImageFilter.none:
        default:
          processedImage = image;
          break;
      }

      // Save processed image
      final processedPath = await _saveProcessedImage(processedImage, imagePath, filter);
      return processedPath;
    } catch (e) {
      debugPrint('Error applying filter: $e');
      return null;
    }
  }

  // Apply black and white filter
  img.Image _applyBlackWhiteFilter(img.Image image) {
    // Convert to grayscale first
    final grayscale = img.grayscale(image);
    
    // Apply threshold for black and white effect
    final threshold = 128;
    
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final gray = img.getRed(pixel);
        final newColor = gray > threshold ? 255 : 0;
        grayscale.setPixel(x, y, img.getColor(newColor, newColor, newColor));
      }
    }
    
    return grayscale;
  }

  // Apply grayscale filter
  img.Image _applyGrayscaleFilter(img.Image image) {
    return img.grayscale(image);
  }

  // Apply magic color filter (auto enhancement)
  img.Image _applyMagicColorFilter(img.Image image) {
    // Apply multiple enhancements
    var enhanced = img.adjustColor(image, 
      contrast: 1.2,
      saturation: 1.1,
      brightness: 1.05,
    );
    
    // Apply sharpening
    enhanced = img.convolution(enhanced, [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0
    ]);
    
    return enhanced;
  }

  // Apply brightness filter
  img.Image _applyBrightnessFilter(img.Image image, int brightness) {
    return img.adjustColor(image, brightness: 1.0 + (brightness / 100.0));
  }

  // Apply contrast filter
  img.Image _applyContrastFilter(img.Image image, double contrast) {
    return img.adjustColor(image, contrast: contrast);
  }

  // Apply custom brightness and contrast
  Future<String?> applyBrightnessContrast(
    String imagePath,
    double brightness,
    double contrast,
  ) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final processed = img.adjustColor(image,
        brightness: brightness,
        contrast: contrast,
      );

      final processedPath = await _saveProcessedImage(
        processed, 
        imagePath, 
        ImageFilter.brightness,
        suffix: '_brightness_contrast',
      );
      
      return processedPath;
    } catch (e) {
      debugPrint('Error applying brightness/contrast: $e');
      return null;
    }
  }

  // Crop image to specified rectangle
  Future<String?> cropImage(String imagePath, Rect cropRect) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final cropped = img.copyCrop(
        image,
        cropRect.left.toInt(),
        cropRect.top.toInt(),
        cropRect.width.toInt(),
        cropRect.height.toInt(),
      );

      final croppedPath = await _saveProcessedImage(
        cropped,
        imagePath,
        ImageFilter.none,
        suffix: '_cropped',
      );

      return croppedPath;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  // Rotate image
  Future<String?> rotateImage(String imagePath, double angle) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final rotated = img.copyRotate(image, angle);

      final rotatedPath = await _saveProcessedImage(
        rotated,
        imagePath,
        ImageFilter.none,
        suffix: '_rotated',
      );

      return rotatedPath;
    } catch (e) {
      debugPrint('Error rotating image: $e');
      return null;
    }
  }

  // Flip image horizontally or vertically
  Future<String?> flipImage(String imagePath, {bool horizontal = true}) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final flipped = horizontal 
          ? img.flipHorizontal(image)
          : img.flipVertical(image);

      final flippedPath = await _saveProcessedImage(
        flipped,
        imagePath,
        ImageFilter.none,
        suffix: horizontal ? '_flip_h' : '_flip_v',
      );

      return flippedPath;
    } catch (e) {
      debugPrint('Error flipping image: $e');
      return null;
    }
  }

  // Resize image
  Future<String?> resizeImage(String imagePath, int width, int height) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final resized = img.copyResize(image, width: width, height: height);

      final resizedPath = await _saveProcessedImage(
        resized,
        imagePath,
        ImageFilter.none,
        suffix: '_resized',
      );

      return resizedPath;
    } catch (e) {
      debugPrint('Error resizing image: $e');
      return null;
    }
  }

  // Apply perspective correction (basic implementation)
  Future<String?> correctPerspective(
    String imagePath,
    List<Offset> corners,
  ) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // This is a simplified perspective correction
      // In a real implementation, you would use more sophisticated algorithms
      final corrected = _applyPerspectiveTransform(image, corners);

      final correctedPath = await _saveProcessedImage(
        corrected,
        imagePath,
        ImageFilter.none,
        suffix: '_perspective',
      );

      return correctedPath;
    } catch (e) {
      debugPrint('Error correcting perspective: $e');
      return null;
    }
  }

  // Simple perspective transform (placeholder implementation)
  img.Image _applyPerspectiveTransform(img.Image image, List<Offset> corners) {
    // This is a placeholder implementation
    // In a real app, you would implement proper perspective transformation
    // using matrix calculations or OpenCV
    return image;
  }

  // Detect document edges (basic implementation)
  Future<List<Offset>?> detectDocumentEdges(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // This is a simplified edge detection
      // In a real implementation, you would use OpenCV or similar libraries
      final edges = _detectEdges(image);
      return edges;
    } catch (e) {
      debugPrint('Error detecting edges: $e');
      return null;
    }
  }

  // Simple edge detection (placeholder)
  List<Offset> _detectEdges(img.Image image) {
    // This is a placeholder implementation
    // Return corners of the image as default
    return [
      const Offset(0, 0), // Top-left
      Offset(image.width.toDouble(), 0), // Top-right
      Offset(image.width.toDouble(), image.height.toDouble()), // Bottom-right
      Offset(0, image.height.toDouble()), // Bottom-left
    ];
  }

  // Enhance document image (combination of filters)
  Future<String?> enhanceDocument(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Apply multiple enhancements for document scanning
      var enhanced = image;
      
      // 1. Adjust brightness and contrast
      enhanced = img.adjustColor(enhanced,
        brightness: 1.1,
        contrast: 1.3,
      );
      
      // 2. Apply sharpening
      enhanced = img.convolution(enhanced, [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0
      ]);
      
      // 3. Reduce noise
      enhanced = img.gaussianBlur(enhanced, 1);

      final enhancedPath = await _saveProcessedImage(
        enhanced,
        imagePath,
        ImageFilter.magicColor,
        suffix: '_enhanced',
      );

      return enhancedPath;
    } catch (e) {
      debugPrint('Error enhancing document: $e');
      return null;
    }
  }

  // Save processed image
  Future<String> _saveProcessedImage(
    img.Image image,
    String originalPath,
    ImageFilter filter, {
    String suffix = '',
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final processedDir = Directory(path.join(directory.path, 'processed'));
    
    if (!await processedDir.exists()) {
      await processedDir.create(recursive: true);
    }

    final originalFile = File(originalPath);
    final originalName = path.basenameWithoutExtension(originalFile.path);
    final extension = path.extension(originalFile.path);
    
    final filterSuffix = suffix.isNotEmpty ? suffix : '_${filter.name}';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${originalName}${filterSuffix}_$timestamp$extension';
    
    final processedPath = path.join(processedDir.path, fileName);
    final processedFile = File(processedPath);
    
    final encodedBytes = img.encodeJpg(image, quality: 90);
    await processedFile.writeAsBytes(encodedBytes);
    
    return processedPath;
  }

  // Get image dimensions
  Future<Size?> getImageDimensions(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      debugPrint('Error getting image dimensions: $e');
      return null;
    }
  }

  // Get image file size
  Future<int> getImageFileSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
    return 0;
  }

  // Compress image
  Future<String?> compressImage(String imagePath, {int quality = 80}) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final compressedPath = await _saveProcessedImage(
        image,
        imagePath,
        ImageFilter.none,
        suffix: '_compressed',
      );

      // Re-encode with specified quality
      final compressedFile = File(compressedPath);
      final encodedBytes = img.encodeJpg(image, quality: quality);
      await compressedFile.writeAsBytes(encodedBytes);

      return compressedPath;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  // Clean up processed images (remove old files)
  Future<void> cleanupProcessedImages({int daysOld = 7}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final processedDir = Directory(path.join(directory.path, 'processed'));
      
      if (!await processedDir.exists()) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      await for (final entity in processedDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up processed images: $e');
    }
  }
}
