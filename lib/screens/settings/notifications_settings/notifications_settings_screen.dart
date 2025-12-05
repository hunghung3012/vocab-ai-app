import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocab_ai/providers/notification_provider.dart';


class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Notification Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage your notification preferences',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              _buildNotificationCard(
                context,
                notificationProvider,
              ),

              const SizedBox(height: 16),

              _buildInfoCard(context, notificationProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context,
      NotificationProvider provider,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        secondary: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: provider.isEnabled
                ? Colors.purple.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            provider.isEnabled
                ? Icons.notifications_active
                : Icons.notifications_off,
            color: provider.isEnabled ? Colors.purple : Colors.grey,
          ),
        ),
        title: const Text(
          'Enable Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          provider.isEnabled
              ? 'Notifications every 20 seconds (Test Mode)'
              : 'Turn on to receive vocabulary reminders',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        value: provider.isEnabled,
        onChanged: (value) async {
          await provider.toggleNotifications(value);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? '🔔 Notifications enabled! Test notification every 20s'
                      : '🔕 Notifications disabled',
                ),
                backgroundColor: value ? Colors.green : Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        activeColor: Colors.purple,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, NotificationProvider provider) {
    if (!provider.isEnabled) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Test Mode Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'ll receive a notification every 20 seconds for testing. In production, this will be a daily reminder at 8 AM.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}