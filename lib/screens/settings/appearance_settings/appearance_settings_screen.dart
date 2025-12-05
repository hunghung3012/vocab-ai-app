import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocab_ai/providers/theme_provider.dart';


class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        elevation: 0,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Theme Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your preferred theme',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              _buildThemeOption(
                context,
                themeProvider,
                title: 'Light Mode',
                subtitle: 'Use light theme',
                icon: Icons.light_mode,
                themeMode: ThemeMode.light,
                isSelected: themeProvider.isLightMode,
              ),
              const SizedBox(height: 12),

              _buildThemeOption(
                context,
                themeProvider,
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                icon: Icons.dark_mode,
                themeMode: ThemeMode.dark,
                isSelected: themeProvider.isDarkMode,
              ),
              const SizedBox(height: 12),

              _buildThemeOption(
                context,
                themeProvider,
                title: 'System Default',
                subtitle: 'Follow system theme',
                icon: Icons.brightness_auto,
                themeMode: ThemeMode.system,
                isSelected: themeProvider.isSystemMode,
              ),

              const SizedBox(height: 24),

              _buildPreviewCard(context, themeProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
      BuildContext context,
      ThemeProvider provider, {
        required String title,
        required String subtitle,
        required IconData icon,
        required ThemeMode themeMode,
        required bool isSelected,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? Colors.purple : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.purple.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.purple : Colors.grey,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isSelected ? Colors.purple : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: isSelected
            ? const Icon(
          Icons.check_circle,
          color: Colors.purple,
          size: 28,
        )
            : const Icon(
          Icons.circle_outlined,
          color: Colors.grey,
          size: 28,
        ),
        onTap: () async {
          await provider.setThemeMode(themeMode);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Theme changed to $title'),
                backgroundColor: Colors.purple,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: Colors.amber[700],
              ),
              const SizedBox(width: 12),
              Text(
                'Current Theme',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            provider.isLightMode
                ? '☀️ Light Mode'
                : provider.isDarkMode
                ? '🌙 Dark Mode'
                : '📱 System Default',
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber[900],
            ),
          ),
        ],
      ),
    );
  }
}