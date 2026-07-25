class PersonAlbum {
  const PersonAlbum({
    required this.id,
    required this.name,
    required this.referencePath,
    required this.yearsBack,
    required this.assetIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String referencePath;
  final int yearsBack;
  final List<String> assetIds;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'referencePath': referencePath,
        'yearsBack': yearsBack,
        'assetIds': assetIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PersonAlbum.fromJson(Map<String, dynamic> json) => PersonAlbum(
        id: json['id'] as String,
        name: json['name'] as String,
        referencePath: json['referencePath'] as String,
        yearsBack: json['yearsBack'] as int,
        assetIds: (json['assetIds'] as List<dynamic>).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
