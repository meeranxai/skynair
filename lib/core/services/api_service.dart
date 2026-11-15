import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer';

import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.apiTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        sendTimeout: AppConfig.apiTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add JWT token to requests
          final token = await _secureStorage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          log('API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => log(obj.toString()),
      ),
    );
  }

  // Auth endpoints
  Future<Map<String, dynamic>> exchangeFirebaseToken({
    required String firebaseToken,
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/firebase-login',
        data: {
          'firebaseToken': firebaseToken,
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'photoURL': photoURL,
        },
      );

      if (response.data['token'] != null) {
        await _secureStorage.write(
          key: 'jwt_token',
          value: response.data['token'],
        );
      }

      return response.data;
    } catch (e) {
      log('Firebase token exchange error: $e');
      rethrow;
    }
  }

  // User endpoints
  Future<UserModel> syncUserProfile(UserModel user) async {
    try {
      final response = await _dio.post('/users/sync', data: user.toMap());
      return UserModel.fromMap(response.data['user']);
    } catch (e) {
      log('User sync error: $e');
      rethrow;
    }
  }

  Future<UserModel> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/users/$userId', data: data);
      return UserModel.fromMap(response.data['user']);
    } catch (e) {
      log('User update error: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/users/search',
        queryParameters: {'q': query, 'limit': 20},
      );

      return (response.data['users'] as List)
          .map((user) => UserModel.fromMap(user))
          .toList();
    } catch (e) {
      log('User search error: $e');
      return [];
    }
  }

  Future<UserModel> getUserProfile(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return UserModel.fromMap(response.data['user']);
    } catch (e) {
      log('Get user profile error: $e');
      rethrow;
    }
  }

  // Post endpoints
  Future<PostModel> createPost(PostModel post) async {
    try {
      final response = await _dio.post('/posts', data: post.toMap());
      return PostModel.fromMap(response.data['post']);
    } catch (e) {
      log('Create post error: $e');
      rethrow;
    }
  }

  Future<List<PostModel>> getPosts({
    int page = 1,
    int limit = 20,
    String? category,
    String? userId,
  }) async {
    try {
      final response = await _dio.get(
        '/posts',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (category != null) 'category': category,
          if (userId != null) 'userId': userId,
        },
      );

      return (response.data['posts'] as List)
          .map((post) => PostModel.fromMap(post))
          .toList();
    } catch (e) {
      log('Get posts error: $e');
      return [];
    }
  }

  Future<PostModel> updatePost(String postId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/posts/$postId', data: data);
      return PostModel.fromMap(response.data['post']);
    } catch (e) {
      log('Update post error: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _dio.delete('/posts/$postId');
    } catch (e) {
      log('Delete post error: $e');
      rethrow;
    }
  }

  Future<void> likePost(String postId) async {
    try {
      await _dio.post('/posts/$postId/like');
    } catch (e) {
      log('Like post error: $e');
      rethrow;
    }
  }

  Future<void> unlikePost(String postId) async {
    try {
      await _dio.delete('/posts/$postId/like');
    } catch (e) {
      log('Unlike post error: $e');
      rethrow;
    }
  }

  Future<void> savePost(String postId) async {
    try {
      await _dio.post('/posts/$postId/save');
    } catch (e) {
      log('Save post error: $e');
      rethrow;
    }
  }

  Future<void> unsavePost(String postId) async {
    try {
      await _dio.delete('/posts/$postId/save');
    } catch (e) {
      log('Unsave post error: $e');
      rethrow;
    }
  }

  // Follow endpoints
  Future<void> followUser(String userId) async {
    try {
      await _dio.post('/users/$userId/follow');
    } catch (e) {
      log('Follow user error: $e');
      rethrow;
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      await _dio.delete('/users/$userId/follow');
    } catch (e) {
      log('Unfollow user error: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/followers');
      return (response.data['followers'] as List)
          .map((user) => UserModel.fromMap(user))
          .toList();
    } catch (e) {
      log('Get followers error: $e');
      return [];
    }
  }

  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/following');
      return (response.data['following'] as List)
          .map((user) => UserModel.fromMap(user))
          .toList();
    } catch (e) {
      log('Get following error: $e');
      return [];
    }
  }

  // Utility methods
  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: 'jwt_token');
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }
}
