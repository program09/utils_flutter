class User {
  final int id;
  final String name;
  final int age;
  User({required this.id, required this.name, required this.age});

  // de json a object
  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'], name: json['name'], age: json['age']);

  // de map a object
  factory User.fromMap(Map<String, dynamic> map) =>
      User(id: map['id'], name: map['name'], age: map['age']);

  // de objeto a map
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'age': age};

  @override
  String toString() => 'User(id: $id, name: $name, age: $age)';
}
