import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppCenterPage extends StatefulWidget {
  const AppCenterPage({super.key});

  @override
  State<AppCenterPage> createState() => _AppCenterPageState();
}

class _AppCenterPageState extends State<AppCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _expandedCategory;

  final List<HelpCategory> _helpCategories = [
    HelpCategory(
      title: 'Getting Started',
      icon: Icons.rocket_launch_outlined,
      color: Colors.blue,
      topics: [
        HelpTopic(
          question: 'How do I create an account?',
          answer: '''1. Open the Skynaire app
2. Tap "Sign Up" on the welcome screen
3. Enter your email address
4. Choose a strong password
5. Complete your profile with username and display name
6. Tap "Create Account"''',
        ),
        HelpTopic(
          question: 'How do I set up my profile?',
          answer: '''1. Go to your Profile tab
2. Tap the "Edit Profile" button
3. Add a profile picture
4. Write a bio (max 150 characters)
5. Add your website or social links
6. Save your changes

Your profile is your identity on Skynaire. Make it unique!''',
        ),
        HelpTopic(
          question: 'What are the main features?',
          answer: '''Skynaire offers:

📱 Media Posts - Share photos and moments
🔍 Explore - Discover new posts and people
👥 Following - Connect with interesting people
💬 Comments - Engage in conversations
🔖 Save Posts - Bookmark content for later
📊 Analytics - Track your post performance''',
        ),
      ],
    ),
    HelpCategory(
      title: 'Creating Content',
      icon: Icons.edit_outlined,
      color: Colors.purple,
      topics: [
        HelpTopic(
          question: 'How do I create a post?',
          answer: '''1. Tap the + button in the navigation bar
2. Choose "Media Post"
3. Choose or take a photo
4. Edit your image with filters and adjustments
5. Add a catchy title
6. Write a description
7. Select a category
8. Tap "Post"

Media posts are limited to 800 characters.''',
        ),
        
        HelpTopic(
          question: 'How do I edit my images?',
          answer: '''When creating a post, our built-in editor offers:

🎨 Filters - Vivid, Cool, Warm, B&W, Vintage
☀️ Brightness - Adjust light levels
🎭 Contrast - Enhance depth
🌈 Saturation - Control color intensity
🔄 Rotation - Rotate up to 180°

Tip: Try combining filters with manual adjustments for unique looks!''',
        ),
      ],
    ),
    HelpCategory(
      title: 'Exploring & Discovery',
      icon: Icons.explore_outlined,
      color: Colors.orange,
      topics: [
        HelpTopic(
          question: 'How does the Explore page work?',
          answer: '''The Explore page helps you discover:

🖼️ Posts Tab - Browse media posts from the community
👥 People Tab - Find new users to follow

Use the search bar to find specific:
• Posts by category or keywords
• People by name or username (e.g., @username)

Tap any post to view details or any profile to connect!''',
        ),
        HelpTopic(
          question: 'How do I search for content?',
          answer: '''Search Section:
• Use the search bar at the top
• Search posts by keywords or categories
• Search people by name or username (try @mentions)
• Results update in real-time as you type''',
        ),
        HelpTopic(
          question: 'How do I follow someone?',
          answer: '''1. Visit their profile
2. Tap the "Follow" button
3. Their posts will now appear in your feed

You can unfollow anytime by tapping "Following" on their profile.''',
        ),
      ],
    ),
    HelpCategory(
      title: 'Engagement & Interaction',
      icon: Icons.people_outline,
      color: Colors.green,
      topics: [
        HelpTopic(
          question: 'How do I interact with posts?',
          answer: '''You can:

❤️ Like - Double tap the post or tap the heart icon
💬 Comment - Tap the comment icon to share thoughts
🔖 Save - Bookmark posts for later (tap the bookmark icon)
📤 Share - Share posts with others

All interactions are visible to the post author.''',
        ),
        HelpTopic(
          question: 'Where are my saved posts?',
          answer: '''1. Go to your Profile
2. Swipe to the "Saved" tab
3. View all bookmarked posts

Saved posts are private and only visible to you.''',
        ),
        HelpTopic(
          question: 'How do notifications work?',
          answer: '''You'll receive notifications for:

• New followers
• Likes on your posts
• Comments on your posts
• Mentions using your @username

Manage notification settings in Settings → Notifications.''',
        ),
      ],
    ),
    HelpCategory(
      title: 'Privacy & Security',
      icon: Icons.security_outlined,
      color: Colors.red,
      topics: [
        HelpTopic(
          question: 'What is App Lock?',
          answer:
              '''App Lock adds an extra layer of security with a 4-digit PIN.

1. Go to Settings → Security Center
2. Toggle "App Lock" and set your PIN
3. Use "Lock Timeout" to choose when the app should ask for the PIN:
   • Immediate (locks as soon as you exit)
   • After 1, 5, or 15 minutes

This prevents unauthorized access if someone else uses your phone.''',
        ),
        HelpTopic(
          question: 'How do I block someone?',
          answer: '''1. Go to their profile
2. Tap the menu (⋯) button
3. Select "Block User"

Blocked users:
• Cannot see your posts
• Cannot follow you
• Cannot message or tag you''',
        ),
        HelpTopic(
          question: 'How do I report inappropriate content?',
          answer: '''1. Tap the menu (⋯) on the post or comment
2. Select "Report Post"
3. Choose a specific reason (Spam, Harassment, Violence, etc.) from our new professional report dialog.
4. Submit your report.

Our moderation team reviews every report. Thank you for keeping Skynaire safe!''',
        ),
        HelpTopic(
          question: 'How is my data protected?',
          answer: '''Skynaire uses:

🔒 End-to-end encryption for messages
🛡️ Secure authentication with Firebase
☁️ Encrypted cloud storage via Supabase
🔐 HTTPS for all data transmission
📊 Automated content moderation

We never share your personal data with third parties.''',
        ),
      ],
    ),
    HelpCategory(
      title: 'Account Management',
      icon: Icons.person_outline,
      color: Colors.indigo,
      topics: [
        HelpTopic(
          question: 'How do I change my password?',
          answer: '''1. Go to Settings
2. Tap "Security"
3. Select "Change Password"
4. Enter current password
5. Enter new password (min 8 characters)
6. Confirm new password
7. Save changes''',
        ),
        HelpTopic(
          question: 'How do I change my username?',
          answer: '''1. Go to your Profile
2. Tap "Edit Profile"
3. Change your username
4. Tap "Save"

Note: Usernames must be unique and can contain letters, numbers, and underscores only.''',
        ),
        HelpTopic(
          question: 'Delete Account',
          answer: '''1. Go to Settings
2. Select "Security"
3. Scroll down to "Account Actions"
4. Tap "Delete Account"
5. Confirm with your password

⚠️ Warning: This action is permanent and cannot be undone. All your posts, followers, and data will be permanently deleted.''',
        ),
      ],
    ),
    HelpCategory(
      title: 'Troubleshooting',
      icon: Icons.build_outlined,
      color: Colors.teal,
      topics: [
        HelpTopic(
          question: 'The app is running slowly',
          answer: '''Try these steps:

1. Clear app cache in Settings
2. Close and restart the app
3. Check your internet connection
4. Update to the latest version
5. Restart your device

If issues persist, contact support.''',
        ),
        HelpTopic(
          question: 'I can\'t upload images',
          answer: '''Check:

📱 Storage permission enabled
📶 Stable internet connection
💾 Available storage space
📏 Image size (max 10MB)

Try:
• Compress the image
• Use a different image
• Restart the app
• Clear app cache''',
        ),
        HelpTopic(
          question: 'I forgot my password',
          answer: '''1. Go to Login screen
2. Tap "Forgot Password?"
3. Enter your email
4. Check your email for reset link
5. Follow the link to create a new password

If you don't receive the email, check your spam folder.''',
        ),
        HelpTopic(
          question: 'Posts are not loading',
          answer: '''1. Pull down to refresh
2. Check your internet connection
3. Log out and log back in
4. Clear app cache
5. Update the app

If the issue persists, posts may be temporarily unavailable due to maintenance.''',
        ),
      ],
    ),
    HelpCategory(
      title: 'Platform Status',
      icon: Icons.speed_outlined,
      color: Colors.amber,
      topics: [
        HelpTopic(
          question: 'Is Skynaire currently online?',
          answer: '''All systems are currently operational.
          
✅ Authentication Service
✅ Media Hosting
✅ Database Cluster
✅ Real-time Messaging
✅ Smart Search Index''',
        ),
        HelpTopic(
          question: 'Scheduled Maintenance',
          answer: '''Typically, maintenance occurs on Sundays at 02:00 AM UTC. During this time, some features may be briefly unavailable for 5-10 minutes.''',
        ),
      ],
    ),
    HelpCategory(
      title: 'App Info & Legal',
      icon: Icons.info_outline,
      color: Colors.blueGrey,
      topics: [
        HelpTopic(
          question: 'App Version',
          answer: '''Skynaire v1.0.0
Build: 2026.01.12
Status: Stable Release''',
        ),
        HelpTopic(
          question: 'Terms of Service',
          answer: '''By using Skynaire, you agree to our Terms of Service. We prioritize community safety and user privacy above all else.''',
        ),
        HelpTopic(
          question: 'Privacy Policy',
          answer: '''Your data is encrypted and secure. We do not sell user data to advertisers. You can export or delete your data anytime in Settings.''',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HelpCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return _helpCategories;

    return _helpCategories
        .map((category) {
          final filteredTopics = category.topics
              .where(
                (topic) =>
                    topic.question.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    topic.answer.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    category.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

          if (filteredTopics.isEmpty) return null;

          return HelpCategory(
            title: category.title,
            icon: category.icon,
            color: category.color,
            topics: filteredTopics,
          );
        })
        .whereType<HelpCategory>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredCategories = _filteredCategories;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('App Center'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            onPressed: () => _contactSupport(context),
            tooltip: 'Contact Support',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search resources...',
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Quick Actions
          if (_searchQuery.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 80,
              child: Row(
                children: [
                  _buildQuickAction(
                    context,
                    'Contact Us',
                    Icons.headset_mic_outlined,
                    Colors.blue,
                    () => _contactSupport(context),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    context,
                    'Video Tutorials',
                    Icons.play_circle_outline,
                    Colors.red,
                    () => _showComingSoon(context),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    context,
                    'Community',
                    Icons.groups_outlined,
                    Colors.green,
                    () => _showComingSoon(context),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Help Categories
          Expanded(
            child: filteredCategories.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      final isExpanded = _expandedCategory == category.title;

                      return _buildCategoryCard(theme, category, isExpanded);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    ThemeData theme,
    HelpCategory category,
    bool isExpanded,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedCategory = isExpanded ? null : category.title;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(category.icon, color: category.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${category.topics.length} topics',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            ...category.topics.map((topic) => _buildTopicTile(theme, topic)),
        ],
      ),
    );
  }

  Widget _buildTopicTile(ThemeData theme, HelpTopic topic) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        topic.question,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text(
            topic.answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _contactSupport(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'meeran01110rafiq@gmail.com',
      query: 'subject=Skynaire Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email: meeran01110rafiq@gmail.com'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class HelpCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<HelpTopic> topics;

  HelpCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.topics,
  });
}

class HelpTopic {
  final String question;
  final String answer;

  HelpTopic({required this.question, required this.answer});
}
