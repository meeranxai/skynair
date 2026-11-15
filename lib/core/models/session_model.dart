class SessionModel {
  final String id;
  final String deviceName;
  final String platform;
  final String deviceType;
  final String location;
  final DateTime lastActive;
  final bool isCurrent;
  final String? ipAddress;

  SessionModel({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.deviceType,
    this.location = 'Unknown',
    required this.lastActive,
    this.isCurrent = false,
    this.ipAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceName': deviceName,
      'platform': platform,
      'deviceType': deviceType,
      'location': location,
      'lastActive': lastActive.toIso8601String(),
      'ipAddress': ipAddress,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map, {bool isCurrent = false}) {
    return SessionModel(
      id: map['id'] ?? '',
      deviceName: map['deviceName'] ?? 'Unknown Device',
      platform: map['platform'] ?? 'Unknown OS',
      deviceType: map['deviceType'] ?? 'Unknown',
      location: map['location'] ?? 'Unknown',
      lastActive: map['lastActive'] != null 
          ? DateTime.parse(map['lastActive']) 
          : DateTime.now(),
      isCurrent: isCurrent,
      ipAddress: map['ipAddress'],
    );
  }
}
