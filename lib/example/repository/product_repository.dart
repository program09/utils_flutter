import 'package:orm/example/models/product.model.dart';
import 'package:orm/orm/repository/base_repository.dart';

class ProductRepository extends BaseRepository<Product> {
  ProductRepository()
    : super(
        tableName: Product.tableName,
        fromMap: Product.fromMap,
        toMap: (p) => p.toMap(),
      );

  Future<List<Product>> getByCategory(int categoryId) async {
    return await createBuilder().where('category_id = ?', [
      categoryId,
    ]).toList();
  }
}
