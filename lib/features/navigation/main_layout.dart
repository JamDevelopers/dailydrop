import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../collections/collections_list_screen.dart';
import '../products/products_list_screen.dart';
import '../inquiries/inquiries_screen.dart';
import '../contacts/contacts_screen.dart';
import '../settings/settings_screen.dart';
import '../public_catalog/public_catalog_screen.dart';
import '../products/bulk_upload_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CollectionsListScreen(),
    ProductsListScreen(),
    InquiriesScreen(),
    ContactsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inqProvider = context.watch<InquiryProvider>();
    final newInqsCount = inqProvider.newInquiries.length;

    return Responsive(
      // Mobile View: Bottom Navigation Bar
      mobile: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex > 4 ? 4 : _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryEmerald),
              label: 'Dashboard',
            ),
            const NavigationDestination(
              icon: Icon(Icons.collections_bookmark_outlined),
              selectedIcon: Icon(Icons.collections_bookmark_rounded, color: AppTheme.primaryEmerald),
              label: 'Daily Drops',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: AppTheme.primaryEmerald),
              label: 'Designs',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: newInqsCount > 0,
                label: Text('$newInqsCount'),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              selectedIcon: Badge(
                isLabelVisible: newInqsCount > 0,
                label: Text('$newInqsCount'),
                child: const Icon(Icons.chat_bubble_rounded, color: AppTheme.whatsappGreen),
              ),
              label: 'Inquiries',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded, color: AppTheme.primaryEmerald),
              label: 'Buyers',
            ),
          ],
        ),
      ),

      // Desktop / Web View: Navigation Rail & Sidebar
      desktop: Scaffold(
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Banner
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryEmerald,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.layers_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TextileDrop',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                              Text(
                                auth.business.name,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Nav Items
                  _SidebarNavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                  _SidebarNavItem(
                    icon: Icons.collections_bookmark_rounded,
                    label: 'Daily Drops',
                    isSelected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _SidebarNavItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Design Codes & Inventory',
                    isSelected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  _SidebarNavItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Buyer Inquiries & CRM',
                    badgeCount: newInqsCount,
                    isSelected: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                  _SidebarNavItem(
                    icon: Icons.people_alt_rounded,
                    label: 'Buyers Directory',
                    isSelected: _currentIndex == 4,
                    onTap: () => setState(() => _currentIndex = 4),
                  ),
                  _SidebarNavItem(
                    icon: Icons.settings_rounded,
                    label: 'Store Settings',
                    isSelected: _currentIndex == 5,
                    onTap: () => setState(() => _currentIndex = 5),
                  ),

                  const Spacer(),
                  const Divider(height: 1),

                  // Quick Action Buttons in Sidebar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
                          label: const Text('Bulk Drop Upload'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BulkUploadScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Public Catalog View'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PublicCatalogScreen(
                                  businessSlug: auth.business.slug,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: _screens[_currentIndex],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primaryEmerald : AppTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.whatsappGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
