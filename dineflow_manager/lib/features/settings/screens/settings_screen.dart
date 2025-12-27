import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';
import '../../profile/screens/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // The AuthWrapper in main.dart listens to authStateChanges and will automatically
      // switch to LoginScreen. However, if we are deep in the navigation stack,
      // we might want to pop everything to ensure a clean state.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark
        ? Colors.white.withOpacity(0.6)
        : Colors.grey[600];
    final cardColor = isDark ? AppTheme.cardColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.withOpacity(0.1);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.outerPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Settings",
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: _handleLogout,
                  tooltip: "Logout",
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.outerPadding,
              ),
              children: [
                // 1. Account Section
                _buildSectionHeader("Account", subTextColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        icon: Icons.person_outline,
                        title: "Personal Info",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        textColor: textColor,
                        iconColor: subTextColor,
                      ),
                      _buildDivider(borderColor),
                      _buildListTile(
                        icon: Icons.security,
                        title: "Security & Privacy",
                        onTap: () => _navigateToPlaceholder(
                          context,
                          "Security & Privacy",
                        ),
                        textColor: textColor,
                        iconColor: subTextColor,
                      ),
                      _buildDivider(borderColor),
                      _buildListTile(
                        icon: Icons.payment,
                        title: "Payment Methods",
                        onTap: () =>
                            _navigateToPlaceholder(context, "Payment Methods"),
                        textColor: textColor,
                        iconColor: subTextColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Preferences Section
                _buildSectionHeader("Preferences", subTextColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        icon: Icons.dark_mode_outlined,
                        title: "Dark Mode",
                        value: AppTheme.themeMode.value == ThemeMode.dark,
                        onChanged: (value) {
                          AppTheme.themeMode.value = value
                              ? ThemeMode.dark
                              : ThemeMode.light;
                        },
                        textColor: textColor,
                        iconColor: subTextColor,
                      ),
                      _buildDivider(borderColor),
                      _buildSwitchTile(
                        icon: Icons.notifications_none,
                        title: "Notifications",
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                        },
                        textColor: textColor,
                        iconColor: subTextColor,
                      ),
                      _buildDivider(borderColor),
                      _buildListTile(
                        icon: Icons.language,
                        title: "Language",
                        trailing: Text(
                          "English",
                          style: GoogleFonts.poppins(
                            color: subTextColor,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () =>
                            _navigateToPlaceholder(context, "Language"),
                        textColor: textColor,
                        iconColor: subTextColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Actions Section
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: ListTile(
                    onTap: _handleLogout,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      "Log Out",
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color textColor,
    required Color? iconColor,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          trailing ?? Icon(Icons.arrow_forward_ios, color: iconColor, size: 16),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accentGreen,
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(
      height: 1,
      thickness: 1,
      color: color,
      indent: 56, // Align with text start
    );
  }

  void _navigateToPlaceholder(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: Center(
            child: Text(
              "$title Screen",
              style: GoogleFonts.poppins(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
