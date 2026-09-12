/// A server an app knows how to talk to.
///
/// [key] is what gets persisted, so keep it stable across releases;
/// [label] is what testers see; [baseUrl] is where requests go, including
/// the API prefix (`https://example.com/api`).
class ApiEnvironment {
  final String key;
  final String label;
  final String baseUrl;

  const ApiEnvironment({
    required this.key,
    required this.label,
    required this.baseUrl,
  });

  @override
  bool operator ==(Object other) =>
      other is ApiEnvironment && other.key == key && other.baseUrl == baseUrl;

  @override
  int get hashCode => Object.hash(key, baseUrl);

  @override
  String toString() => 'ApiEnvironment($key, $baseUrl)';
}
