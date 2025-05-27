import 'package:bizorganizer/models/status_constants.dart'; // Task 2.1

// Renamed from Trip to CargoJob and fields updated as per schema
class CargoJob {
  final int? id; 
  final String? shipperName;
  final String? paymentStatus; // Will store string representation from PaymentStatus enum
  final String? deliveryStatus; // Will store string representation from DeliveryStatus enum
  final String? pickupLocation;
  final String? dropoffLocation;
  final DateTime? pickupDate; // Task 2.2
  final DateTime? estimatedDeliveryDate; // Task 2.2
  final DateTime? actualDeliveryDate; // Task 2.2
  final double? agreedPrice;
  final String? notes;
  final DateTime? updatedAt; // Task 2.2
  final String? createdBy; 
  final String? receiptUrl;
  final DateTime? createdAt; // Task 2.2

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

  // Task 2.5: effectiveDeliveryStatus Getter
  String? get effectiveDeliveryStatus {
    // Ensure deliveryStatus itself is not null before using it.
    // If deliveryStatus is already 'Completed' or 'Cancelled', it takes precedence.
    if (deliveryStatus == deliveryStatusToString(DeliveryStatus.Completed) ||
        deliveryStatus == deliveryStatusToString(DeliveryStatus.Cancelled)) {
      return deliveryStatus;
    }
    // If there's an actual delivery date, the job is considered completed.
    if (actualDeliveryDate != null) {
      return deliveryStatusToString(DeliveryStatus.Completed);
    }
    // If it's past the estimated delivery date and not yet completed/cancelled, it's Overdue.
    if (estimatedDeliveryDate != null && estimatedDeliveryDate!.isBefore(DateTime.now())) {
      return deliveryStatusToString(DeliveryStatus.Overdue);
    }
    // Otherwise, return the current delivery status or default to Pending if null.
    return deliveryStatus ?? deliveryStatusToString(DeliveryStatus.Pending);
  }


  Map<String, dynamic> toJson() { // Task 2.4
    return {
      // id is typically not sent in toJson for create, Supabase handles it. 
      // It might be needed if the toJson is used for updates where ID is required.
      // 'id': id, 
      'shipper_name': shipperName,
      'payment_status': paymentStatus, // Assumes this string is already from paymentStatusToString()
      'delivery_status': deliveryStatus, // Assumes this string is already from deliveryStatusToString()
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'pickup_date': pickupDate?.toIso8601String(),
      'estimated_delivery_date': estimatedDeliveryDate?.toIso8601String(),
      'actual_delivery_date': actualDeliveryDate?.toIso8601String(),
      'agreed_price': agreedPrice,
      'notes': notes,
      // Supabase usually handles updated_at and created_at automatically on the server-side.
      // Only include them if you are explicitly setting them from the client.
      // 'updated_at': updatedAt?.toIso8601String(), 
      'created_by': createdBy, 
      'receipt_url': receiptUrl,
      // 'created_at': createdAt?.toIso8601String(),
    };
  }

  factory CargoJob.fromJson(Map<String, dynamic> json) { // Task 2.3
    return CargoJob(
      id: json['id'] as int?,
      shipperName: json['shipper_name'] as String?,
      paymentStatus: json['payment_status'] as String?,
      deliveryStatus: json['delivery_status'] as String?,
      pickupLocation: json['pickup_location'] as String?,
      dropoffLocation: json['dropoff_location'] as String?,
      pickupDate: json['pickup_date'] == null ? null : DateTime.tryParse(json['pickup_date'] as String),
      estimatedDeliveryDate: json['estimated_delivery_date'] == null ? null : DateTime.tryParse(json['estimated_delivery_date'] as String),
      actualDeliveryDate: json['actual_delivery_date'] == null ? null : DateTime.tryParse(json['actual_delivery_date'] as String),
      agreedPrice: (json['agreed_price'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      updatedAt: json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'] as String),
    );
  }
}
