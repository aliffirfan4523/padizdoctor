import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

import '../../features/settings/screens/settings_view.dart';
import 'color_theme.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    Key? key,
    required SidebarXController controller,
  })  : _controller = controller,
        super(key: key);

  final SidebarXController _controller;

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      showToggleButton: false,
      controller: _controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PaddyColors.primaryGreen, // Main sidebar container
          borderRadius: BorderRadius.circular(20),
        ),

        // ===== TEXT =====
        textStyle: TextStyle(
          color: Colors.white.withOpacity(0.75),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        selectedTextStyle: const TextStyle(
          color: PaddyColors.textDark, // Green-dominant text
          fontWeight: FontWeight.w700,
        ),

        itemTextPadding: const EdgeInsets.only(left: 24),
        selectedItemTextPadding: const EdgeInsets.only(left: 24),

        // ===== HOVER =====
        hoverColor: PaddyColors.accentGreen.withOpacity(0.2),
        hoverTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),

        // ===== NORMAL ITEM =====
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: PaddyColors.primaryGreen.withOpacity(0.2),
        ),

        // ===== SELECTED ITEM =====
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              PaddyColors.accentGreen, // Soft green highlight
              PaddyColors.secondaryGreen.withOpacity(0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: PaddyColors.secondaryGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        // ===== ICONS =====
        iconTheme: IconThemeData(
          color: Colors.white.withOpacity(0.7),
          size: 22,
        ),
        selectedIconTheme: const IconThemeData(
          color: PaddyColors.lightGreen,
          size: 22,
        ),
      ),

      // ===== EXTENDED MODE =====
      extendedTheme: SidebarXTheme(
        width: 210,
        decoration: BoxDecoration(
          color: PaddyColors.primaryGreen, // Soft paddy field background
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: TextStyle(
          fontWeight: FontWeight.w500,
        ),
        selectedTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      footerDivider: divider,
      headerBuilder: (context, extended) {
        return SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Placeholder(),
          ),
        );
      },
      items: [
        SidebarXItem(
          icon: Icons.home,
          label: 'Home',
          onTap: () {
            debugPrint('Home');
            Scaffold.of(context).closeDrawer();
          },
        ),
        SidebarXItem(
          icon: Icons.work_history,
          label: 'My Activity',
          onTap: () {
            Scaffold.of(context).closeDrawer();
          },
        ),
        const SidebarXItem(
          icon: Icons.file_copy,
          label: 'Diagnosis History',
        ),
      ],
      footerBuilder: (context, extended) {
        return ListTile(
          leading: const Icon(Icons.settings, color: Colors.white),
          title: const Text('Settings', style: TextStyle(color: Colors.white)),
          onTap: () {
            Scaffold.of(context).closeDrawer();
            Navigator.restorablePushNamed(context, SettingsView.routeName);
          },
        );
      },
    );
  }

  void _showDisabledAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Item disabled for selecting',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}

const white = Colors.white;
final actionColor = const Color(0xFF5F5FA7).withOpacity(0.6);
final divider = Divider(color: white.withOpacity(0.3), height: 1);
