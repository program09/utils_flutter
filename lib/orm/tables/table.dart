import 'column.dart';
import 'relation.dart';

class Table {
  final String name;
  final List<Column> columns;
  final Map<String, Relation> relations;

  Table({required this.name, required this.columns, this.relations = const {}});

  String toSql() {
    final columnsSql = columns.map((e) => e.toSql()).join(', ');
    return 'CREATE TABLE IF NOT EXISTS $name ($columnsSql)';
  }
}
