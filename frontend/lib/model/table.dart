class Table {

  final int id;
  final int resaurantId;
  final int tableNumble;
  final int capacity;

  Table({required this.id, required this.resaurantId, required this.tableNumble, required this.capacity});

  factory Table.FromJson(Map<String, dynamic> json){
    return Table(
      id: json['id'],
      resaurantId: json['restaurant'],
      tableNumble: json['table_number'],
      capacity: json['capacity'],
    );
  }
}