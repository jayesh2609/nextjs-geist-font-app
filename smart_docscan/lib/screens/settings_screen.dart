import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_state_provider.dart';
import '../providers/premium_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/premium_screen.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildAccountSection(),

          const SizedBox(height: 24),

          // App Settings Section
          _buildSectionHeader('App Settings'),
          _buildAppSettingsSection(),

          const SizedBox(height: 24),

          // OCR Settings Section
          _buildSectionHeader('OCR Settings'),
          _buildOCRSettingsSection(),

          const SizedBox(height: 24),

          // Storage & Backup Section
          _buildSectionHeader('Storage & Backup'),
          _buildStorageSection(),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (premiumProvider.userId != null) ...[
                ListTile(
                  leading: const Icon(Icons.person, color: AppTheme.primaryGreen),
                  title: const Text('Account'),
                  subtitle: Text(premiumProvider.userId!),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Show account details
                  },
                ),
                const Divider(height: 1),
              ],

              if (premiumProvider.isPremium) ...[
                ListTile(
                  leading: const Icon(Icons.workspace_premium, color: Colors.amber),
                  title: const Text('Premium Subscription'),
                  subtitle: const Text('Active • Manage subscription'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PremiumScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.workspace_premium, color: AppTheme.primaryGreen),
                  title: const Text('Upgrade to Premium'),
                  subtitle: const Text('Unlock all features'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PremiumScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
              ],

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out'),
                onTap: _handleSignOut,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppSettingsSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appStateProvider, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language, color: AppTheme.primaryGreen),
                title: const Text('OCR Language'),
                subtitle: Text(_getLanguageName(appStateProvider.selectedLanguage)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageSelector(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.brightness_6, color: AppTheme.primaryGreen),
                title: const Text('Theme'),
                subtitle: const Text('System'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Show theme selector
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications, color: AppTheme.primaryGreen),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // Toggle notifications
                  },
                  activeColor: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOCRSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.auto_fix_high, color: AppTheme.primaryGreen),
            title: const Text('Auto-enhance Images'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Toggle auto-enhance
              },
              activeColor: AppTheme.primaryGreen,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.crop, color: AppTheme.primaryGreen),
            title: const Text('Auto-crop Documents'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Toggle auto-crop
              },
              activeColor: AppTheme.primaryGreen,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.text_fields, color: AppTheme.primaryGreen),
            title: const Text('OCR Confidence Threshold'),
            subtitle: const Text('85%'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show threshold selector
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.storage, color: AppTheme.primaryGreen),
            title: const Text('Storage Usage'),
            subtitle: const Text('2.5 GB / 5 GB'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show storage details
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_upload, color: AppTheme.primaryGreen),
            title: const Text('Cloud Backup'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // Toggle cloud backup
              },
              activeColor: AppTheme.primaryGreen,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            onTap: _clearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: AppTheme.primaryGreen),
            title: const Text('About Smart DocScan'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              // Show about dialog
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.star, color: AppTheme.primaryGreen),
            title: const Text('Rate App'),
            onTap: () {
              // Open app store
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.share, color: AppTheme.primaryGreen),
            title: const Text('Share App'),
            onTap: _shareApp,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.mail, color: AppTheme.primaryGreen),
            title: const Text('Contact Support'),
            onTap: () {
              // Open support email
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppTheme.primaryGreen),
            title: const Text('Privacy Policy'),
            onTap: () {
              // Open privacy policy
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description, color: AppTheme.primaryGreen),
            title: const Text('Terms of Service'),
            onTap: () {
              // Open terms of service
            },
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    final languages = {
      'en': 'English',
      'hi': 'Hindi',
      'mr': 'Marathi',
      'ta': 'Tamil',
      'te': 'Telugu',
      'bn': 'Bengali',
      'gu': 'Gujarati',
      'kn': 'Kannada',
      'ml': 'Malayalam',
      'or': 'Odia',
      'pa': 'Punjabi',
      'ur': 'Urdu',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ar': 'Arabic',
    };
    return languages[code] ?? 'English';
  }

  void _showLanguageSelector(BuildContext context) {
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

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
      await premiumProvider.setUserId(null);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached images and temporary files. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      // Simulate cache clearing
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _shareApp() {
    Share.share(
      'Check out Smart DocScan - the best document scanner app! Download it now and get premium features.',
      subject: 'Smart DocScan - Document Scanner',
    );
  }
}
