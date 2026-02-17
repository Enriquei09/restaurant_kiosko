/// Configuración del screensaver recibida del API.
class ScreensaverConfig {
  final bool enabled;
  final int timeoutSeconds;
  final int intervalSeconds;
  final String transition; // fade, slide, zoom
  final List<ScreensaverImage> images;

  const ScreensaverConfig({
    this.enabled = false,
    this.timeoutSeconds = 180,
    this.intervalSeconds = 5,
    this.transition = 'fade',
    this.images = const [],
  });

  factory ScreensaverConfig.fromJson(Map<String, dynamic> json) {
    return ScreensaverConfig(
      enabled: json['enabled'] ?? false,
      timeoutSeconds: json['timeout_seconds'] ?? 180,
      intervalSeconds: json['interval_seconds'] ?? 5,
      transition: json['transition'] ?? 'fade',
      images: (json['images'] as List?)
              ?.map((e) => ScreensaverImage.fromJson(e))
              .toList() ??
          [],
    );
  }

  bool get hasImages => images.isNotEmpty;
  bool get isActive => enabled && hasImages;
}

class ScreensaverImage {
  final int id;
  final String url;
  final String? thumbnail;
  final String? medium;
  final String? large;
  final int order;
  final String? name;

  const ScreensaverImage({
    required this.id,
    required this.url,
    this.thumbnail,
    this.medium,
    this.large,
    this.order = 0,
    this.name,
  });

  factory ScreensaverImage.fromJson(Map<String, dynamic> json) {
    return ScreensaverImage(
      id: json['id'],
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'],
      medium: json['medium'],
      large: json['large'],
      order: json['order'] ?? 0,
      name: json['name'],
    );
  }

  /// URL optimizada para pantalla completa.
  String get displayUrl => large ?? medium ?? url;
}
