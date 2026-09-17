import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/services/api_client.dart';

class Table {

  final int id;
  final int resaurantId;
  final int tableNumble;
  final int capacity;
  final bool is_signature;

  Table({required this.id,
    required this.resaurantId,
    required this.tableNumble,
    required this.capacity,
    required this.is_signature});

  factory Table.fromJson(Map<String, dynamic> json){
    return Table(
      id: json['id'],
      resaurantId: json['restaurant'],
      tableNumble: json['table_number'],
      capacity: json['capacity'],
      is_signature: json['is_signature'] as bool,
    );
  }
  Future<Table> updateTableSponsor(bool isSponsor ) async {
    final r = await ApiClient.post('update_signature',
    body: json.encode({
      'table_id' : id,
      'newsignature': isSponsor,
    }));
    if(r.statusCode != 200){
      throw Exception(ApiClient.errorMessage(r));
    }

    return Table.fromJson(json.decode(r.body));
    
  }

  static Future<List<Table>> getByRestaurant(int restaurantId) async {
    final response = await ApiClient.post(
      'get_tables',
      body: json.encode({'restaurant_id': restaurantId}),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((e) => Table.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load tables');
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
    throw Exception(_errorMessage(response));
  }

  static String _errorMessage(http.Response response) {
    final raw = ApiClient.errorMessage(response).toLowerCase();
    
    if (raw.contains('br-2') || raw.contains('capacité') || raw.contains('capacity')) {
      return 'Impossible de réduire la capacité : des réservations confirmées l\'utilisent déjà.';
    }
    if (raw.contains('unique') || raw.contains('table_number')) {
      return 'Ce numéro de table existe déjà dans ce restaurant.';
    }
    if (raw.contains('permission denied') || raw.contains('accès refusé')) {
      return 'Accès refusé.';
    }
    
    return 'Erreur lors de la sauvegarde de la table.';
  }
}
