/// Settings model — holds all store configuration for the admin Settings tab.
class StoreSettings {
  // ── Store Information ──
  final String storeName;
  final String slogan;
  final String contactEmail;
  final String contactPhone;
  final String storeAddress;
  final String logoUrl;

  // ── Payment Configuration ──
  final String bankId;     // e.g. "VCB", "MB", "ACB"
  final String bankAccount;
  final String bankAccountName;
  final bool codEnabled;
  final bool bankTransferEnabled;
  final bool momoEnabled;

  // ── Shipping Configuration ──
  final double defaultShippingFee;
  final double freeShippingThreshold;
  final String estimatedDeliveryTime;

  // ── Social Media Links ──
  final String facebookUrl;
  final String instagramUrl;
  final String tiktokUrl;

  // ── Rank Configuration ──
  final double rankSilverThreshold;
  final double rankGoldThreshold;
  final double rankPlatinumThreshold;
  final double rankDiamondThreshold;
  final int rankBronzeDiscount;
  final int rankSilverDiscount;
  final int rankGoldDiscount;
  final int rankPlatinumDiscount;
  final int rankDiamondDiscount;

  // ── System (read-only display) ──
  final String cloudinaryCloudName;
  final String cloudinaryPreset;
  final String appVersion;

  const StoreSettings({
    this.storeName = 'StyleZone',
    this.slogan = 'Phong cách thời trang hiện đại dành cho bạn',
    this.contactEmail = '',
    this.contactPhone = '',
    this.storeAddress = '',
    this.logoUrl = '',
    this.bankId = 'VCB',
    this.bankAccount = '1035238323',
    this.bankAccountName = 'NGUYEN TRONG QUI',
    this.codEnabled = true,
    this.bankTransferEnabled = true,
    this.momoEnabled = true,
    this.defaultShippingFee = 0,
    this.freeShippingThreshold = 500000,
    this.estimatedDeliveryTime = '2-5 ngày làm việc',
    this.facebookUrl = '',
    this.instagramUrl = '',
    this.tiktokUrl = '',
    this.rankSilverThreshold = 2000000,
    this.rankGoldThreshold = 5000000,
    this.rankPlatinumThreshold = 15000000,
    this.rankDiamondThreshold = 30000000,
    this.rankBronzeDiscount = 0,
    this.rankSilverDiscount = 3,
    this.rankGoldDiscount = 5,
    this.rankPlatinumDiscount = 8,
    this.rankDiamondDiscount = 12,
    this.cloudinaryCloudName = 'dtwzcwhaa',
    this.cloudinaryPreset = 'stylezone',
    this.appVersion = '1.0.0',
  });

