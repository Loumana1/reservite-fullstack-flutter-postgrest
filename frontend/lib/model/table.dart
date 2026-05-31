import 'dart:convert';

import '../core/services/api_client.dart';

class Table {

  final int id;
  final int resaurantId;
  final int tableNumble;
  final int capacity;

  Table({required this.id, required this.resaurantId, required this.tableNumble, required this.capacity});

  factory Table.fromJson(Map<String, dynamic> json){
    return Table(
      id: json['id'],
      resaurantId: json['restaurant'],
      tableNumble: json['table_number'],
      capacity: json['capacity'],
    );
  }

  static Future<Table> save(int? id, int restaurantId, int tableNumber, int capacity) async {
    final response = await ApiClient.post('save_table', body: json.encode({
      'table_id': ?id,
      'restaurant_id': restaurantId,
      'table_number': tableNumber,
      'capacity': capacity,
    }));
    if (response.statusCode == 200) {
      return Table.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to save table');
  }
}
