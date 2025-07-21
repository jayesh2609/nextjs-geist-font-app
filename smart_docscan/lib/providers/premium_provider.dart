import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool _isLoading = false;
  String? _userId;
  DateTime? _premiumExpiryDate;
  
  // Ad related
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  
  // In-app purchase
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Product IDs
  static const String premiumYearlyId = 'premium_yearly';
  static const String premiumMonthlyId = 'premium_monthly';
  
  // Ad Unit IDs (Test IDs - Replace with real ones)
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  // Getters
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  DateTime? get premiumExpiryDate => _premiumExpiryDate;
  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get shouldShowAds => !_isPremium;

  PremiumProvider() {
    _initializePremiumStatus();
    _initializeAds();
    _initializeInAppPurchase();
  }

  // Initialize premium status
  Future<void> _initializePremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('is_premium') ?? false;
      _userId = prefs.getString('user_id');
      
      final expiryTimestamp = prefs.getInt('premium_expiry');
      if (expiryTimestamp != null) {
        _premiumExpiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
        
        // Check if premium has expired
        if (_premiumExpiryDate!.isBefore(DateTime.now())) {
          await _setPremiumStatus(false);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing premium status: $e');
    }
  }

  // Initialize ads
  Future<void> _initializeAds() async {
    if (_isPremium) return;
    
    await _loadBannerAd();
    await _loadInterstitialAd();
  }

  // Load banner ad
  Future<void> _loadBannerAd() async {
    if (_isPremium) return;
    
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          _isBannerAdLoaded = false;
          notifyListeners();
        },
      ),
    );
    
    await _bannerAd!.load();
  }

  // Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    if (_isPremium) return;
    
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialAdLoaded = false;
          notifyListeners();
        },
      ),
    );
  }

  // Show interstitial ad
  Future<void> showInterstitialAd() async {
    if (_isPremium || !_isInterstitialAdLoaded || _interstitialAd == null) {
      return;
    }
    
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        _loadInterstitialAd(); // Load next ad
      },
    );
    
    await _interstitialAd!.show();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
  }

  // Initialize in-app purchase
  void _initializeInAppPurchase() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );
  }

  // Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchaseDetails.error}');
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == premiumYearlyId) {
      await _setPremiumStatus(true, duration: const Duration(days: 365));
    } else if (purchaseDetails.productID == premiumMonthlyId) {
      await _setPremiumStatus(true, duration: const Duration(days: 30));
    }
  }

  // Purchase premium
  Future<bool> purchasePremium(String productId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        throw Exception('In-app purchases not available');
      }
      
      const Set<String> productIds = {premiumYearlyId, premiumMonthlyId};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        throw Exception('Product not found');
      }
      
      final ProductDetails productDetails = response.productDetails
          .firstWhere((product) => product.id == productId);
      
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      return true;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set premium status
  Future<void> _setPremiumStatus(bool isPremium, {Duration? duration}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', isPremium);
      
      if (isPremium && duration != null) {
        final expiryDate = DateTime.now().add(duration);
        await prefs.setInt('premium_expiry', expiryDate.millisecondsSinceEpoch);
        _premiumExpiryDate = expiryDate;
      }
      
      _isPremium = isPremium;
      
      // Dispose ads if premium
      if (isPremium) {
        _bannerAd?.dispose();
        _interstitialAd?.dispose();
        _bannerAd = null;
        _interstitialAd = null;
        _isBannerAdLoaded = false;
        _isInterstitialAdLoaded = false;
      } else {
        // Reload ads if not premium
        await _initializeAds();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting premium status: $e');
    }
  }

  // Set user ID (required for premium purchase)
  Future<void> setUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      _userId = userId;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  // Check if user needs to login for premium
  bool get needsLoginForPremium => _userId == null;

  // Get premium features list
  List<String> getPremiumFeatures() {
    return [
      'No Advertisements',
      'Unlimited Document Scans',
      'Advanced OCR Languages',
      'Cloud Backup & Sync',
      'Batch Processing',
      'Advanced Filters & Effects',
      'Priority Customer Support',
      'Export to Multiple Formats',
      'Document Password Protection',
      'Watermark Removal',
    ];
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _subscription.cancel();
    super.dispose();
  }
}
