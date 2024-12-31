class Trip {
  String clientName;
  int contactNumber;
  String Date;
  String origin;
  String Destination;
  double amount;
  String paymentStatus;
  String description;

  Trip(
      {required this.clientName,
      required this.contactNumber,
      required this.Date,
      required this.origin,
      required this.Destination,
      required this.amount,
      required this.description,
      required this.paymentStatus});

  Map<String, dynamic> toJson() {
    return {
      'clientName': clientName,
      'contactNumber': contactNumber,
      'Date': Date,
      'origin': origin,
      'Destination': Destination,
      'amount': amount,
      'paymentStatus': paymentStatus,
      'description': description
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      clientName: json['clientName'],
      contactNumber: json['contactNumber'],
      Date: json['Date'],
      origin: json['origin'],
      Destination: json['Destination'],
      amount: json['amount'],
      paymentStatus: json['paymentStatus'],
      description: json['description'],
    );
  }
}
