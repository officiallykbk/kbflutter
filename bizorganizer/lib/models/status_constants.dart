// Delivery Statuses
enum DeliveryStatus {
  Scheduled,
  InProgress, // Added based on typical cargo statuses
  OutForDelivery, // Added based on typical cargo statuses
  Completed,
  Cancelled,
  Delayed, // Added for when it's past ETA but not yet 'Overdue' in a business sense
  Onhold, // For jobs that are paused
  Rejected, // If a job is rejected
  Overdue, // Calculated status, but can also be an explicit status
  Pending, // Generic pending, often initial state
}

// Helper to get string value, or use extension .name in Dart 2.15+
String deliveryStatusToString(DeliveryStatus status) {
  // Using .name requires Dart 2.15+. If not available, use toString().split('.').last
  try {
    return status.name;
  } catch (e) {
    return status.toString().split('.').last;
  }
}

DeliveryStatus? deliveryStatusFromString(String? statusString) {
  if (statusString == null) return null;
  try {
    return DeliveryStatus.values.firstWhere((e) => e.name.toLowerCase() == statusString.toLowerCase());
  } catch (e) {
    // Fallback for older Dart versions or if .name is not robust for all cases
    try {
      return DeliveryStatus.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == statusString.toLowerCase());
    } catch (e) {
      return null; // Or a default status like DeliveryStatus.Pending
    }
  }
}


// Payment Statuses
enum PaymentStatus {
  Pending,
  Paid,
  Cancelled, // If a payment is cancelled
  Refunded, // Added as it's a common payment state
  Overdue, // If payment is past due date
  Partial, // For partial payments
}

String paymentStatusToString(PaymentStatus status) {
  try {
    return status.name;
  } catch (e) {
    return status.toString().split('.').last;
  }
}

PaymentStatus? paymentStatusFromString(String? statusString) {
  if (statusString == null) return null;
  try {
    return PaymentStatus.values.firstWhere((e) => e.name.toLowerCase() == statusString.toLowerCase());
  } catch (e) {
    try {
      return PaymentStatus.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == statusString.toLowerCase());
    } catch (e) {
      return null; // Or a default status like PaymentStatus.Pending
    }
  }
}
