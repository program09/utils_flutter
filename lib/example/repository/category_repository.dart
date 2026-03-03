import 'package:orm/example/models/category.model.dart';
import 'package:orm/orm/repository/base_repository.dart';

class CategoryRepository extends BaseRepository<Category> {
  CategoryRepository()
    : super(
        tableName: Category.tableName,
        fromMap: Category.fromMap,
        toMap: (cat) => cat.toMap(),
      );
}
