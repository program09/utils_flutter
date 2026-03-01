//tipos de columnas
enum ColumnType {
  integer,
  text,
  real,
  blob,
  date,
  dateTime,
  time,
  timestamp,
  bool,
}

class Column {
  final String name;
  final ColumnType type;
  final bool? isPrimaryKey;
  final bool? isForeignKey;
  final String? referenceTable;
  final String? referenceColumn;
  final bool? isAutoIncrement;
  final bool? isNullable;
  final String? defaultValue;

  Column({
    required this.name,
    required this.type,
    this.isPrimaryKey = false,
    this.isForeignKey = false,
    this.referenceTable,
    this.referenceColumn,
    this.isAutoIncrement = false,
    this.isNullable = false,
    this.defaultValue,
  });

  String toSql() {
    String sql = '$name ${_getSqlType(type)}';
    if (isPrimaryKey == true) sql += ' PRIMARY KEY';
    if (isAutoIncrement == true) sql += ' AUTOINCREMENT';
    if (isNullable == false) sql += ' NOT NULL';
    if (defaultValue != null) sql += " DEFAULT '$defaultValue'";
    if (isForeignKey == true) {
      sql += ' REFERENCES $referenceTable($referenceColumn)';
    }
    return sql;
  }

  String _getSqlType(ColumnType type) {
    switch (type) {
      case ColumnType.integer:
      case ColumnType.bool:
      case ColumnType.date:
      case ColumnType.dateTime:
      case ColumnType.time:
      case ColumnType.timestamp:
        return 'INTEGER';
      case ColumnType.text:
        return 'TEXT';
      case ColumnType.real:
        return 'REAL';
      case ColumnType.blob:
        return 'BLOB';
    }
  }
}
