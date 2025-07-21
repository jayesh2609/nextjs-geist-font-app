import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../providers/document_provider.dart';
import '../providers/premium_provider.dart';
import '../services/image_processing_service.dart';
import '../screens/ocr_preview_screen.dart';
import '../utils/app_theme.dart';

class CropFilterScreen extends StatefulWidget {
  final String imagePath;
  final bool isMultiPage;
  final List<String>? existingImages;

  const CropFilterScreen({
    super.key,
    required this.imagePath,
    this.isMultiPage = false,
    this.existingImages,
  });

  @override
  State<CropFilterScreen> createState() => _CropFilterScreenState();
}

class _CropFilterScreenState extends State<CropFilterScreen>
    with TickerProviderStateMixin {
  String _currentImagePath = '';
  ImageFilter _selectedFilter = ImageFilter.none;
  bool _isProcessing = false;
  bool _isCropMode = false;
  List<Offset> _cropCorners = [];
  
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  late TabController _tabController;

  final List<FilterOption> _filterOptions = [
    FilterOption(
      filter: ImageFilter.none,
      name: 'Original',
      icon: Icons.image,
    ),
    FilterOption(
      filter: ImageFilter.blackWhite,
      name: 'B&W',
      icon: Icons.contrast,
    ),
    FilterOption(
      filter: ImageFilter.magicColor,
      name: 'Magic Color',
      icon: Icons.auto_fix_high,
    ),
    FilterOption(
      filter: ImageFilter.grayscale,
      name: 'Grayscale',
      icon: Icons.filter_b_and_w,
    ),
    FilterOption(
      filter: ImageFilter.lighten,
      name: 'Lighten',
      icon: Icons.brightness_high,
    ),
    FilterOption(
      filter: ImageFilter.darken,
      name: 'Darken',
      icon: Icons.brightness_low,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _detectDocumentEdges();
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _filterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _detectDocumentEdges() async {
    try {
      final edges = await ImageProcessingService.instance.detectDocumentEdges(_currentImagePath);
      if (edges != null && mounted) {
        setState(() {
          _cropCorners = edges;
        });
      }
    } catch (e) {
      debugPrint('Error detecting edges: $e');
    }
  }

  Future<void> _applyFilter(ImageFilter filter) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _selectedFilter = filter;
    });

    _filterAnimationController.forward();

    try {
      final filteredPath = await ImageProcessingService.instance.applyFilter(
        widget.imagePath,
        filter,
      );

      if (filteredPath != null && mounted) {
        setState(() {
          _currentImagePath = filteredPath;
        });
      }
    } catch (e) {
      debugPrint('Error applying filter: $e');
      _showErrorSnackBar('Failed to apply filter');
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _filterAnimationController.reverse();
    }
  }

  Future<void> _cropImage() async {
    if (_cropCorners.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final cropRect = _calculateCropRect();
      
      final croppedPath = await ImageProcessingService.instance.cropImage(
        _currentImagePath,
        cropRect,
      );

      if (croppedPath != null && mounted) {
        setState(() {
          _currentImagePath = croppedPath;
          _isCropMode = false;
        });
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      _showErrorSnackBar('Failed to crop image');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Rect _calculateCropRect() {
    if (_cropCorners.length < 4) {
      return Rect.fromLTWH(0, 0, 100, 100);
    }

    final left = _cropCorners.map((c) => c.dx).reduce((a, b) => a < b ? a : b);
    final top = _cropCorners.map((c) => c.dy).reduce((a, b) => a < b ? a : b);
    final right = _cropCorners.map((c) => c.dx).reduce((a, b) => a > b ? a : b);
    final bottom = _cropCorners.map((c) => c.dy).reduce((a, b) => a > b ? a : b);

    return Rect.fromLTRB(left, top, right, bottom);
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

  void _proceedToOCR() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OCRPreviewScreen(
          imagePath: _currentImagePath,
          isMultiPage: widget.isMultiPage,
          existingImages: widget.existingImages,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop & Filter'),
        actions: [
          if (_isCropMode)
            TextButton(
              onPressed: _cropImage,
              child: const Text(
                'Apply',
                style: TextStyle(color: AppTheme.primaryGreen),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Image preview
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              child: Stack(
                children: [
                  // Image
                  Center(
                    child: _buildImagePreview(),
                  ),
                  
                  // Processing overlay
                  if (_isProcessing)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Controls
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.textDark,
                    unselectedLabelColor: AppTheme.textGray,
                    indicatorColor: AppTheme.primaryGreen,
                    tabs: const [
                      Tab(text: 'Crop'),
                      Tab(text: 'Filter'),
                    ],
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCropTab(),
                        _buildFilterTab(),
                      ],
                    ),
                  ),

                  // Bottom actions
                  _buildBottomActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return InteractiveViewer(
      panEnabled: true,
      scaleEnabled: true,
      child: Image.file(
        File(_currentImagePath),
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
    );
  }

  Widget _buildCropTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Auto crop button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _detectDocumentEdges,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Auto Detect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Manual crop button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isCropMode = !_isCropMode;
                });
              },
              icon: Icon(_isCropMode ? Icons.check : Icons.crop),
              label: Text(_isCropMode ? 'Done' : 'Manual Crop'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Rotate buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rotateImage(-90),
                  icon: const Icon(Icons.rotate_left),
                  label: const Text('Rotate Left'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rotateImage(90),
                  icon: const Icon(Icons.rotate_right),
                  label: const Text('Rotate Right'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option.filter;

          return GestureDetector(
            onTap: () => _applyFilter(option.filter),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.textGray.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    option.icon,
                    size: 32,
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.textGray,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
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
      child: Row(
        children: [
          // Retake button
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textGray,
                side: BorderSide(color: AppTheme.textGray.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Retake'),
            ),
          ),

          const SizedBox(width: 16),

          // Continue button
          Expanded(
            child: ElevatedButton(
              onPressed: _proceedToOCR,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rotateImage(double angle) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final rotatedPath = await ImageProcessingService.instance.rotateImage(
        _currentImagePath,
        angle,
      );

      if (rotatedPath != null && mounted) {
        setState(() {
          _currentImagePath = rotatedPath;
        });
      }
    } catch (e) {
      debugPrint('Error rotating image: $e');
      _showErrorSnackBar('Failed to rotate image');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

class FilterOption {
  final ImageFilter filter;
  final String name;
  final IconData icon;

  FilterOption({
    required this.filter,
    required this.name,
    required this.icon,
  });
}
