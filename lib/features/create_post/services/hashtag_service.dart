/// Service for managing hashtags
class HashtagService {
  // Hashtag database by category
  static final Map<String, List<String>> _categoryHashtags = {
    'General': [
      '#social',
      '#community',
      '#share',
      '#connect',
      '#network',
      '#daily',
      '#life',
      '#moment',
      '#today',
      '#inspiration',
    ],
    'Technology': [
      '#tech',
      '#technology',
      '#innovation',
      '#digital',
      '#coding',
      '#programming',
      '#developer',
      '#software',
      '#ai',
      '#machinelearning',
      '#webdev',
      '#mobiledev',
      '#techlife',
      '#gadgets',
      '#future',
    ],
    'Art': [
      '#art',
      '#artist',
      '#artwork',
      '#creative',
      '#design',
      '#illustration',
      '#drawing',
      '#painting',
      '#digitalart',
      '#artoftheday',
      '#artistsoninstagram',
      '#instaart',
      '#sketch',
      '#artsy',
      '#contemporary',
    ],
    'Music': [
      '#music',
      '#musician',
      '#song',
      '#singer',
      '#band',
      '#musicproducer',
      '#newmusic',
      '#musicvideo',
      '#livemusic',
      '#concert',
      '#musiclover',
      '#instamusic',
      '#musiclife',
      '#songwriter',
      '#beats',
    ],
    'Food': [
      '#food',
      '#foodie',
      '#foodporn',
      '#instafood',
      '#yummy',
      '#delicious',
      '#foodphotography',
      '#cooking',
      '#recipe',
      '#homemade',
      '#foodstagram',
      '#tasty',
      '#foodlover',
      '#chef',
      '#foodblogger',
    ],
    'Travel': [
      '#travel',
      '#travelphotography',
      '#wanderlust',
      '#adventure',
      '#explore',
      '#travelgram',
      '#instatravel',
      '#traveling',
      '#vacation',
      '#trip',
      '#tourism',
      '#travelblogger',
      '#nature',
      '#landscape',
      '#beautiful',
    ],
    'Sports': [
      '#sports',
      '#fitness',
      '#workout',
      '#gym',
      '#training',
      '#athlete',
      '#sport',
      '#fit',
      '#exercise',
      '#health',
      '#motivation',
      '#fitnessmotivation',
      '#sportlife',
      '#active',
      '#strong',
    ],
    'Fashion': [
      '#fashion',
      '#style',
      '#ootd',
      '#fashionblogger',
      '#fashionista',
      '#instafashion',
      '#outfit',
      '#fashionstyle',
      '#trendy',
      '#stylish',
      '#fashionweek',
      '#model',
      '#fashionphotography',
      '#streetstyle',
      '#look',
    ],
    'Photography': [
      '#photography',
      '#photo',
      '#photographer',
      '#photooftheday',
      '#picoftheday',
      '#instagood',
      '#instadaily',
      '#photoshoot',
      '#camera',
      '#photos',
      '#naturephotography',
      '#portraitphotography',
      '#streetphotography',
      '#art',
      '#beautiful',
    ],
    'Business': [
      '#business',
      '#entrepreneur',
      '#marketing',
      '#success',
      '#motivation',
      '#startup',
      '#businessowner',
      '#smallbusiness',
      '#entrepreneurship',
      '#hustle',
      '#businesslife',
      '#leadership',
      '#mindset',
      '#goals',
      '#growth',
    ],
  };

  // Trending hashtags (Simulated live data)
  static final List<String> _trendingHashtags = [
    '#viral',
    '#trending',
    '#explore',
    '#fyp',
    '#foryou',
    '#instagood',
    '#photooftheday',
    '#love',
    '#beautiful',
    '#happy',
    '#innovation',
    '#future',
    '#tech',
    '#coding',
    '#art',
    '#nature',
    '#life',
    '#motivation',
    '#success',
    '#community',
  ];

  /// Get suggested hashtags for a category
  List<String> getSuggestedHashtags(String category, {int count = 10}) {
    final categoryTags =
        _categoryHashtags[category] ?? _categoryHashtags['General']!;
    final trending = _trendingHashtags.take(5).toList();

    // Mix category-specific and trending (Smart Mix)
    final suggested = <String>[];
    suggested.addAll(trending.take(3)); // Top 3 trending
    suggested.addAll(categoryTags.take(count - 3)); // Rest category specific

    return suggested.take(count).toList();
  }

  /// Get hashtags by popularity level (3-Tier Strategy)
  Map<String, List<String>> getHashtagsByPopularity(String category) {
    final allTags =
        _categoryHashtags[category] ?? _categoryHashtags['General']!;

    // Simulating tiered structure based on list position
    // In a real app, this would come from volume data
    return {
      'broad': allTags.take(5).toList(), // >1M posts
      'niche': allTags.skip(5).take(10).toList(), // 100k-1M posts
      'specific': allTags.skip(15).take(5).toList(), // <100k posts
    };
  }

