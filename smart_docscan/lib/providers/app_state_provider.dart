import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class AppStateProvider extends ChangeNotifier {
  bool _isFirstLaunch = true;
  bool _hasPermissions = false;
  bool _isLoading = false;
  String _selectedLanguage = 'en';
  
  // Getters
  bool get isFirstLaunch => _isFirstLaunch;
  bool get hasPermissions => _hasPermissions;
  bool get isLoading => _isLoading;
  String get selectedLanguage => _selectedLanguage;

  // Initialize app
  Future<void> initializeApp() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if first launch
      _isFirstLaunch = prefs.getBool('first_launch') ?? true;
      
      // Get selected language
      _selectedLanguage = prefs.getString('selected_language') ?? 'en';
      
      // Check permissions
      await _checkPermissions();
      
    } catch (e) {
      debugPrint('Error initializing app: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check and request permissions
  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;
    final photosStatus = await Permission.photos.status;
    
    _hasPermissions = cameraStatus.isGranted && 
                     (storageStatus.isGranted || photosStatus.isGranted);
    
    notifyListeners();
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      
      // Request storage/photos permission
      PermissionStatus storageStatus;
      if (await Permission.storage.isRestricted) {
        storageStatus = await Permission.photos.request();
      } else {
        storageStatus = await Permission.storage.request();
      }
      
      // Request notification permission (optional)
      await Permission.notification.request();
      
      _hasPermissions = cameraStatus.isGranted && storageStatus.isGranted;
      
      return _hasPermissions;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_launch', false);
      _isFirstLaunch = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  // Set language
  Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', languageCode);
      _selectedLanguage = languageCode;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  // Get supported languages for OCR
  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'Hindi'},
      {'code': 'mr', 'name': 'Marathi'},
      {'code': 'ta', 'name': 'Tamil'},
      {'code': 'te', 'name': 'Telugu'},
      {'code': 'bn', 'name': 'Bengali'},
      {'code': 'gu', 'name': 'Gujarati'},
      {'code': 'kn', 'name': 'Kannada'},
      {'code': 'ml', 'name': 'Malayalam'},
      {'code': 'or', 'name': 'Odia'},
      {'code': 'pa', 'name': 'Punjabi'},
      {'code': 'ur', 'name': 'Urdu'},
    ];
  }

  // Reset app state (for testing)
  Future<void> resetAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _isFirstLaunch = true;
      _hasPermissions = false;
      _selectedLanguage = 'en';
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting app state: $e');
    }
  }
}
