import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../providers/premium_provider.dart';
import '../screens/crop_filter_screen.dart';
import '../utils/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isRearCamera = true;
  bool _isCapturing = false;
  final ImagePicker _imagePicker = ImagePicker();
  
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _scanAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    ));

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _scanAnimationController.repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        final camera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Smart DocScan needs camera access to scan documents. Please grant camera permission in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      
      if (mounted) {
        // Navigate to crop and filter screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CropFilterScreen(
              imagePath: image.path,
              isMultiPage: false,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      _showErrorSnackBar('Failed to capture image');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CropFilterScreen(
              imagePath: image.path,
              isMultiPage: false,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      _showErrorSnackBar('Failed to pick image from gallery');
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isCameraInitialized) return;

    try {
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (!_isCameraInitialized || _cameras == null || _cameras!.length < 2) return;

    try {
      final newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == 
            (_isRearCamera ? CameraLensDirection.front : CameraLensDirection.back),
        orElse: () => _cameras!.first,
      );

      await _cameraController!.dispose();
      
      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      setState(() {
        _isRearCamera = !_isRearCamera;
        _isFlashOn = false; // Reset flash when switching cameras
      });
    } catch (e) {
      debugPrint('Error switching camera: $e');
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

  void _showSampleFilesDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sample document image
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        size: 48,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sample Document',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Try sample files',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'No documents on hand? Try scanning the sample files',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Load sample document
                        _loadSampleDocument();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadSampleDocument() {
    // This would load a sample document for demonstration
    // For now, we'll just show a message
    _showErrorSnackBar('Sample document feature coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            ),

          // Document detection overlay
          if (_isCameraInitialized)
            Positioned.fill(
              child: _buildDocumentOverlay(),
            ),

          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildTopControls(),
          ),

          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),

          // HD Scan button (floating)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 120,
            left: 0,
            right: 0,
            child: _buildHDScanButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentOverlay() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: DocumentOverlayPainter(
            scanProgress: _scanAnimation.value,
            isScanning: _isCapturing,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildTopControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Close button
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.close,
            color: Colors.white,
            size: 28,
          ),
        ),

        // Title
        const Text(
          'HD scan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Settings button
        IconButton(
          onPressed: () {
            // Show scan settings
          },
          icon: const Icon(
            Icons.settings,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Column(
      children: [
        // Main action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Gallery button
            _buildControlButton(
              icon: Icons.photo_library,
              onPressed: _pickFromGallery,
            ),

            // Capture button
            AnimatedBuilder(
              animation: _buttonScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _buttonScaleAnimation.value,
                  child: GestureDetector(
                    onTap: _captureImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isCapturing 
                            ? AppTheme.primaryGreen.withOpacity(0.8)
                            : AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isCapturing ? Icons.hourglass_empty : Icons.camera_alt,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Flash button
            _buildControlButton(
              icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
              onPressed: _toggleFlash,
              isActive: _isFlashOn,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Secondary controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Sample files button
            _buildSecondaryButton(
              icon: Icons.folder_open,
              label: 'Sample Files',
              onPressed: _showSampleFilesDialog,
            ),

            // Switch camera button (if available)
            if (_cameras != null && _cameras!.length > 1)
              _buildSecondaryButton(
                icon: Icons.flip_camera_ios,
                label: 'Switch',
                onPressed: _switchCamera,
              ),

            // Multi-page scan button
            Consumer<PremiumProvider>(
              builder: (context, premiumProvider, child) {
                return _buildSecondaryButton(
                  icon: Icons.library_add,
                  label: 'Multi-page',
                  onPressed: premiumProvider.isPremium
                      ? () {
                          // Start multi-page scan
                        }
                      : () {
                          // Show premium upgrade dialog
                        },
                  isPremium: !premiumProvider.isPremium,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHDScanButton() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HD scan',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Start here',
              style: TextStyle(
                color: AppTheme.textGray,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isActive 
            ? AppTheme.primaryGreen 
            : Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPremium = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                if (isPremium)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for document detection overlay
class DocumentOverlayPainter extends CustomPainter {
  final double scanProgress;
  final bool isScanning;

  DocumentOverlayPainter({
    required this.scanProgress,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw overlay shadow
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final documentRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.6,
    );
    
    final documentPath = Path()
      ..addRRect(RRect.fromRectAndRadius(documentRect, const Radius.circular(12)));
    
    final combinedPath = Path.combine(PathOperation.difference, overlayPath, documentPath);
    canvas.drawPath(combinedPath, shadowPaint);

    // Draw document frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(documentRect, const Radius.circular(12)),
      paint,
    );

    // Draw corner indicators
    final cornerSize = 20.0;
    final cornerPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset(documentRect.left, documentRect.top + cornerSize),
      Offset(documentRect.left, documentRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(documentRect.left, documentRect.top),
      Offset(documentRect.left + cornerSize, documentRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(documentRect.right - cornerSize, documentRect.top),
      Offset(documentRect.right, documentRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(documentRect.right, documentRect.top),
      Offset(documentRect.right, documentRect.top + cornerSize),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(documentRect.left, documentRect.bottom - cornerSize),
      Offset(documentRect.left, documentRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(documentRect.left, documentRect.bottom),
      Offset(documentRect.left + cornerSize, documentRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(documentRect.right - cornerSize, documentRect.bottom),
      Offset(documentRect.right, documentRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(documentRect.right, documentRect.bottom),
      Offset(documentRect.right, documentRect.bottom - cornerSize),
      cornerPaint,
    );

    // Draw scanning line if capturing
    if (isScanning) {
      final scanLinePaint = Paint()
        ..color = AppTheme.primaryGreen.withOpacity(0.8)
        ..strokeWidth = 2;

      final scanY = documentRect.top + (documentRect.height * scanProgress);
      canvas.drawLine(
        Offset(documentRect.left, scanY),
        Offset(documentRect.right, scanY),
        scanLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
