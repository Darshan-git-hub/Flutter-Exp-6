class CodeSnippet {
  int? id;
  String title;
  String code;
  String language;
  String description;
  DateTime dateAdded;

  CodeSnippet({
    this.id,
    required this.title,
    required this.code,
    required this.language,
    required this.description,
    DateTime? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now();

  factory CodeSnippet.fromRow(Map<String, dynamic> row) {
    return CodeSnippet(
      id: row['id'],
      title: row['title'],
      code: row['code'],
      language: row['language'],
      description: row['description'],
      dateAdded: DateTime.parse(row['dateAdded']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'code': code,
      'language': language,
      'description': description,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }
}