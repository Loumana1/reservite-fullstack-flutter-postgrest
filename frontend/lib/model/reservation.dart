class Reservation {
  const Reservation({
    required this.id,
    required this.clientId,
    required this.restaurantId,
    required this.datetime,
    required this.numberOfGuests,
    required this.status,
    this.specialRequests,
    this.restaurantName,
    this.restaurantCity,
  });

  final int id;
  final int clientId;
  final int restaurantId;
  final DateTime datetime;
  final int numberOfGuests;
  final String status;
  final String? specialRequests;
  final String? restaurantName;
  final String? restaurantCity;

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as int,
      clientId: json['client'] as int,
      restaurantId: json['restaurant'] as int,
      datetime: DateTime.parse(json['datetime'].toString()),
      numberOfGuests: json['number_of_guests'] as int,
      status: json['status'] as String,
      specialRequests: json['special_requests'] as String?,
      restaurantName: json['restaurant_name'] as String?,
      restaurantCity: json['restaurant_city'] as String?,
    );
  }

  bool get canEdit => status == 'pending' || status == 'confirmed';
  bool get canCancel => status == 'pending' || status == 'confirmed';
}