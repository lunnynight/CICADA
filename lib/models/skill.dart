// Unified Skill model for Cicada.
// Replaces the separate SkillModel and ClawHubSkill with a single type.

enum SkillSource { bundled, clawhub, github, local }

class Skill {
  final String slug;
  final String name;
  final String description;
  final String author;
  final String category;
  final String emoji;
  final String version;
  final SkillSource source;
  final bool isInstalled;
  final String? installedVersion;
  final double score;
  final int downloads;

  const Skill({
    required this.slug,
    required this.name,
    required this.description,
    this.author = '',
    this.category = '',
    this.emoji = '',
    this.version = '',
    this.source = SkillSource.local,
    this.isInstalled = false,
    this.installedVersion,
    this.score = 0,
    this.downloads = 0,
  });

  Skill copyWith({
    String? slug,
    String? name,
    String? description,
    String? author,
    String? category,
    String? emoji,
    String? version,
    SkillSource? source,
    bool? isInstalled,
    String? installedVersion,
    double? score,
    int? downloads,
  }) {
    return Skill(
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      version: version ?? this.version,
      source: source ?? this.source,
      isInstalled: isInstalled ?? this.isInstalled,
      installedVersion: installedVersion ?? this.installedVersion,
      score: score ?? this.score,
      downloads: downloads ?? this.downloads,
    );
  }

  bool get isBundled => source == SkillSource.bundled;
  bool get hasUpdate =>
      isInstalled &&
      installedVersion != null &&
      version.isNotEmpty &&
      installedVersion != version;

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? '',
      category: json['category'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      version: json['version'] as String? ?? '',
      source: _parseSource(json['source'] as String?),
      isInstalled: json['isInstalled'] as bool? ?? false,
      installedVersion: json['installedVersion'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      downloads: json['downloads'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
      'description': description,
      'author': author,
      'category': category,
      'emoji': emoji,
      'version': version,
      'source': source.name,
      'isInstalled': isInstalled,
      if (installedVersion != null) 'installedVersion': installedVersion,
      'score': score,
      'downloads': downloads,
    };
  }

  /// Convert from legacy ClawHubSkill catalog entry
  factory Skill.fromClawHub(Map<String, dynamic> entry) {
    return Skill(
      slug: entry['slug'] as String? ?? '',
      name: entry['name'] as String? ?? '',
      description: entry['description'] as String? ?? '',
      category: entry['category'] as String? ?? '',
      emoji: entry['emoji'] as String? ?? '',
      score: (entry['score'] as num?)?.toDouble() ?? 0,
      source: SkillSource.clawhub,
      author: 'ClawHub',
    );
  }

  static SkillSource _parseSource(String? s) {
    return switch (s) {
      'bundled' => SkillSource.bundled,
      'clawhub' => SkillSource.clawhub,
      'github' => SkillSource.github,
      _ => SkillSource.local,
    };
  }
}
