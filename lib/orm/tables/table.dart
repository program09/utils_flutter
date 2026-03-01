import 'column.dart';

class Table {
  final String name;
  final List<Column> columns;

  Table({required this.name, required this.columns});

  String toSql() {
    final columnsSql = columns.map((e) => e.toSql()).join(', ');
    return 'CREATE TABLE IF NOT EXISTS $name ($columnsSql)';
  }
}
