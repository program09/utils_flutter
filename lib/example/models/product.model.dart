import 'package:orm/orm/tables/table.dart' as orm;
import 'package:orm/orm/tables/column.dart';
import 'package:orm/example/models/category.model.dart';

class Product {
  static const String tableName = 'products';

  static orm.Table get table => orm.Table(
    name: tableName,
    columns: [
      Column(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
      Column(name: 'name', type: ColumnType.text),
      Column(name: 'price', type: ColumnType.real),
      Column(
        name: 'category_id',
        type: ColumnType.integer,
        isForeignKey: true,
        referenceTable: Category.tableName,
        referenceColumn: 'id',
      ),
    ],
  );

  final int id;
  final String name;
  final double price;
  final int categoryId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      categoryId: map['category_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'price': price, 'category_id': categoryId};
  }
}
