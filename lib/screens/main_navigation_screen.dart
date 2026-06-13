import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'profile_view.dart';
import 'search_view.dart';
import 'social_feed_screen.dart';
import 'jobs_view.dart';
import '../widgets/scale_on_tap.dart';
import '../widgets/user_avatar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _views = const [
    SocialFeedScreen(),
    JobsView(),
    SearchView(),
    ProfileView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      extendBody:
          true, // Let the content scroll and show through behind the bar
      body: IndexedStack(index: _selectedIndex, children: _views),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16.0,
            0.0,
            16.0,
            8.0,
          ), // Floating margins matching the post cards horizontally
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Tab 1: Social (Community Feed)
                    _buildNavItem(
                      index: 0,
                      icon: Icons.feed_outlined,
                      activeIcon: Icons.feed_rounded,
                      isDark: isDark,
                    ),

                    // Tab 2: Jobs (Freelance vitrina)
                    _buildNavItem(
                      index: 1,
                      icon: Icons.work_outline_rounded,
                      activeIcon: Icons.work_rounded,
                      isDark: isDark,
                    ),

                    // Tab 3: Search
                    _buildNavItem(
                      index: 2,
                      icon: Icons.search_rounded,
                      activeIcon: Icons.search_rounded,
                      isDark: isDark,
                    ),

                    // Tab 4: Profile
                    _buildProfileNavItem(index: 3, user: user, isDark: isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required bool isDark,
  }) {
    final isActive = _selectedIndex == index;
    return ScaleOnTap(
      onTap: () => _onItemTapped(index),
      scaleFactor: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive
              ? AppTheme.primary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.5)),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildProfileNavItem({
    required int index,
    required UserModel? user,
    required bool isDark,
  }) {
    final isActive = _selectedIndex == index;

    return ScaleOnTap(
      onTap: () => _onItemTapped(index),
      scaleFactor: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: user != null
            ? UserAvatar.fromUsername(
                username: user.username,
                avatarUrl: user.avatarUrl,
                size: 32,
                showBorder: isActive,
                borderWidth: 1.0,
              )
            : _buildFallbackAvatar('', isDark),
      ),
    );
  }

  Widget _buildFallbackAvatar(String initial, bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
