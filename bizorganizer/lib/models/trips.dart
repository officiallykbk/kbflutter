class Trip {
  String clientName;
  String contactNumber;
  String receipt;
  String date;
  String origin;
  String destination;
  double amount;
  String paymentStatus;
  String orderStatus;
  String description;

  Trip(
      {required this.clientName,
      required this.contactNumber,
      required this.receipt,
      required this.date,
      required this.origin,
      required this.destination,
      required this.amount,
      required this.description,
      required this.paymentStatus,
      this.orderStatus = 'pending'});

  Map<String, dynamic> toJson() {
    return {
      'clientName': clientName,
      'contactNumber': contactNumber,
      'receipt': receipt,
      'date': date,
      'origin': origin,
      'destination': destination,
      'amount': amount,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'description': description
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      clientName: json['clientName'],
      contactNumber: json['contactNumber'],
      receipt: json['receipt'],
      date: json['date'],
      origin: json['origin'],
      destination: json['destination'],
      amount: json['amount'],
      paymentStatus: json['paymentStatus'],
      orderStatus: json['orderStatus'],
      description: json['description'],
    );
  }
}
