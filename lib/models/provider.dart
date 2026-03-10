class ModelInfo {
  final String id;
  final String name;
  final int context;

  const ModelInfo({required this.id, required this.name, required this.context});

  factory ModelInfo.fromJson(Map<String, dynamic> json) => ModelInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        context: json['context'] as int,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'context': context};
}

class ProviderConfig {
  final String id;
  final String name;
  final String provider;
  final String description;
  final String apiBase;
  final List<ModelInfo> models;
  final String keyUrl;
  final String freeQuota;
  final String docs;

  const ProviderConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.description,
    required this.apiBase,
    required this.models,
    required this.keyUrl,
    required this.freeQuota,
    required this.docs,
  });

  factory ProviderConfig.fromJson(Map<String, dynamic> json) => ProviderConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        provider: json['provider'] as String,
        description: json['description'] as String,
        apiBase: json['apiBase'] as String,
        models: (json['models'] as List).map((m) => ModelInfo.fromJson(m)).toList(),
        keyUrl: json['keyUrl'] as String? ?? '',
        freeQuota: json['freeQuota'] as String? ?? '',
        docs: json['docs'] as String? ?? '',
      );
}
