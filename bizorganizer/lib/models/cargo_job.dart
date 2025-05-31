import 'package:bizorganizer/models/status_constants.dart';
import 'package:hive/hive.dart';

// part 'cargo_job.g.dart'; // Not needed for manual adapter

// @HiveType(typeId: 0) // Annotations not needed for manual adapter
class CargoJob {
  final String? id;
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
      id: json['id'] as String?,
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

class CargoJobAdapter extends TypeAdapter<CargoJob> {
  @override
  final int typeId = 0;

  @override
  CargoJob read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CargoJob(
      id: fields[0] as String?,
      shipperName: fields[1] as String?,
      paymentStatus: fields[2] as String?,
      deliveryStatus: fields[3] as String?,
      pickupLocation: fields[4] as String?,
      dropoffLocation: fields[5] as String?,
      pickupDate: fields[6] == null ? null : DateTime.tryParse(fields[6] as String),
      estimatedDeliveryDate: fields[7] == null ? null : DateTime.tryParse(fields[7] as String),
      actualDeliveryDate: fields[8] == null ? null : DateTime.tryParse(fields[8] as String),
      agreedPrice: fields[9] as double?,
      notes: fields[10] as String?,
      updatedAt: fields[11] == null ? null : DateTime.tryParse(fields[11] as String),
      createdBy: fields[12] as String?,
      receiptUrl: fields[13] as String?,
      createdAt: fields[14] == null ? null : DateTime.tryParse(fields[14] as String),
    );
  }

  @override
  void write(BinaryWriter writer, CargoJob obj) {
    writer
      ..writeByte(15) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.shipperName)
      ..writeByte(2)
      ..write(obj.paymentStatus)
      ..writeByte(3)
      ..write(obj.deliveryStatus)
      ..writeByte(4)
      ..write(obj.pickupLocation)
      ..writeByte(5)
      ..write(obj.dropoffLocation)
      ..writeByte(6)
      ..write(obj.pickupDate?.toIso8601String())
      ..writeByte(7)
      ..write(obj.estimatedDeliveryDate?.toIso8601String())
      ..writeByte(8)
      ..write(obj.actualDeliveryDate?.toIso8601String())
      ..writeByte(9)
      ..write(obj.agreedPrice)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.updatedAt?.toIso8601String())
      ..writeByte(12)
      ..write(obj.createdBy)
      ..writeByte(13)
      ..write(obj.receiptUrl)
      ..writeByte(14)
      ..write(obj.createdAt?.toIso8601String());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CargoJobAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
