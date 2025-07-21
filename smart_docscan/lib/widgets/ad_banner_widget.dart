import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers/premium_provider.dart';
import '../utils/app_theme.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    
    // Don't load ads for premium users
    if (premiumProvider.isPremium) return;

    _bannerAd = BannerAd(
      adUnitId: PremiumProvider.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
          });
          
          // Show fallback ad after delay
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              _loadBannerAd();
            }
          });
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('Banner ad closed');
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        // Don't show ads for premium users
        if (premiumProvider.isPremium) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: AppTheme.textGray.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: _isAdLoaded && _bannerAd != null
              ? SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                )
              : _buildFallbackAd(),
        );
      },
    );
  }

  Widget _buildFallbackAd() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Ad icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.workspace_premium,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Ad content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'Remove ads and unlock all features',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),

          // Upgrade button
          TextButton(
            onPressed: () {
              // Navigate to premium screen
              Navigator.of(context).pushNamed('/premium');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Close button
          IconButton(
            onPressed: () {
              // Hide ad temporarily
              setState(() {
                _isAdLoaded = false;
              });
              
              // Show again after 30 seconds
              Future.delayed(const Duration(seconds: 30), () {
                if (mounted) {
                  _loadBannerAd();
                }
              });
            },
            icon: Icon(
              Icons.close,
              size: 16,
              color: AppTheme.textGray,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ],
      ),
    );
  }
}

// Interstitial Ad Helper Widget
class InterstitialAdHelper extends StatelessWidget {
  final Widget child;
  final String? adTrigger;

  const InterstitialAdHelper({
    super.key,
    required this.child,
    this.adTrigger,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        return GestureDetector(
          onTap: () async {
            // Show interstitial ad for free users on certain actions
            if (!premiumProvider.isPremium && adTrigger != null) {
              await premiumProvider.showInterstitialAd();
            }
          },
          child: this.child,
        );
      },
    );
  }
}

// Native Ad Widget (for more integrated ads)
class NativeAdWidget extends StatefulWidget {
  final String adUnitId;
  final double height;

  const NativeAdWidget({
    super.key,
    required this.adUnitId,
    this.height = 120,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId,
      factoryId: 'listTile', // This should match your native ad factory
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native ad failed to load: $error');
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
          });
        },
      ),
    );

    _nativeAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        if (premiumProvider.isPremium) {
          return const SizedBox.shrink();
        }

        return Container(
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textGray.withOpacity(0.2),
            ),
          ),
          child: _isAdLoaded && _nativeAd != null
              ? AdWidget(ad: _nativeAd!)
              : _buildNativeFallback(),
        );
      },
    );
  }

  Widget _buildNativeFallback() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // App icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.document_scanner,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Smart DocScan Premium',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlock unlimited scans, remove ads, and get cloud backup',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/premium');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Ad-free premium indicator
class PremiumIndicator extends StatelessWidget {
  const PremiumIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        if (!premiumProvider.isPremium) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.amber, Colors.orange],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              const Text(
                'Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Ad loading placeholder
class AdLoadingPlaceholder extends StatelessWidget {
  final double height;

  const AdLoadingPlaceholder({
    super.key,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textGray),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading ad...',
              style: TextStyle(
                color: AppTheme.textGray,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
