// Delivery Statuses
enum DeliveryStatus {
  Scheduled,    // User can select
  InProgress,   // Internal status, potentially grouped with Scheduled for some views
  Delivered,    // User can select (formerly Completed)
  Cancelled,    // User can select
  Delayed,      // Automatic/derived (formerly Overdue)
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
  if (statusString == null || statusString.isEmpty) return null;
  String normalizedString = statusString.toLowerCase().replaceAll(' ', ''); // Handle "In Progress" vs "InProgress"

  for (DeliveryStatus status in DeliveryStatus.values) {
    if (status.name.toLowerCase() == normalizedString) {
      return status;
    }
    // Fallback for older Dart versions if .name is not available (less likely now)
    if (status.toString().split('.').last.toLowerCase() == normalizedString) {
      return status;
    }
  }
  
  // Handle common legacy or alternative string values explicitly if needed
  if (normalizedString == "completed") return DeliveryStatus.Delivered;
  if (normalizedString == "overdue") return DeliveryStatus.Delayed;
  if (normalizedString == "pending") return DeliveryStatus.Scheduled; // Example: mapping old 'pending' to 'Scheduled'

  print("Warning: Unknown DeliveryStatus string '$statusString' received.");
  return null; // Or return a default like DeliveryStatus.Scheduled if appropriate
}


// Payment Statuses (Unchanged as per task instructions)
enum PaymentStatus {
  Pending,
  Paid,
  Cancelled, 
  Refunded, 
  Overdue, 
  Partial, 
}

String paymentStatusToString(PaymentStatus status) {
  try {
    return status.name;
  } catch (e) {
    return status.toString().split('.').last;
  }
}

PaymentStatus? paymentStatusFromString(String? statusString) {
  if (statusString == null || statusString.isEmpty) return null;
  String normalizedString = statusString.toLowerCase();
  for (PaymentStatus status in PaymentStatus.values) {
    if (status.name.toLowerCase() == normalizedString) {
      return status;
    }
    if (status.toString().split('.').last.toLowerCase() == normalizedString) {
      return status;
    }
  }
  print("Warning: Unknown PaymentStatus string '$statusString' received.");
  return null; 
}
