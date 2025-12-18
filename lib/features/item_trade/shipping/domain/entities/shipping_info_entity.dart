class ShippingInfoEntity {
  ShippingInfoEntity({
    required this.itemId,
    required this.carrier,
    required this.trackingNumber,
    this.createdAt,
  });

  final String itemId;
  final String carrier;
  final String trackingNumber;
  final String? createdAt;

  factory ShippingInfoEntity.fromMap(Map<String, dynamic> map) {
    return ShippingInfoEntity(
      itemId: map['item_id'] as String? ?? '',
      carrier: map['carrier'] as String? ?? '',
      trackingNumber: map['tracking_number'] as String? ?? '',
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'carrier': carrier,
      'tracking_number': trackingNumber,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}