  /// Validate hashtag format (Supports International/Unicode)
  bool isValidHashtag(String hashtag) {
    if (!hashtag.startsWith('#')) return false;
    if (hashtag.length < 2) return false;
    if (hashtag.length > 50) return false; // Increased limit for complex scripts

    // Check for invalid characters (Supports Unicode Letters & Numbers)
    // \p{L} matches any unicode letter, \p{N} matches any unicode number
    final validPattern = RegExp(r'^#[\p{L}\p{N}_]+$', unicode: true);
    return validPattern.hasMatch(hashtag);
  }

  /// Clean and format hashtag (Unicode aware)
  String formatHashtag(String input) {
    String cleaned = input.trim().toLowerCase();

    // Allow Unicode letters, numbers, and underscores
    cleaned = cleaned.replaceAll(RegExp(r'[^\p{L}\p{N}_]', unicode: true), '');

    // Add # if missing
    if (!cleaned.startsWith('#')) {
      cleaned = '#$cleaned';
    }

    return cleaned;
  }

  /// Get hashtag recommendations based on text content (NLP-lite)
  List<String> getRecommendationsFromText(String text, String category) {
    // 1. Tokenize (Unicode aware)
    final words = text.toLowerCase().split(RegExp(r'[\s\p{P}]+', unicode: true));
    final recommendations = <String>[];

    // 2. Extract Keywords
    final keywords = _extractKeywords(words);
    for (final keyword in keywords) {
      if (keyword.length >= 3) {
        recommendations.add('#$keyword');
      }
    }

    // 3. Add Category Context
    final categoryTags = getSuggestedHashtags(category, count: 5);
    recommendations.addAll(categoryTags);

    // 4. Remove duplicates and limit
    return recommendations.toSet().take(15).toList();
  }

  /// Extract keywords from text (Improved Stop Words)
  List<String> _extractKeywords(List<String> words) {
    // Comprehensive stop words list
    final stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 
      'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'been', 'be', 
      'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 
      'should', 'may', 'might', 'must', 'can', 'this', 'that', 'these', 'those', 
      'i', 'you', 'he', 'she', 'it', 'we', 'they', 'my', 'your', 'his', 'her', 
      'its', 'our', 'their', 'what', 'which', 'who', 'whom', 'whose', 'where', 
      'when', 'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 
      'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 
      'than', 'too', 'very', 'just', 'now', 'then', 'here', 'there', 'about',
      'after', 'before', 'during', 'under', 'above', 'below', 'up', 'down',
      'out', 'off', 'over', 'under', 'again', 'further', 'then', 'once'
    };

    // Filter and score words (frequency analysis could go here)
    return words
        .where((word) => word.length >= 3 && !stopWords.contains(word))
        .toSet() // Unique words only
        .take(8)
        .toList();
  }

  /// Validate hashtag list (Strategy Analysis)
  Map<String, dynamic> validateHashtagList(List<String> hashtags) {
    final errors = <String>[];
    final warnings = <String>[];

    if (hashtags.isEmpty) {
      errors.add('No hashtags added');
    } else if (hashtags.length < 5) {
      warnings.add('Add more hashtags (5-15 is optimal)');
    } else if (hashtags.length > 30) {
      warnings.add('Too many hashtags (Instagram limit is 30, recommended 15)');
    }

    // Check individual hashtags
    for (final tag in hashtags) {
      if (!isValidHashtag(tag)) {
        errors.add('Invalid hashtag format: $tag');
      }
    }

    // Check for duplicates
    if (hashtags.length != hashtags.toSet().length) {
      warnings.add('Duplicate hashtags found');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'score': _calculateHashtagScore(hashtags),
    };
  }

  /// Calculate hashtag quality score (Weighted Strategy)
  int _calculateHashtagScore(List<String> hashtags) {
    int score = 0;

    if (hashtags.isEmpty) return 0;

    // 1. Quantity Score (30%)
    if (hashtags.length >= 8 && hashtags.length <= 20) {
      score += 30;
    } else if (hashtags.length >= 5) {
      score += 20;
    } else {
      score += 10;
    }

    // 2. Format Score (20%)
    final validCount = hashtags.where((tag) => isValidHashtag(tag)).length;
    final validRatio = validCount / hashtags.length;
    score += (validRatio * 20).round();

    // 3. Diversity Score (20%)
    final uniqueCount = hashtags.toSet().length;
    score += ((uniqueCount / hashtags.length) * 20).round();

    // 4. Mix Strategy Bonus (30%) - Ideally check for Broad/Niche mix
    // Since we don't have volume data for custom tags, we infer from length
    // Short tags (<6 chars) often broad (#love), Long tags (>12) often specific
    bool hasBroad = hashtags.any((t) => t.length < 8);
    bool hasSpecific = hashtags.any((t) => t.length > 12);
    
    if (hasBroad && hasSpecific) {
      score += 30; // Good mix
    } else if (hasBroad || hasSpecific) {
      score += 15; // Partial mix
    }

    return score.clamp(0, 100);
  }

  /// Get optimal hashtag count recommendation
  String getHashtagCountRecommendation(int currentCount) {
    if (currentCount < 5) {
      return 'Add ${5 - currentCount} more to reach minimum recommended (5)';
    } else if (currentCount < 10) {
      return 'Great start! Add a few more niche tags for better targeting';
    } else if (currentCount <= 20) {
      return 'Perfect! You have a strong hashtag volume';
    } else {
      return 'You\'re reaching the limit. Focus on quality over quantity now.';
    }
  }
}
