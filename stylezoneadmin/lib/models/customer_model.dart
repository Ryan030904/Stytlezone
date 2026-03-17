import 'package:cloud_firestore/cloud_firestore.dart';

/// Customer rank tiers
enum CustomerRank { bronze, silver, gold, platinum, diamond }

class CustomerModel {
  final String id;
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final String role;
  final String provider; // google, email
  final String phone;
  final String address;
  final String gender; // male, female, other
  final String location;
  final DateTime? dateOfBirth;
  final bool isBanned;
  final DateTime? bannedAt;
  final String banReason;
  final double totalSpent; // total money spent
  final String rank; // bronze, silver, gold, platinum, diamond
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerModel({
    required this.id,
    this.uid = '',
    this.email = '',
    this.displayName = '',
    this.photoURL = '',
    this.role = 'user',
    this.provider = '',
    this.phone = '',
    this.address = '',
    this.gender = '',
    this.location = '',
    this.dateOfBirth,
    this.isBanned = false,
    this.bannedAt,
    this.banReason = '',
    this.totalSpent = 0,
    this.rank = 'bronze',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display name with fallback to email prefix
  String get displayLabel =>
      displayName.isNotEmpty ? displayName : email.split('@').first;

  /// Provider label
  String get providerLabel {
    switch (provider) {
      case 'google': return 'Google';
      case 'email': return 'Email';
      default: return provider.isNotEmpty ? provider : 'N/A';
    }
  }

  /// Gender label in Vietnamese
  String get genderLabel {
    switch (gender.toLowerCase()) {
      case 'male': return 'Nam';
      case 'female': return 'Nữ';
      case 'other': return 'Khác';
      default: return '';
    }
  }

  /// Rank label in Vietnamese
  String get rankLabel {
    switch (rank.toLowerCase()) {
      case 'silver': return 'Bạc';
      case 'gold': return 'Vàng';
      case 'platinum': return 'Bạch Kim';
      case 'diamond': return 'Kim Cương';
      default: return 'Đồng';
    }
  }

  /// Rank discount percentage
  int get rankDiscount {
    switch (rank.toLowerCase()) {
      case 'silver': return 3;
      case 'gold': return 5;
      case 'platinum': return 8;
      case 'diamond': return 12;
      default: return 0; // bronze
    }
  }

  /// Amount needed for next rank
  String get nextRankInfo {
    if (rank == 'diamond') return 'Rank cao nhất';
    final thresholds = {'bronze': 2000000, 'silver': 5000000, 'gold': 15000000, 'platinum': 30000000};
    final next = thresholds[rank.toLowerCase()] ?? 2000000;
    final remaining = next - totalSpent;
    if (remaining <= 0) return 'Đủ điều kiện thăng hạng';
    return 'Còn ${_fmtVND(remaining)} để thăng hạng';
  }

  /// Calculate rank based on totalSpent
  static String calculateRank(double spent) {
    if (spent >= 30000000) return 'diamond';
    if (spent >= 15000000) return 'platinum';
    if (spent >= 5000000) return 'gold';
    if (spent >= 2000000) return 'silver';
    return 'bronze';
  }

  static String _fmtVND(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: (json['id'] ?? json['uid'] ?? '').toString(),
      uid: (json['uid'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      photoURL: (json['photoURL'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      provider: (json['provider'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      dateOfBirth: _toDate(json['dateOfBirth']),
      isBanned: json['isBanned'] == true,
      bannedAt: _toDate(json['bannedAt']),
      banReason: (json['banReason'] ?? '').toString(),
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      rank: (json['rank'] ?? 'bronze').toString(),
      createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'role': role,
        'provider': provider,
        'phone': phone,
        'address': address,
        'gender': gender,
        'location': location,
        'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
        'isBanned': isBanned,
        'bannedAt': bannedAt != null ? Timestamp.fromDate(bannedAt!) : null,
        'banReason': banReason,
        'totalSpent': totalSpent,
        'rank': rank,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
