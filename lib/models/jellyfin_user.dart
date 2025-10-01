class JellyfinUser {
  final String id;
  final String name;
  final String? primaryImageTag;

  JellyfinUser({
    required this.id,
    required this.name,
    this.primaryImageTag,
  });

  factory JellyfinUser.fromJson(Map<String, dynamic> json) {
    return JellyfinUser(
      id: json['Id'] as String,
      name: json['Name'] as String,
      primaryImageTag: json['PrimaryImageTag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'PrimaryImageTag': primaryImageTag,
    };
  }
}
