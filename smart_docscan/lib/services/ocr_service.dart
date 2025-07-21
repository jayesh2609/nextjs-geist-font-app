import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static final OCRService instance = OCRService._init();
  
  OCRService._init();

  // Extract text from image
  Future<String> extractText(String imagePath, String languageCode) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: _getTextRecognitionScript(languageCode));
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      await textRecognizer.close();
      
      return recognizedText.text;
    } catch (e) {
      debugPrint('Error extracting text: $e');
      return '';
    }
  }

  // Extract text with detailed information (blocks, lines, elements)
  Future<OCRResult> extractTextDetailed(String imagePath, String languageCode) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: _getTextRecognitionScript(languageCode));
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      await textRecognizer.close();
      
      return OCRResult(
        fullText: recognizedText.text,
        blocks: recognizedText.blocks.map((block) => OCRBlock(
          text: block.text,
          boundingBox: block.boundingBox,
          lines: block.lines.map((line) => OCRLine(
            text: line.text,
            boundingBox: line.boundingBox,
            elements: line.elements.map((element) => OCRElement(
              text: element.text,
              boundingBox: element.boundingBox,
            )).toList(),
          )).toList(),
        )).toList(),
      );
    } catch (e) {
      debugPrint('Error extracting detailed text: $e');
      return OCRResult(fullText: '', blocks: []);
    }
  }

  // Extract text from multiple images
  Future<List<String>> extractTextFromMultipleImages(
    List<String> imagePaths,
    String languageCode,
  ) async {
    final List<String> results = [];
    
    for (final imagePath in imagePaths) {
      final text = await extractText(imagePath, languageCode);
      results.add(text);
    }
    
    return results;
  }

  // Extract and combine text from multiple images
  Future<String> extractCombinedText(
    List<String> imagePaths,
    String languageCode,
  ) async {
    final textResults = await extractTextFromMultipleImages(imagePaths, languageCode);
    return textResults.join('\n\n--- Page Break ---\n\n');
  }

  // Get text recognition script based on language code
  TextRecognitionScript _getTextRecognitionScript(String languageCode) {
    switch (languageCode) {
      case 'zh':
      case 'zh-CN':
      case 'zh-TW':
        return TextRecognitionScript.chinese;
      case 'ja':
        return TextRecognitionScript.japanese;
      case 'ko':
        return TextRecognitionScript.korean;
      case 'hi':
      case 'mr':
      case 'ta':
      case 'te':
      case 'bn':
      case 'gu':
      case 'kn':
      case 'ml':
      case 'or':
      case 'pa':
      case 'ur':
        return TextRecognitionScript.devanagari;
      default:
        return TextRecognitionScript.latin;
    }
  }

  // Validate if image is suitable for OCR
  Future<bool> validateImageForOCR(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return false;
      
      final fileSize = await file.length();
      // Check if file size is reasonable (not too small or too large)
      if (fileSize < 1024 || fileSize > 50 * 1024 * 1024) return false;
      
      return true;
    } catch (e) {
      debugPrint('Error validating image: $e');
      return false;
    }
  }

  // Get supported languages
  List<OCRLanguage> getSupportedLanguages() {
    return [
      OCRLanguage(code: 'en', name: 'English', script: TextRecognitionScript.latin),
      OCRLanguage(code: 'hi', name: 'Hindi', script: TextRecognitionScript.devanagari),
      OCRLanguage(code: 'mr', name: 'Marathi', script: TextRecognitionScript.devanagari),
      OCRLanguage(code: 'ta', name: 'Tamil', script: TextRecognitionScript.devanagari),
      OCRLanguage(code: 'te', name: 'Telugu', script: TextRecognitionScript.devanagari),
      OCRLanguage(code: 'bn', name: 'Bengali', script: TextRecognitionScript.devanagari),
      OCRLanguage(code: 'gu', name: 'Gujarati', script: TextRecognitionScript.devanagari),
      OCRLanguage(code: 'kn', name: 'Kannada', script: TextRecognitionScript.devanagari),
      OCRLanguage(code: 'ml', name: 'Malayalam', script: TextRecognitionScript.devanagari),
      OCRLanguage(code: 'or', name: 'Odia', script: TextRecognitionScript.devanagari),
      OCRLanguage(code: 'pa', name: 'Punjabi', script: TextRecognitionScript.devanagari),
      OCRLanguage(code: 'ur', name: 'Urdu', script: TextRecognitionScript.devanagari),
      OCRLanguage(code: 'zh', name: 'Chinese', script: TextRecognitionScript.chinese),
      OCRLanguage(code: 'ja', name: 'Japanese', script: TextRecognitionScript.japanese),
      OCRLanguage(code: 'ko', name: 'Korean', script: TextRecognitionScript.korean),
      OCRLanguage(code: 'es', name: 'Spanish', script: TextRecognitionScript.latin),
      OCRLanguage(code: 'fr', name: 'French', script: TextRecognitionScript.latin),
      OCRLanguage(code: 'de', name: 'German', script: TextRecognitionScript.latin),
      OCRLanguage(code: 'it', name: 'Italian', script: TextRecognitionScript.latin),
      OCRLanguage(code: 'pt', name: 'Portuguese', script: TextRecognitionScript.latin),
      OCRLanguage(code: 'ru', name: 'Russian', script: TextRecognitionScript.latin),
      OCRLanguage(code: 'ar', name: 'Arabic', script: TextRecognitionScript.latin),
    ];
  }

  // Extract specific information (like phone numbers, emails, etc.)
  Future<Map<String, List<String>>> extractSpecificInfo(String text) async {
    final Map<String, List<String>> extractedInfo = {
      'emails': [],
      'phoneNumbers': [],
      'urls': [],
      'dates': [],
    };

    try {
      // Email regex
      final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
      extractedInfo['emails'] = emailRegex.allMatches(text).map((m) => m.group(0)!).toList();

      // Phone number regex (Indian format)
      final phoneRegex = RegExp(r'(\+91|91)?[-.\s]?[6-9]\d{9}');
      extractedInfo['phoneNumbers'] = phoneRegex.allMatches(text).map((m) => m.group(0)!).toList();

      // URL regex
      final urlRegex = RegExp(r'https?://[^\s]+');
      extractedInfo['urls'] = urlRegex.allMatches(text).map((m) => m.group(0)!).toList();

      // Date regex (various formats)
      final dateRegex = RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b|\b\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}\b');
      extractedInfo['dates'] = dateRegex.allMatches(text).map((m) => m.group(0)!).toList();
    } catch (e) {
      debugPrint('Error extracting specific info: $e');
    }

    return extractedInfo;
  }

  // Clean and format extracted text
  String cleanExtractedText(String text) {
    // Remove extra whitespaces
    String cleaned = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove leading/trailing whitespace
    cleaned = cleaned.trim();
    
    // Fix common OCR errors
    cleaned = cleaned.replaceAll(RegExp(r'[|]'), 'I');
    cleaned = cleaned.replaceAll(RegExp(r'[0O]'), 'O');
    
    return cleaned;
  }

  // Get text confidence score (if available)
  Future<double> getTextConfidence(String imagePath, String languageCode) async {
    try {
      final result = await extractTextDetailed(imagePath, languageCode);
      if (result.blocks.isEmpty) return 0.0;
      
      // Calculate average confidence (this is a simplified approach)
      // In a real implementation, you might want to use the actual confidence scores
      // provided by the ML Kit if available
      return result.fullText.isNotEmpty ? 0.85 : 0.0;
    } catch (e) {
      debugPrint('Error getting text confidence: $e');
      return 0.0;
    }
  }
}

// OCR Result classes
class OCRResult {
  final String fullText;
  final List<OCRBlock> blocks;

  OCRResult({
    required this.fullText,
    required this.blocks,
  });
}

class OCRBlock {
  final String text;
  final Rect boundingBox;
  final List<OCRLine> lines;

  OCRBlock({
    required this.text,
    required this.boundingBox,
    required this.lines,
  });
}

class OCRLine {
  final String text;
  final Rect boundingBox;
  final List<OCRElement> elements;

  OCRLine({
    required this.text,
    required this.boundingBox,
    required this.elements,
  });
}

class OCRElement {
  final String text;
  final Rect boundingBox;

  OCRElement({
    required this.text,
    required this.boundingBox,
  });
}

class OCRLanguage {
  final String code;
  final String name;
  final TextRecognitionScript script;

  OCRLanguage({
    required this.code,
    required this.name,
    required this.script,
  });
}
