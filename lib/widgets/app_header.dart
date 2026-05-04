import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String currentTab;
  final Function(String) onTabSelected;

  const AppHeader({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(112);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Dark IBM top bar
        Container(
          color: AppTheme.ibmHeaderBlack,
          padding: EdgeInsets.only(
            left: isMobile ? 14 : 24,
            right: isMobile ? 14 : 24,
            top:
                14 +
                MediaQuery.of(context).padding.top, // respect iOS safe area
            bottom: 14,
          ),
          child: Row(
            children: [
              const Text(
                'IBM',
                style: TextStyle(
                  color: AppTheme.ibmWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: AppTheme.ibmGray),
              const SizedBox(width: 12),
              // On mobile show shorter title; on tablet+ show full
              Expanded(
                child: Text(
                  isMobile
                      ? 'SkillsBuild Advisor'
                      : 'SkillsBuild Learning Pathway Advisor',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC6C6C6),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildUserMenu(context, isMobile),
            ],
          ),
        ),
        // Tab bar - scrolls horizontally on mobile so no tabs get cut off
        Container(
          decoration: const BoxDecoration(
            color: AppTheme.ibmWhite,
            border: Border(bottom: BorderSide(color: AppTheme.ibmDivider)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24),
            child: Row(
              children: [
                _buildTab('My Profile', 'profile'),
                _buildTab('Recommendations', 'recommendations'),
                _buildTab('Dashboard', 'dashboard'),
                _buildTab('Feedback', 'feedback'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMenu(BuildContext context, bool isMobile) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 40),
      onSelected: (value) async {
        if (value == 'logout') {
          await AuthService().signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ibmBlack,
                ),
              ),
              if (user?.email != null)
                Text(
                  user!.email!,
                  style: const TextStyle(fontSize: 12, color: AppTheme.ibmGray),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 16, color: AppTheme.ibmBlack),
              SizedBox(width: 10),
              Text('Sign out', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.ibmBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppTheme.ibmWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Text(
              displayName,
              style: const TextStyle(color: AppTheme.ibmWhite, fontSize: 13),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFC6C6C6),
              size: 18,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(String label, String tabKey) {
    final isActive = currentTab == tabKey;
    return InkWell(
      onTap: () => onTabSelected(tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.ibmBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.ibmBlue : AppTheme.ibmGray,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
