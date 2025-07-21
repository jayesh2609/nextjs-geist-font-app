import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../providers/document_provider.dart';
import '../providers/premium_provider.dart';
import '../screens/scan_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/premium_banner.dart';
import '../widgets/document_grid.dart';
import '../widgets/ad_banner_widget.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    await documentProvider.initializeDocuments();
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      // Navigate to scan screen
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ScanScreen()),
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        Provider.of<DocumentProvider>(context, listen: false).searchDocuments('');
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    Provider.of<DocumentProvider>(context, listen: false).searchDocuments(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),
            
            // Premium Banner
            Consumer<PremiumProvider>(
              builder: (context, premiumProvider, child) {
                if (!premiumProvider.isPremium) {
                  return const PremiumBanner();
                }
                return const SizedBox.shrink();
              },
            ),

            // Sign in banner (if not signed in)
            _buildSignInBanner(),

            // Tab Bar
            _buildTabBar(),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDocumentsTab(),
                  _buildToolsTab(),
                ],
              ),
            ),

            // Ad Banner (for free users)
            Consumer<PremiumProvider>(
              builder: (context, premiumProvider, child) {
                if (!premiumProvider.isPremium) {
                  return const AdBannerWidget();
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Profile/Menu button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.person, size: 20),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ),

          const SizedBox(width: 16),

          // App title or search bar
          Expanded(
            child: _isSearching
                ? TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search documents...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppTheme.textGray),
                    ),
                    onChanged: _onSearchChanged,
                  )
                : const Text(
                    'OKEN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                      letterSpacing: 2,
                    ),
                  ),
          ),

          // Search button
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildSignInBanner() {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        if (premiumProvider.userId != null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.red.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sign in to sync and keep files save.',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigate to sign in
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('Sign In', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.textDark,
        unselectedLabelColor: AppTheme.textGray,
        indicatorColor: AppTheme.primaryGreen,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_outlined, size: 20),
                const SizedBox(width: 8),
                Consumer<DocumentProvider>(
                  builder: (context, provider, child) {
                    return Text('All docs(${provider.documents.length})');
                  },
                ),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.build_outlined, size: 20),
                SizedBox(width: 8),
                Text('Tools'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        if (documentProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (documentProvider.documents.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Sort and filter options
            _buildSortFilterBar(),
            
            // Documents grid
            Expanded(
              child: DocumentGrid(
                documents: documentProvider.documents,
                onDocumentTap: (document) {
                  // Navigate to document viewer
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildToolCard(
            icon: Icons.document_scanner,
            title: 'Scan',
            subtitle: 'Scan documents',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScanScreen()),
              );
            },
          ),
          _buildToolCard(
            icon: Icons.folder,
            title: 'Doc Management',
            subtitle: 'Organize files',
            onTap: () {
              // Navigate to document management
            },
          ),
          _buildToolCard(
            icon: Icons.share,
            title: 'Doc Export',
            subtitle: 'Share documents',
            onTap: () {
              // Navigate to export options
            },
          ),
          _buildToolCard(
            icon: Icons.language,
            title: 'OCR language',
            subtitle: 'Change language',
            onTap: () {
              _showLanguageSelector();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryGreen),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state illustration
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
            'You don\'t have any documents yet',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScanScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Scan new docs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // View options
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () {
              // Toggle list view
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortOptions();
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () {
              // Toggle grid view
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Enter edit mode
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onBottomNavTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryGreen,
      unselectedItemColor: AppTheme.textGray,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.folder),
          label: 'Docs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt),
          label: '', // Empty label for center button
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.build),
          label: 'Tools',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 28,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ScanScreen()),
          );
        },
      ),
    );
  }

  void _showSortOptions() {
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
                'Sort by',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Date (Newest first)', DocumentSortType.dateDesc),
              _buildSortOption('Date (Oldest first)', DocumentSortType.dateAsc),
              _buildSortOption('Name (A-Z)', DocumentSortType.titleAsc),
              _buildSortOption('Name (Z-A)', DocumentSortType.titleDesc),
              _buildSortOption('Size (Largest first)', DocumentSortType.sizeDesc),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, DocumentSortType sortType) {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.sortType == sortType;
        
        return ListTile(
          title: Text(title),
          trailing: isSelected 
              ? Icon(Icons.check, color: AppTheme.primaryGreen)
              : null,
          onTap: () {
            provider.sortDocuments(sortType);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _showLanguageSelector() {
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
                'OCR Language',
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
                            ? Icon(Icons.check, color: AppTheme.primaryGreen)
                            : null,
                        onTap: () {
                          provider.setLanguage(lang['code']!);
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
}
