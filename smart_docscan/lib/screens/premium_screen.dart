import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/premium_provider.dart';
import '../screens/auth_screen.dart';
import '../utils/app_theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroAnimationController;
  late AnimationController _featuresAnimationController;
  late Animation<double> _heroAnimation;
  late Animation<double> _featuresAnimation;
  
  bool _isYearlySelected = true;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _featuresAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _featuresAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _heroAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.elasticOut,
    ));

    _featuresAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _featuresAnimationController,
      curve: Curves.easeInOut,
    ));

    _heroAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _featuresAnimationController.forward();
    });
  }

  Future<void> _purchasePremium() async {
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    
    // Check if user needs to login first
    if (premiumProvider.needsLoginForPremium) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AuthScreen(isSignUpRequired: true),
        ),
      );
      
      if (result != true) {
        return; // User cancelled login
      }
    }

    // Proceed with purchase
    final productId = _isYearlySelected 
        ? PremiumProvider.premiumYearlyId 
        : PremiumProvider.premiumMonthlyId;
    
    final success = await premiumProvider.purchasePremium(productId);
    
    if (success && mounted) {
      // Show success dialog
      _showSuccessDialog();
    } else if (mounted) {
      // Show error dialog
      _showErrorDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text('Welcome to Premium!'),
          ],
        ),
        content: const Text(
          'Congratulations! You now have access to all premium features. Enjoy unlimited scans, no ads, and much more!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close premium screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Get Started', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Failed'),
        content: const Text(
          'We couldn\'t complete your purchase. Please try again or contact support if the problem persists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6B35),
              Color(0xFFFF8E53),
              Color(0xFFFFB366),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Hero section
                      _buildHeroSection(),
                      
                      // Features list
                      Expanded(
                        child: _buildFeaturesList(),
                      ),
                      
                      // Pricing and purchase
                      _buildPricingSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Spacer(),
          const Text(
            'Premium Features',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Consumer<PremiumProvider>(
            builder: (context, provider, child) {
              return TextButton(
                onPressed: provider.restorePurchases,
                child: const Text(
                  'Restore',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _heroAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _heroAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Premium crown icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 40,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'Unlock Premium',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Get unlimited access to all features',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesList() {
    return AnimatedBuilder(
      animation: _featuresAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _featuresAnimation.value,
          child: Consumer<PremiumProvider>(
            builder: (context, provider, child) {
              final features = provider.getPremiumFeatures();
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 200 + (index * 100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(50 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: _buildFeatureItem(features[index], index),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(String feature, int index) {
    final icons = [
      Icons.block, // No Advertisements
      Icons.all_inclusive, // Unlimited Document Scans
      Icons.language, // Advanced OCR Languages
      Icons.cloud_upload, // Cloud Backup & Sync
      Icons.layers, // Batch Processing
      Icons.auto_fix_high, // Advanced Filters & Effects
      Icons.support_agent, // Priority Customer Support
      Icons.file_download, // Export to Multiple Formats
      Icons.lock, // Document Password Protection
      Icons.branding_watermark_outlined, // Watermark Removal
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              icons[index % icons.length],
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pricing toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isYearlySelected = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isYearlySelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: !_isYearlySelected ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Text(
                        'Monthly\n₹99/month',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: !_isYearlySelected ? FontWeight.bold : FontWeight.normal,
                          color: !_isYearlySelected ? AppTheme.textDark : AppTheme.textGray,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isYearlySelected = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isYearlySelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _isYearlySelected ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Text(
                            'Yearly\n₹999/year',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _isYearlySelected ? FontWeight.bold : FontWeight.normal,
                              color: _isYearlySelected ? AppTheme.textDark : AppTheme.textGray,
                            ),
                          ),
                          if (_isYearlySelected)
                            Positioned(
                              top: -8,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'SAVE 17%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Purchase button
          Consumer<PremiumProvider>(
            builder: (context, provider, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _purchasePremium,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isYearlySelected 
                              ? 'Start Free Trial - ₹999/year'
                              : 'Start Free Trial - ₹99/month',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Terms and conditions
          Text(
            'Free trial for 7 days, then ${_isYearlySelected ? '₹999/year' : '₹99/month'}. Cancel anytime.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Legal links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  // Show terms of service
                },
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGray,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                ' • ',
                style: TextStyle(color: AppTheme.textGray),
              ),
              TextButton(
                onPressed: () {
                  // Show privacy policy
                },
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGray,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
