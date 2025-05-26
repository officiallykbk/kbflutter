// Renamed from Trip to CargoJob and fields updated as per schema
class CargoJob {
  final int? id; // Assuming int from Supabase auto-increment
  final String? shipperName;
  final String? paymentStatus;
  final String? deliveryStatus;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? pickupDate; // Storing as String, assuming ISO 8601 format from/to Supabase
  final String? estimatedDeliveryDate; // String
  final String? actualDeliveryDate; // String
  final double? agreedPrice;
  final String? notes;
  final String? updatedAt; // String, from Supabase timestamp
  final String? createdBy; // String, user ID (UUID) from Supabase
  final String? receiptUrl;
  final String? createdAt; // String, from Supabase timestamp

  CargoJob({
    this.id,
    this.shipperName,
    this.paymentStatus,
    this.deliveryStatus,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupDate,
    this.estimatedDeliveryDate,
    this.actualDeliveryDate,
    this.agreedPrice,
    this.notes,
    this.updatedAt,
    this.createdBy,
    this.receiptUrl,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      // id is typically not sent in toJson for create, Supabase handles it. Included if updating.
      // 'id': id, 
      'shipper_name': shipperName,
      'payment_status': paymentStatus,
      'delivery_status': deliveryStatus,
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'pickup_date': pickupDate,
      'estimated_delivery_date': estimatedDeliveryDate,
      'actual_delivery_date': actualDeliveryDate,
      'agreed_price': agreedPrice,
      'notes': notes,
      // 'updated_at': updatedAt, // Supabase usually handles this automatically
      'created_by': createdBy, // Usually set by Supabase based on authenticated user
      'receipt_url': receiptUrl,
      // 'created_at': createdAt, // Supabase usually handles this automatically
    };
  }

  factory CargoJob.fromJson(Map<String, dynamic> json) {
    return CargoJob(
      id: json['id'] as int?,
      shipperName: json['shipper_name'] as String?,
      paymentStatus: json['payment_status'] as String?,
      deliveryStatus: json['delivery_status'] as String?,
      pickupLocation: json['pickup_location'] as String?,
      dropoffLocation: json['dropoff_location'] as String?,
      pickupDate: json['pickup_date'] as String?,
      estimatedDeliveryDate: json['estimated_delivery_date'] as String?,
      actualDeliveryDate: json['actual_delivery_date'] as String?,
      // Handle potential num type from json for double fields
      agreedPrice: (json['agreed_price'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      updatedAt: json['updated_at'] as String?,
      createdBy: json['created_by'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
