# Smart DocScan - Mobile OCR Document Scanner

A comprehensive mobile document scanner app built with Flutter that allows users to scan, enhance, and organize documents with OCR text extraction capabilities. Features both free and premium versions with ads and in-app purchases.

## 🚀 Features

### Core Features
- **📸 Document Scanning**: High-quality camera scanning with auto-edge detection
- **✂️ Image Cropping**: Manual and automatic document cropping with perspective correction
- **🎨 Image Enhancement**: Multiple filters including B/W, Magic Color, Grayscale, etc.
- **🔍 OCR Text Recognition**: Extract text from documents in 15+ languages
- **📄 PDF Generation**: Create multi-page PDFs with extracted text
- **📂 Document Management**: Organize documents in folders with search functionality
- **☁️ Cloud Backup**: Secure cloud storage for premium users
- **🔒 Security**: Document encryption and password protection

### Free Version Features
- Basic document scanning
- Limited OCR (5 scans per day)
- Basic filters
- Local storage only
- Ads display

### Premium Version Features
- **No advertisements**
- **Unlimited document scans**
- **Advanced OCR languages**
- **Cloud backup & sync**
- **Batch processing**
- **Advanced filters & effects**
- **Priority customer support**
- **Export to multiple formats**
- **Document password protection**
- **Watermark removal**

## 🛠️ Tech Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language
- **Provider**: State management
- **Material Design 3**: Modern UI components

### Backend Services
- **Google ML Kit**: OCR text recognition
- **Tesseract OCR**: Advanced text extraction
- **SQLite**: Local database
- **SharedPreferences**: Local storage
- **Firebase**: Optional cloud services

### Dependencies
- `camera`: Camera functionality
- `image_picker`: Gallery access
- `google_mlkit_text_recognition`: OCR engine
- `pdf`: PDF generation
- `sqflite`: Database operations
- `shared_preferences`: Local storage
- `google_mobile_ads`: Ad integration
- `in_app_purchase`: Premium purchases
- `permission_handler`: Permission management

## 📱 Screens

1. **Splash Screen**: App initialization and branding
2. **Onboarding**: First-time user guide with permissions
3. **Home Screen**: Document gallery with search and filters
4. **Scan Screen**: Camera interface with document detection
5. **Crop & Filter**: Image editing with filters and cropping
6. **OCR Preview**: Text extraction and editing
7. **Premium Screen**: Subscription plans and features
8. **Settings**: App configuration and preferences
9. **Auth Screen**: User authentication for premium features

## 🎯 Premium Features

### Subscription Plans
- **Monthly**: ₹99/month
- **Yearly**: ₹999/year (17% savings)
- **7-day free trial** for both plans

### Payment Integration
- **Google Play Billing** for Android
- **App Store In-App Purchase** for iOS
- **Secure payment processing**
- **Subscription management**

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- Android Studio / Xcode
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/smart-docscan.git
cd smart-docscan
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure platform-specific settings**

#### Android Setup
- Add your Google AdMob App ID in `android/app/src/main/AndroidManifest.xml`
- Configure signing for release builds

#### iOS Setup
- Add your AdMob App ID in `ios/Runner/Info.plist`
- Configure in-app purchase capabilities

4. **Run the app**
```bash
flutter run
```

### Configuration

#### AdMob Setup
1. Create an AdMob account at [admob.google.com](https://admob.google.com)
2. Add your app and get the App ID
3. Update the ad unit IDs in `lib/providers/premium_provider.dart`

#### In-App Purchase Setup
1. Create products in Google Play Console and App Store Connect
2. Update product IDs in `lib/providers/premium_provider.dart`
3. Configure subscription plans

#### OCR Language Support
The app supports 15+ languages including:
- English
- Hindi
- Marathi
- Tamil
- Telugu
- Bengali
- Gujarati
- Kannada
- Malayalam
- Odia
- Punjabi
- Urdu
- Chinese
- Japanese
- Korean
- Spanish
- French
- German
- Italian
- Portuguese
- Russian
- Arabic

## 🏗️ Project Structure

```
smart_docscan/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   └── document_model.dart
│   ├── providers/                # State management
│   │   ├── app_state_provider.dart
│   │   ├── document_provider.dart
│   │   └── premium_provider.dart
│   ├── screens/                  # UI screens
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── home_screen.dart
│   │   ├── scan_screen.dart
│   │   ├── crop_filter_screen.dart
│   │   ├── ocr_preview_screen.dart
│   │   ├── premium_screen.dart
│   │   ├── auth_screen.dart
│   │   └── settings_screen.dart
│   ├── services/                 # Business logic
│   │   ├── database_service.dart
│   │   ├── ocr_service.dart
│   │   ├── image_processing_service.dart
│   │   └── pdf_service.dart
│   ├── utils/                    # Utilities
│   │   └── app_theme.dart
│   └── widgets/                  # Reusable components
│       ├── premium_banner.dart
│       ├── document_grid.dart
│       └── ad_banner_widget.dart
├── pubspec.yaml
└── README.md
```

## 🎨 Design System

### Color Palette
- **Primary Green**: `#2E7D32`
- **Light Green**: `#4CAF50`
- **Dark Green**: `#1B5E20`
- **Accent Orange**: `#FF6B35`
- **Background Gray**: `#F5F5F5`
- **Text Dark**: `#212121`
- **Text Gray**: `#757575`

### Typography
- **Roboto** font family
- Material Design 3 guidelines
- Responsive text scaling

## 📊 Analytics & Tracking

### User Events
- Document scans
- OCR usage
- Premium conversions
- Feature usage
- Error tracking

### Performance Metrics
- Scan quality scores
- OCR accuracy rates
- App performance
- User retention

## 🔒 Privacy & Security

- **Local-first approach**: Documents stored locally by default
- **Encryption**: Document encryption for sensitive files
- **Privacy-focused**: No data collection without consent
- **GDPR compliant**: User data protection
- **Secure cloud**: Encrypted cloud storage for premium users

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

## 📦 Build & Release

### Android Release
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS Release
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support, email support@smartdocscan.com or join our Discord community.

## 📱 Download

- **Google Play Store**: [Download for Android](https://play.google.com/store/apps/details?id=com.smartdocscan.app)
- **Apple App Store**: [Download for iOS](https://apps.apple.com/app/smart-docscan/id123456789)

## 🔄 Changelog

### Version 1.0.0
- Initial release
- Basic document scanning
- OCR text extraction
- PDF generation
- Premium subscription
- Multi-language support

---

**Made with ❤️ by the Smart DocScan Team**
