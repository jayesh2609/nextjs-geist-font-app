import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../screens/home_screen.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRequestingPermissions = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Smart DocScan',
      description: 'Transform your phone into a powerful document scanner. Scan, enhance, and organize your documents with ease.',
      icon: Icons.document_scanner,
      color: AppTheme.primaryGreen,
    ),
    OnboardingPage(
      title: 'Scan & Enhance',
      description: 'Capture documents with your camera and apply professional filters like Black & White, Magic Color, and more.',
      icon: Icons.camera_alt,
      color: AppTheme.lightGreen,
    ),
    OnboardingPage(
      title: 'OCR Text Recognition',
      description: 'Extract text from your scanned documents in multiple languages including Hindi, English, Marathi, and more.',
      icon: Icons.text_fields,
      color: AppTheme.accentOrange,
    ),
    OnboardingPage(
      title: 'Save & Share',
      description: 'Save as PDF, share via WhatsApp, Email, or Drive. Organize your documents in folders for easy access.',
      icon: Icons.share,
      color: AppTheme.primaryGreen,
    ),
    OnboardingPage(
      title: 'Permissions Required',
      description: 'To provide the best experience, we need access to your camera and storage. Your privacy is our priority.',
      icon: Icons.security,
      color: AppTheme.darkGreen,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _requestPermissionsAndComplete();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToPermissions() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _requestPermissionsAndComplete() async {
    setState(() {
      _isRequestingPermissions = true;
    });

    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    
    final permissionsGranted = await appStateProvider.requestPermissions();
    
    if (permissionsGranted) {
      await appStateProvider.completeOnboarding();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _isRequestingPermissions = false;
      });
      
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'Smart DocScan needs camera and storage permissions to function properly. Please grant these permissions in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestPermissionsAndComplete();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Continue without permissions (limited functionality)
              _completeOnboardingWithoutPermissions();
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboardingWithoutPermissions() async {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    await appStateProvider.completeOnboarding();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _skipToPermissions,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 56),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? AppTheme.primaryGreen 
                        : AppTheme.textGray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Previous',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),

                  if (_currentPage > 0) const SizedBox(width: 16),

                  // Next/Get Started button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isRequestingPermissions ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isRequestingPermissions
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _currentPage == _pages.length - 1 
                                  ? 'Get Started' 
                                  : 'Next',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Special content for permissions page
          if (page.title.contains('Permissions')) ...[
            const SizedBox(height: 32),
            _buildPermissionItem(
              icon: Icons.camera_alt,
              title: 'Camera Access',
              description: 'To capture document photos',
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              icon: Icons.storage,
              title: 'Storage Access',
              description: 'To save and organize your documents',
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              icon: Icons.notifications,
              title: 'Notifications',
              description: 'To notify you about scan completion',
              isOptional: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    bool isOptional = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (isOptional) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.textGray.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