  /// Parse from Firestore document map.
  factory StoreSettings.fromMap(Map<String, dynamic> map) {
    return StoreSettings(
      storeName: map['storeName'] as String? ?? 'StyleZone',
      slogan: map['slogan'] as String? ?? '',
      contactEmail: map['contactEmail'] as String? ?? '',
      contactPhone: map['contactPhone'] as String? ?? '',
      storeAddress: map['storeAddress'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      bankId: map['bankId'] as String? ?? 'VCB',
      bankAccount: map['bankAccount'] as String? ?? '',
      bankAccountName: map['bankAccountName'] as String? ?? '',
      codEnabled: map['codEnabled'] as bool? ?? true,
      bankTransferEnabled: map['bankTransferEnabled'] as bool? ?? true,
      momoEnabled: map['momoEnabled'] as bool? ?? true,
      defaultShippingFee: (map['defaultShippingFee'] as num?)?.toDouble() ?? 0,
      freeShippingThreshold: (map['freeShippingThreshold'] as num?)?.toDouble() ?? 500000,
      estimatedDeliveryTime: map['estimatedDeliveryTime'] as String? ?? '2-5 ngày làm việc',
      facebookUrl: map['facebookUrl'] as String? ?? '',
      instagramUrl: map['instagramUrl'] as String? ?? '',
      tiktokUrl: map['tiktokUrl'] as String? ?? '',
      rankSilverThreshold: (map['rankSilverThreshold'] as num?)?.toDouble() ?? 2000000,
      rankGoldThreshold: (map['rankGoldThreshold'] as num?)?.toDouble() ?? 5000000,
      rankPlatinumThreshold: (map['rankPlatinumThreshold'] as num?)?.toDouble() ?? 15000000,
      rankDiamondThreshold: (map['rankDiamondThreshold'] as num?)?.toDouble() ?? 30000000,
      rankBronzeDiscount: (map['rankBronzeDiscount'] as num?)?.toInt() ?? 0,
      rankSilverDiscount: (map['rankSilverDiscount'] as num?)?.toInt() ?? 3,
      rankGoldDiscount: (map['rankGoldDiscount'] as num?)?.toInt() ?? 5,
      rankPlatinumDiscount: (map['rankPlatinumDiscount'] as num?)?.toInt() ?? 8,
      rankDiamondDiscount: (map['rankDiamondDiscount'] as num?)?.toInt() ?? 12,
      cloudinaryCloudName: map['cloudinaryCloudName'] as String? ?? 'dtwzcwhaa',
      cloudinaryPreset: map['cloudinaryPreset'] as String? ?? 'stylezone',
      appVersion: map['appVersion'] as String? ?? '1.0.0',
    );
  }

  /// Convert to Firestore-ready map.
  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'slogan': slogan,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'storeAddress': storeAddress,
      'logoUrl': logoUrl,
      'bankId': bankId,
      'bankAccount': bankAccount,
      'bankAccountName': bankAccountName,
      'codEnabled': codEnabled,
      'bankTransferEnabled': bankTransferEnabled,
      'momoEnabled': momoEnabled,
      'defaultShippingFee': defaultShippingFee,
      'freeShippingThreshold': freeShippingThreshold,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'facebookUrl': facebookUrl,
      'instagramUrl': instagramUrl,
      'tiktokUrl': tiktokUrl,
      'rankSilverThreshold': rankSilverThreshold,
      'rankGoldThreshold': rankGoldThreshold,
      'rankPlatinumThreshold': rankPlatinumThreshold,
      'rankDiamondThreshold': rankDiamondThreshold,
      'rankBronzeDiscount': rankBronzeDiscount,
      'rankSilverDiscount': rankSilverDiscount,
      'rankGoldDiscount': rankGoldDiscount,
      'rankPlatinumDiscount': rankPlatinumDiscount,
      'rankDiamondDiscount': rankDiamondDiscount,
      'cloudinaryCloudName': cloudinaryCloudName,
      'cloudinaryPreset': cloudinaryPreset,
      'appVersion': appVersion,
    };
  }

  /// Create a modified copy.
  StoreSettings copyWith({
    String? storeName,
    String? slogan,
    String? contactEmail,
    String? contactPhone,
    String? storeAddress,
    String? logoUrl,
    String? bankId,
    String? bankAccount,
    String? bankAccountName,
    bool? codEnabled,
    bool? bankTransferEnabled,
    bool? momoEnabled,
    double? defaultShippingFee,
    double? freeShippingThreshold,
    String? estimatedDeliveryTime,
    String? facebookUrl,
    String? instagramUrl,
    String? tiktokUrl,
    double? rankSilverThreshold,
    double? rankGoldThreshold,
    double? rankPlatinumThreshold,
    double? rankDiamondThreshold,
    int? rankBronzeDiscount,
    int? rankSilverDiscount,
    int? rankGoldDiscount,
    int? rankPlatinumDiscount,
    int? rankDiamondDiscount,
    String? cloudinaryCloudName,
    String? cloudinaryPreset,
    String? appVersion,
  }) {
    return StoreSettings(
      storeName: storeName ?? this.storeName,
      slogan: slogan ?? this.slogan,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      storeAddress: storeAddress ?? this.storeAddress,
      logoUrl: logoUrl ?? this.logoUrl,
      bankId: bankId ?? this.bankId,
      bankAccount: bankAccount ?? this.bankAccount,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      codEnabled: codEnabled ?? this.codEnabled,
      bankTransferEnabled: bankTransferEnabled ?? this.bankTransferEnabled,
      momoEnabled: momoEnabled ?? this.momoEnabled,
      defaultShippingFee: defaultShippingFee ?? this.defaultShippingFee,
      freeShippingThreshold: freeShippingThreshold ?? this.freeShippingThreshold,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      rankSilverThreshold: rankSilverThreshold ?? this.rankSilverThreshold,
      rankGoldThreshold: rankGoldThreshold ?? this.rankGoldThreshold,
      rankPlatinumThreshold: rankPlatinumThreshold ?? this.rankPlatinumThreshold,
      rankDiamondThreshold: rankDiamondThreshold ?? this.rankDiamondThreshold,
      rankBronzeDiscount: rankBronzeDiscount ?? this.rankBronzeDiscount,
      rankSilverDiscount: rankSilverDiscount ?? this.rankSilverDiscount,
      rankGoldDiscount: rankGoldDiscount ?? this.rankGoldDiscount,
      rankPlatinumDiscount: rankPlatinumDiscount ?? this.rankPlatinumDiscount,
      rankDiamondDiscount: rankDiamondDiscount ?? this.rankDiamondDiscount,
      cloudinaryCloudName: cloudinaryCloudName ?? this.cloudinaryCloudName,
      cloudinaryPreset: cloudinaryPreset ?? this.cloudinaryPreset,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
