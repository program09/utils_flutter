enum RelationType { hasOne, hasMany, belongsTo, manyToMany }

class Relation {
  final RelationType type;
  final String targetTable;

  /// For belongsTo or hasMany
  final String? foreignKey;

  /// For hasMany or manyToMany
  final String? targetKey;

  /// For manyToMany
  final String? pivotTable;
  final String? sourcePivotKey;
  final String? targetPivotKey;

  Relation({
    required this.type,
    required this.targetTable,
    this.foreignKey,
    this.targetKey,
    this.pivotTable,
    this.sourcePivotKey,
    this.targetPivotKey,
  });

  /// Constructors de conveniencia
  factory Relation.hasMany(String targetTable, {required String foreignKey}) {
    return Relation(
      type: RelationType.hasMany,
      targetTable: targetTable,
      foreignKey: foreignKey,
    );
  }

  factory Relation.belongsTo(String targetTable, {required String foreignKey}) {
    return Relation(
      type: RelationType.belongsTo,
      targetTable: targetTable,
      foreignKey: foreignKey,
    );
  }

  factory Relation.manyToMany(
    String targetTable, {
    required String pivotTable,
    required String sourcePivotKey,
    required String targetPivotKey,
  }) {
    return Relation(
      type: RelationType.manyToMany,
      targetTable: targetTable,
      pivotTable: pivotTable,
      sourcePivotKey: sourcePivotKey,
      targetPivotKey: targetPivotKey,
    );
  }
}
