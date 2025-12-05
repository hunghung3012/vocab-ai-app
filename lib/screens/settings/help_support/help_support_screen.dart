import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find answers to common questions',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // FAQ Section
          _buildSectionTitle('Frequently Asked Questions'),
          const SizedBox(height: 12),
          _buildFAQItem(
            context,
            question: 'How do I create a new deck?',
            answer:
            'Go to the Decks tab and tap the "+" button. Enter your deck name and start adding vocabulary cards.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            context,
            question: 'How do I import Anki decks?',
            answer:
            'Tap the import icon on the Decks screen, select your .apkg file, and the deck will be imported automatically.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            context,
            question: 'How does the AI Chat feature work?',
            answer:
            'The AI Chat helps you practice vocabulary by having conversations. Ask questions, get definitions, or practice using words in context.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            context,
            question: 'Can I customize notification times?',
            answer:
            'Yes! Go to Settings > Notifications to enable daily reminders and customize when you want to be reminded to study.',
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            context,
            question: 'How do I track my progress?',
            answer:
            'Visit the Dashboard to see your study statistics, streaks, and progress over time.',
          ),

          const SizedBox(height: 32),

          // Contact Section
          _buildSectionTitle('Contact Us'),
          const SizedBox(height: 12),
          _buildContactCard(
            context,
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@vocabai.com',
            color: Colors.blue,
            onTap: () => _launchEmail('support@vocabai.com'),
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            context,
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            subtitle: 'Help us improve',
            color: Colors.orange,
            onTap: () => _showReportBugDialog(context),
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            context,
            icon: Icons.star_outline,
            title: 'Rate Us',
            subtitle: 'Leave a review on the App Store',
            color: Colors.amber,
            onTap: () => _showRateAppDialog(context),
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            context,
            icon: Icons.web_outlined,
            title: 'Visit Website',
            subtitle: 'www.vocabai.com',
            color: Colors.purple,
            onTap: () => _launchURL('https://www.vocabai.com'),
          ),

          const SizedBox(height: 32),

          // Resources Section
          _buildSectionTitle('Resources'),
          const SizedBox(height: 12),
          _buildResourceCard(
            context,
            icon: Icons.menu_book,
            title: 'User Guide',
            subtitle: 'Learn how to use VocabAI',
            onTap: () => _showUserGuideDialog(context),
          ),
          const SizedBox(height: 12),
          _buildResourceCard(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () => _showPrivacyPolicyDialog(context),
          ),
          const SizedBox(height: 12),
          _buildResourceCard(
            context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Our terms and conditions',
            onTap: () => _showTermsDialog(context),
          ),

          const SizedBox(height: 32),

          // App Info
          _buildAppInfo(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildFAQItem(
      BuildContext context, {
        required String question,
        required String answer,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.help_outline,
              color: Colors.purple,
              size: 20,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildResourceCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.grey[700], size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 40,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 12),
          const Text(
            'VocabAI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2024 VocabAI. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'VocabAI Support Request',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showReportBugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please describe the issue you\'re experiencing:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the bug...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you! Bug report submitted.'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showRateAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Rate VocabAI'),
          ],
        ),
        content: const Text(
          'If you enjoy using VocabAI, would you mind taking a moment to rate us? It won\'t take more than a minute. Thanks for your support!',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening App Store...'),
                  backgroundColor: Colors.purple,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showUserGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Guide'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuideItem('1. Create Decks', 'Organize your vocabulary into themed decks'),
              const SizedBox(height: 12),
              _buildGuideItem('2. Add Cards', 'Add vocabulary words with definitions and examples'),
              const SizedBox(height: 12),
              _buildGuideItem('3. Study Mode', 'Review your cards with spaced repetition'),
              const SizedBox(height: 12),
              _buildGuideItem('4. Quiz Yourself', 'Test your knowledge with interactive quizzes'),
              const SizedBox(height: 12),
              _buildGuideItem('5. AI Chat', 'Practice with AI-powered conversations'),
              const SizedBox(height: 12),
              _buildGuideItem('6. Track Progress', 'Monitor your learning journey on the dashboard'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got It!'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            'At VocabAI, we take your privacy seriously. We collect only the data necessary to provide our services.\n\n'
                '• We do not sell your personal information\n'
                '• Your study data is stored securely\n'
                '• You can delete your account at any time\n\n'
                'For full details, visit our website.',
            style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[700]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchURL('https://www.vocabai.com/privacy');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Read Full Policy'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Text(
            'By using VocabAI, you agree to:\n\n'
                '• Use the app for personal learning purposes\n'
                '• Not share copyrighted content without permission\n'
                '• Follow community guidelines when using AI features\n'
                '• Accept that we may update these terms as needed\n\n'
                'For complete terms, visit our website.',
            style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[700]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchURL('https://www.vocabai.com/terms');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Read Full Terms'),
          ),
        ],
      ),
    );
  }
}