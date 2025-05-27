import 'package:bizorganizer/models/status_constants.dart';

class CargoJob {
  final int? id; 
  final String? shipperName;
  final String? paymentStatus; 
  final String? deliveryStatus; 
  final String? pickupLocation;
  final String? dropoffLocation;
  final DateTime? pickupDate; 
  final DateTime? estimatedDeliveryDate; 
  final DateTime? actualDeliveryDate; 
  final double? agreedPrice;
  final String? notes;
  final DateTime? updatedAt; 
  final String? createdBy; 
  final String? receiptUrl;
  final DateTime? createdAt; 

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

  String? get effectiveDeliveryStatus {
    // If already in a terminal state set by user, respect that.
    if (deliveryStatus == deliveryStatusToString(DeliveryStatus.Delivered) ||
        deliveryStatus == deliveryStatusToString(DeliveryStatus.Cancelled)) {
      return deliveryStatus;
    }

    // If an actual delivery date is set, it's considered Delivered.
    if (actualDeliveryDate != null) {
      return deliveryStatusToString(DeliveryStatus.Delivered);
    }

    // If it's past estimated delivery and not yet Delivered or Cancelled, it's Delayed.
    // (This implies the actual stored status could be Scheduled or InProgress)
    if (estimatedDeliveryDate != null && 
        deliveryStatus != deliveryStatusToString(DeliveryStatus.Delivered) && // Ensure not already delivered
        deliveryStatus != deliveryStatusToString(DeliveryStatus.Cancelled) && // Ensure not already cancelled
        estimatedDeliveryDate!.isBefore(DateTime.now())) {
      return deliveryStatusToString(DeliveryStatus.Delayed);
    }

    // Otherwise, return the actual stored status, or default to Scheduled if null.
    return deliveryStatus ?? deliveryStatusToString(DeliveryStatus.Scheduled);
  }


  Map<String, dynamic> toJson() { 
    return {
      'shipper_name': shipperName,
      'payment_status': paymentStatus, 
      'delivery_status': deliveryStatus, 
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'pickup_date': pickupDate?.toIso8601String(),
      'estimated_delivery_date': estimatedDeliveryDate?.toIso8601String(),
      'actual_delivery_date': actualDeliveryDate?.toIso8601String(),
      'agreed_price': agreedPrice,
      'notes': notes,
      'created_by': createdBy, 
      'receipt_url': receiptUrl,
      // id, created_at, updated_at are typically handled by Supabase
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
