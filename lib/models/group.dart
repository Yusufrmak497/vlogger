class Group {
  final String id;
  final String name;
  final String createdBy;
  final List<String> members;
  final String? lastVlog;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
    this.lastVlog,
    required this.createdAt,
  });
} 