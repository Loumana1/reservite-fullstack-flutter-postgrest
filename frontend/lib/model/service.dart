class Service {

  final int id;
  final int restaurantId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  Service({required this.id, required, required this.restaurantId, required this.dayOfWeek, required this.startTime, required this.endTime });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      restaurantId: json ['restaurantId'],
      dayOfWeek: json['dayOfWeek'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
}
}