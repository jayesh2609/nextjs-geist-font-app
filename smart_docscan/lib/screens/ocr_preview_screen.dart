import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../providers/app_state_provider.dart';
import '../providers/document_provider.dart';
import '../providers/premium_provider.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';
import '../utils/app_theme.dart';

class OCRPreviewScreen extends StatefulWidget {
  final String imagePath;
  final bool isMultiPage;
  final List<String>? existingImages;

  const OCRPreviewScreen({
    super.key,
    required this.imagePath,
    this.isMultiPage = false,
    this.existingImages,
  });

  @override
  State<OCRPreviewScreen> createState() => _OCRPreviewScreenState();
}

class _OCRPreviewScreenState extends State<OCRPreviewScreen>
    with TickerProviderStateMixin {
  String _extractedText = '';
  bool _isProcessingOCR = false;
  bool _isGeneratingPDF = false;
  bool _isTextEditable = false;
  String _documentTitle = '';
  
  late TabController _tabController;
  late TextEditingController _textController;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _textController = TextEditingController();
    _titleController = TextEditingController();
    _documentTitle = 'Scanned Document ${DateTime.now().millisecondsSinceEpoch}';
    _titleController.text = _documentTitle;
    _performOCR();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _performOCR() async {
    setState(() {
      _isProcessingOCR = true;
    });

    try {
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      final languageCode = appStateProvider.selectedLanguage;
      
      final extractedText = await OCRService.instance.extractText(
        widget.imagePath,
        languageCode,
      );

      if (mounted) {
        setState(() {
          _extractedText = extractedText;
          _textController.text = extractedText;
        });
      }
    } catch (e) {
      debugPrint('Error performing OCR: $e');
      _showErrorSnackBar('Failed to extract text from image');
    } finally {
      setState(() {
        _isProcessingOCR = false;
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_documentTitle.trim().isEmpty) {
      _showErrorSnackBar('Please enter a document title');
      return;
    }

    try {
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      
      final imagePaths = widget.existingImages != null 
          ? [...widget.existingImages!, widget.imagePath]
          : [widget.imagePath];

      final document = await documentProvider.addDocument(
        title: _documentTitle.trim(),
        imagePaths: imagePaths,
        metadata: {
          'ocr_language': Provider.of<AppStateProvider>(context, listen: false).selectedLanguage,
          'created_from': 'scan',
        },
      );

      if (document != null) {
        // Update document with OCR text
        final updatedDocument = document.copyWith(
          extractedText: _textController.text.trim(),
        );
        
        await documentProvider.updateDocument(updatedDocument);

        if (mounted) {
          // Show success message and navigate back to home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document saved successfully!'),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate back to home screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        _showErrorSnackBar('Failed to save document');
      }
    } catch (e) {
      debugPrint('Error saving document: $e');
      _showErrorSnackBar('Failed to save document');
    }
  }

  Future<void> _generateAndSharePDF() async {
    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final imagePaths = widget.existingImages != null 
          ? [...widget.existingImages!, widget.imagePath]
          : [widget.imagePath];

      final pdfPath = await PDFService.instance.generatePDF(
        title: _documentTitle.trim(),
        imagePaths: imagePaths,
        extractedText: _textController.text.trim(),
      );

      if (pdfPath != null && mounted) {
        await PDFService.instance.sharePDF(
          pdfPath,
          subject: _documentTitle.trim(),
        );
      } else {
        _showErrorSnackBar('Failed to generate PDF');
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      _showErrorSnackBar('Failed to generate PDF');
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
  }

  void _copyTextToClipboard() {
    if (_extractedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _extractedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareText() {
    if (_extractedText.isNotEmpty) {
      Share.share(
        _extractedText,
        subject: _documentTitle.trim(),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select OCR Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Consumer<AppStateProvider>(
                builder: (context, provider, child) {
                  final languages = provider.getSupportedLanguages();
                  
                  return Column(
                    children: languages.map((lang) {
                      final isSelected = provider.selectedLanguage == lang['code'];
                      
                      return ListTile(
                        title: Text(lang['name']!),
                        trailing: isSelected 
                            ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                            : null,
                        onTap: () async {
                          await provider.setLanguage(lang['code']!);
                          Navigator.of(context).pop();
                          _performOCR(); // Re-run OCR with new language
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        title: const Text('OCR Preview'),
        actions: [
          IconButton(
            onPressed: _showLanguageSelector,
            icon: const Icon(Icons.language),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _copyTextToClipboard();
                  break;
                case 'share_text':
                  _shareText();
                  break;
                case 'share_pdf':
                  _generateAndSharePDF();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Copy Text'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_text',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share Text'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Share as PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Document title input
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Document Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              onChanged: (value) {
                _documentTitle = value;
              },
            ),
          ),

          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.textDark,
              unselectedLabelColor: AppTheme.textGray,
              indicatorColor: AppTheme.primaryGreen,
              tabs: const [
                Tab(
                  icon: Icon(Icons.image),
                  text: 'Image',
                ),
                Tab(
                  icon: Icon(Icons.text_fields),
                  text: 'Text',
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildImageTab(),
                _buildTextTab(),
              ],
            ),
          ),

          // Bottom actions
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildImageTab() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: AppTheme.backgroundGray,
                  child: const Center(
                    child: Icon(
                      Icons.error,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextTab() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // OCR status and controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.textGray.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                if (_isProcessingOCR) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Extracting text...'),
                ] else ...[
                  Icon(
                    _extractedText.isNotEmpty ? Icons.check_circle : Icons.error,
                    color: _extractedText.isNotEmpty ? AppTheme.primaryGreen : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _extractedText.isNotEmpty 
                        ? 'Text extracted successfully'
                        : 'No text found',
                  ),
                ],
                
                const Spacer(),
                
                // Edit toggle
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isTextEditable = !_isTextEditable;
                    });
                  },
                  icon: Icon(
                    _isTextEditable ? Icons.check : Icons.edit,
                    size: 16,
                  ),
                  label: Text(_isTextEditable ? 'Done' : 'Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),

          // Text content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isTextEditable
                  ? TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Edit extracted text...',
                      ),
                      textAlignVertical: TextAlignVertical.top,
                    )
                  : SingleChildScrollView(
                      child: SelectableText(
                        _extractedText.isNotEmpty 
                            ? _extractedText 
                            : 'No text extracted from the image.\n\nTry:\n• Using better lighting\n• Ensuring text is clear and readable\n• Selecting the correct language\n• Retaking the photo',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: _extractedText.isNotEmpty 
                              ? AppTheme.textDark 
                              : AppTheme.textGray,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Consumer<PremiumProvider>(
        builder: (context, premiumProvider, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium features info
              if (!premiumProvider.isPremium && _extractedText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Upgrade to Premium for unlimited OCR and advanced features',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to premium screen
                        },
                        child: const Text('Upgrade'),
                      ),
                    ],
                  ),
                ),

              // Action buttons
              Row(
                children: [
                  // Retake button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil(
                          (route) => route.settings.name == '/scan' || route.isFirst,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textGray,
                        side: BorderSide(color: AppTheme.textGray.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Retake'),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Save button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveDocument,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Document'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Secondary actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _extractedText.isNotEmpty ? _copyTextToClipboard : null,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _extractedText.isNotEmpty ? _shareText : null,
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isGeneratingPDF ? null : _generateAndSharePDF,
                    icon: _isGeneratingPDF 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('PDF'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
