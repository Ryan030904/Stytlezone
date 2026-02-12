import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/admin_enums.dart';

class AuditLogModel {
  final String id;
  final AuditAction action;
  final AuditEntity entity;
  final String entityId;
  final String summary;
  final String oldSummary;
  final String newSummary;
  final Map<String, dynamic> metadata;
  final String actorUid;
  final String actorEmail;
  final String ipAddress;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.summary,
    this.oldSummary = '',
    this.newSummary = '',
    this.metadata = const {},
    this.actorUid = '',
    this.actorEmail = '',
    this.ipAddress = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': EnumMapper.auditAction(action),
      'entity': EnumMapper.auditEntity(entity),
      'entityId': entityId,
      'summary': summary,
      'oldSummary': oldSummary,
      'newSummary': newSummary,
      'metadata': metadata,
      'actorUid': actorUid,
      'actorEmail': actorEmail,
      'ipAddress': ipAddress,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: (json['id'] ?? '').toString(),
      action: EnumMapper.parseAuditAction(json['action']?.toString()),
      entity: EnumMapper.parseAuditEntity(json['entity']?.toString()),
      entityId: (json['entityId'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      oldSummary: (json['oldSummary'] ?? '').toString(),
      newSummary: (json['newSummary'] ?? '').toString(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? const {}),
      actorUid: (json['actorUid'] ?? '').toString(),
      actorEmail: (json['actorEmail'] ?? '').toString(),
      ipAddress: (json['ipAddress'] ?? '').toString(),
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
    );
  }
}
