import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/home/widgets/live_indicator.dart';
import '../features/home/widgets/notification_badge.dart';
import '../features/home/widgets/story_bar.dart';
import '../features/home/widgets/create_post_widget.dart';
import '../features/home/widgets/post_card.dart';
import '../core/models/post_model.dart';

/// Widget Preview App for Flutter Widget Inspector
class WidgetPreviewApp extends StatelessWidget {
  const WidgetPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Skynaire Widget Previews',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const WidgetPreviewsPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Main preview page showing all widgets
class WidgetPreviewsPage extends StatefulWidget {
  const WidgetPreviewsPage({super.key});

  @override
  State<WidgetPreviewsPage> createState() => _WidgetPreviewsPageState();
}

class _WidgetPreviewsPageState extends State<WidgetPreviewsPage>
    with TickerProviderStateMixin {
  late AnimationController _liveController;

  @override
  void initState() {
    super.initState();
    _liveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _liveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skynaire Widget Previews'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Live Indicator', [
            _buildPreviewCard(
              'Live Indicator - Online',
              const LiveIndicator(isLive: true),
            ),
            _buildPreviewCard(
              'Live Indicator - Offline',
              const LiveIndicator(isLive: false),
            ),
          ]),

          _buildSection('Notification Badge', [
            _buildPreviewCard(
              'Notification Badge - 5',
              NotificationBadge(count: 5, child: Icon(Icons.notifications)),
            ),
            _buildPreviewCard(
              'Notification Badge - 99+',
              NotificationBadge(count: 150, child: Icon(Icons.message)),
            ),
            _buildPreviewCard(
              'Notification Badge - Custom Color',
              NotificationBadge(
                count: 3,
                backgroundColor: Colors.green,
                textColor: Colors.white,
                child: Icon(Icons.favorite),
              ),
            ),
          ]),

          _buildSection('Story Bar', [
            _buildPreviewCard(
              'Story Bar',
              const SizedBox(height: 120, child: StoryBar()),
            ),
          ]),

          _buildSection('Create Post Widget', [
            _buildPreviewCard('Create Post Widget', const CreatePostWidget()),
          ]),

          _buildSection('Post Card', [
            _buildPreviewCard(
              'Sample Post Card',
              PostCard(
                post: _createSamplePost(),
                currentUserId: 'current_user_123',
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPreviewCard(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  PostModel _createSamplePost() {
    return PostModel(
      id: 'sample_post_1',
      title: 'Sample Post Title',
      category: 'general',
      authorId: 'user_123',
      author: 'John Doe',
      authorAvatar: null,
      description:
          'This is a sample post for widget preview! 🚀\n\nIt shows how the post card looks with some content and demonstrates the professional design we\'ve implemented.',
      image: null,
      likes: ['user_1', 'user_2', 'user_3', 'current_user_123'],
      commentsCount: 5,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }
}

/// Individual widget previews for focused testing

/// Live Indicator Preview
class LiveIndicatorPreview extends StatefulWidget {
  const LiveIndicatorPreview({super.key});

  @override
  State<LiveIndicatorPreview> createState() => _LiveIndicatorPreviewState();
}

class _LiveIndicatorPreviewState extends State<LiveIndicatorPreview>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLive = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Live Indicator Preview')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LiveIndicator(isLive: _isLive),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _isLive = !_isLive),
                child: Text(_isLive ? 'Go Offline' : 'Go Online'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notification Badge Preview
class NotificationBadgePreview extends StatefulWidget {
  const NotificationBadgePreview({super.key});

  @override
  State<NotificationBadgePreview> createState() =>
      _NotificationBadgePreviewState();
}

class _NotificationBadgePreviewState extends State<NotificationBadgePreview> {
  int _count = 1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Notification Badge Preview')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications, size: 30),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: NotificationBadge(
                      count: _count,
                      child: SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => _count = (_count - 1).clamp(0, 999)),
                    child: const Text('-'),
                  ),
                  const SizedBox(width: 20),
                  Text('Count: $_count'),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => _count = (_count + 1).clamp(0, 999)),
                    child: const Text('+'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Story Bar Preview
class StoryBarPreview extends StatelessWidget {
  const StoryBarPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Story Bar Preview')),
          body: const Column(
            children: [
              SizedBox(height: 20),
              StoryBar(),
              Expanded(
                child: Center(
                  child: Text(
                    'Story Bar Preview\nScroll horizontally to see all stories',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Create Post Widget Preview
class CreatePostWidgetPreview extends StatelessWidget {
  const CreatePostWidgetPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Create Post Widget Preview')),
          body: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                CreatePostWidget(),
                Expanded(
                  child: Center(
                    child: Text(
                      'Create Post Widget Preview\nTap to interact with the widget',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Post Card Preview
class PostCardPreview extends StatelessWidget {
  const PostCardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Post Card Preview')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: PostCard(
              post: PostModel(
                id: 'preview_post',
                title: 'Preview Post Title',
                category: 'preview',
                authorId: 'preview_user',
                author: 'Preview User',
                authorAvatar: null,
                description:
                    'This is a preview post showing the professional design of our post cards! 🎨\n\nIt includes all the features like likes, comments, and sharing.',
                image: null,
                likes: ['user1', 'user2', 'user3'],
                commentsCount: 8,
                createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
                updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
              ),
              currentUserId: 'current_user',
            ),
          ),
        ),
      ),
    );
  }
}
