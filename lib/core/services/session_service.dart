import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';

final sessionServiceProvider = Provider<SessionService>((ref) => SessionService());

final userSessionsProvider = StreamProvider<List<SessionModel>>((ref) {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.getSessions();
});

class SessionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _currentDeviceId;
  String? get currentDeviceId => _currentDeviceId;

  // Initialize and record current session
  Future<void> initSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final session = await _getCurrentSessionInfo();
      _currentDeviceId = session.id;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(session.id)
          .set(session.toMap(), SetOptions(merge: true));
      
      debugPrint('✅ Session initialized: ${session.deviceName} ($currentDeviceId)');
    } catch (e) {
      debugPrint('❌ Error initializing session: $e');
    }
  }

  Future<void> updateLastActive() async {
    final user = _auth.currentUser;
    if (user == null || _currentDeviceId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(_currentDeviceId)
          .update({
        'lastActive': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating session heartbeat: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(sessionId)
        .delete();
  }

  Future<void> signOutAllExceptCurrent() async {
    final user = _auth.currentUser;
    if (user == null || _currentDeviceId == null) return;

    final batch = _firestore.batch();
    final snapshots = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .get();

    for (var doc in snapshots.docs) {
      if (doc.id != _currentDeviceId) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  Stream<List<SessionModel>> getSessions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SessionModel.fromMap(
          doc.data(),
          isCurrent: doc.id == _currentDeviceId,
        );
      }).toList();
    });
  }

  Future<SessionModel> _getCurrentSessionInfo() async {
    String deviceName = 'Unknown Device';
    String platform = 'Unknown OS';
    String deviceType = 'browser';
    String deviceId = DateTime.now().millisecondsSinceEpoch.toString(); 

    try {
        if (kIsWeb) {
            final webInfo = await _deviceInfo.webBrowserInfo;
            deviceName = webInfo.browserName.toString();
            platform = 'Web';
            deviceType = 'Web';
            // Use user agent + vendor as a semi-unique ID for web
            deviceId = '${webInfo.vendor ?? 'web'}-${webInfo.userAgent ?? 'agent'}'.hashCode.toString();
        } else if (Platform.isAndroid) {
            final androidInfo = await _deviceInfo.androidInfo;
            deviceName = '${androidInfo.brand} ${androidInfo.model}';
            platform = 'Android ${androidInfo.version.release}';
            deviceType = 'Mobile';
            deviceId = androidInfo.id; // Unique Android ID
        } else if (Platform.isIOS) {
            final iosInfo = await _deviceInfo.iosInfo;
            deviceName = iosInfo.name;
            platform = '${iosInfo.systemName} ${iosInfo.systemVersion}';
            deviceType = 'Mobile';
            deviceId = iosInfo.identifierForVendor ?? deviceId;
        } else if (Platform.isWindows) {
           final windowsInfo = await _deviceInfo.windowsInfo;
           deviceName = windowsInfo.computerName;
           platform = 'Windows';
           deviceType = 'Desktop';
           deviceId = windowsInfo.deviceId;
        } else if (Platform.isMacOS) {
           final macInfo = await _deviceInfo.macOsInfo;
           deviceName = macInfo.computerName;
           platform = 'macOS ${macInfo.osRelease}';
           deviceType = 'Desktop';
           deviceId = macInfo.systemGUID ?? deviceId;
        } else if (Platform.isLinux) {
           final linuxInfo = await _deviceInfo.linuxInfo;
           deviceName = linuxInfo.name;
           platform = 'Linux ${linuxInfo.versionId}';
           deviceType = 'Desktop';
           deviceId = linuxInfo.machineId ?? deviceId;
        }
    } catch (e) {
        debugPrint('Error getting device info: $e');
    }

    return SessionModel(
      id: deviceId,
      deviceName: deviceName,
      platform: platform,
      deviceType: deviceType,
      lastActive: DateTime.now(),
      location: 'Unknown', // Requires external API
    );
  }
}
