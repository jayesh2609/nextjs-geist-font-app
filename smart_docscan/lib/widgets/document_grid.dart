import 'package:flutter/material.dart';
import 'dart:io';

import '../models/document_model.dart';
import '../utils/app_theme.dart';

class DocumentGrid extends StatelessWidget {
  final List<DocumentModel> documents;
  final Function(DocumentModel) onDocumentTap;
  final Function(DocumentModel)? onDocumentLongPress;
  final bool isSelectionMode;
  final Set<String> selectedDocuments;

  const DocumentGrid({
    super.key,
    required this.documents,
    required this.onDocumentTap,
    this.onDocumentLongPress,
    this.isSelectionMode = false,
    this.selectedDocuments = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentCard(
          document: document,
          onTap: () => onDocumentTap(document),
          onLongPress: onDocumentLongPress != null 
              ? () => onDocumentLongPress!(document)
              : null,
          isSelected: selectedDocuments.contains(document.id),
          isSelectionMode: isSelectionMode,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.textGray.withOpacity(0.3),
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              size: 48,
              color: AppTheme.textGray.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No documents found',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentCard extends StatefulWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: widget.isSelected
                    ? Border.all(color: AppTheme.primaryGreen, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document preview
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Document image or placeholder
                          _buildDocumentPreview(),
                          
                          // Selection overlay
                          if (widget.isSelectionMode)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: widget.isSelected
                                      ? AppTheme.primaryGreen
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.isSelected
                                        ? AppTheme.primaryGreen
                                        : AppTheme.textGray,
                                    width: 2,
                                  ),
                                ),
                                child: widget.isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),

                          // Document type badge
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.document.documentIcon,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.document.pageCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Premium features badge
                          if (widget.document.isLocked)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Document info
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Document title
                          Text(
                            widget.document.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // Document date and size
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatDate(widget.document.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textGray,
                                  ),
                                ),
                              ),
                              if (widget.document.hasOCRText)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'OCR',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Features row
                          Row(
                            children: [
                              if (widget.document.hasPDF)
                                _buildFeatureIcon(Icons.picture_as_pdf, Colors.red),
                              if (widget.document.hasOCRText)
                                _buildFeatureIcon(Icons.text_fields, AppTheme.primaryGreen),
                              if (widget.document.isFavorite)
                                _buildFeatureIcon(Icons.favorite, Colors.pink),
                              const Spacer(),
                              Icon(
                                Icons.more_vert,
                                size: 16,
                                color: AppTheme.textGray,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentPreview() {
    if (widget.document.imagePaths.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
          ),
        ),
        child: Center(
          child: Icon(
            widget.document.documentIcon,
            size: 32,
            color: AppTheme.textGray,
          ),
        ),
      );
    }

    final imagePath = widget.document.imagePaths.first;
    final imageFile = File(imagePath);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12),
      ),
      child: FutureBuilder<bool>(
        future: imageFile.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              imageFile,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return child;
                }
                return _buildLoadingPlaceholder();
              },
            );
          } else {
            return _buildPlaceholder();
          }
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.document.documentIcon,
              size: 32,
              color: AppTheme.textGray,
            ),
            const SizedBox(height: 8),
            Text(
              'Preview\nUnavailable',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        icon,
        size: 12,
        color: color,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }
}

// Document list view (alternative to grid)
class DocumentList extends StatelessWidget {
  final List<DocumentModel> documents;
  final Function(DocumentModel) onDocumentTap;
  final Function(DocumentModel)? onDocumentLongPress;
  final bool isSelectionMode;
  final Set<String> selectedDocuments;

  const DocumentList({
    super.key,
    required this.documents,
    required this.onDocumentTap,
    this.onDocumentLongPress,
    this.isSelectionMode = false,
    this.selectedDocuments = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(
        child: Text('No documents found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentListTile(
          document: document,
          onTap: () => onDocumentTap(document),
          onLongPress: onDocumentLongPress != null 
              ? () => onDocumentLongPress!(document)
              : null,
          isSelected: selectedDocuments.contains(document.id),
          isSelectionMode: isSelectionMode,
        );
      },
    );
  }
}

class DocumentListTile extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const DocumentListTile({
    super.key,
    required this.document,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppTheme.primaryGreen, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            document.documentIcon,
            color: AppTheme.primaryGreen,
          ),
        ),
        title: Text(
          document.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${document.pageCount} page${document.pageCount > 1 ? 's' : ''} • ${_formatDate(document.createdAt)}',
              style: TextStyle(
                color: AppTheme.textGray,
                fontSize: 12,
              ),
            ),
            if (document.hasOCRText) ...[
              const SizedBox(height: 4),
              Text(
                document.extractedText!.length > 50
                    ? '${document.extractedText!.substring(0, 50)}...'
                    : document.extractedText!,
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: isSelectionMode
            ? Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryGreen : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.textGray,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              )
            : Icon(
                Icons.more_vert,
                color: AppTheme.textGray,
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
