class ReportModel {
  final String? id;
  final String reporterId;
  final String targetId; // Post ID or Comment ID
  final String targetType; // 'post' or 'comment'
  final String reason;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'dismissed', 'action_taken'

  ReportModel({
    this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ReportModel(
      id: id,
      reporterId: map['reporterId'] ?? '',
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? 'post',
      reason: map['reason'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'] ?? 'pending',
    );
  }
}
