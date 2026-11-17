class ProcessedImages {
  final String? preprocess;
  final String? segmentation;
  final String? reconstruction;

  const ProcessedImages({
    this.preprocess,
    this.segmentation,
    this.reconstruction,
  });

  factory ProcessedImages.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProcessedImages();
    return ProcessedImages(
      preprocess: json['preprocess']?.toString(),
      segmentation: json['segmentation']?.toString(),
      reconstruction: json['reconstruction']?.toString(),
    );
  }

  bool get hasAnyImage =>
      (preprocess != null && preprocess!.trim().isNotEmpty) ||
      (segmentation != null && segmentation!.trim().isNotEmpty) ||
      (reconstruction != null && reconstruction!.trim().isNotEmpty);
}

class PredictionRecommendation {
  final String? nama;
  final String? tingkatPerhatian;
  final String? kemungkinanPenyebab;
  final String? tindakanSegera;
  final String? budidaya;
  final String? hayati;
  final String? kimia;
  final String? pemantauan;

  const PredictionRecommendation({
    this.nama,
    this.tingkatPerhatian,
    this.kemungkinanPenyebab,
    this.tindakanSegera,
    this.budidaya,
    this.hayati,
    this.kimia,
    this.pemantauan,
  });

  factory PredictionRecommendation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PredictionRecommendation();
    return PredictionRecommendation(
      nama: json['nama']?.toString(),
      tingkatPerhatian: json['tingkat_perhatian']?.toString(),
      kemungkinanPenyebab: json['kemungkinan_penyebab']?.toString(),
      tindakanSegera: json['tindakan_segera']?.toString(),
      budidaya: json['budidaya']?.toString(),
      hayati: json['hayati']?.toString(),
      kimia: json['kimia']?.toString(),
      pemantauan: json['pemantauan']?.toString(),
    );
  }

  bool get hasAnyField =>
      (nama != null && nama!.trim().isNotEmpty) ||
      (tingkatPerhatian != null && tingkatPerhatian!.trim().isNotEmpty) ||
      (kemungkinanPenyebab != null && kemungkinanPenyebab!.trim().isNotEmpty) ||
      (tindakanSegera != null && tindakanSegera!.trim().isNotEmpty) ||
      (budidaya != null && budidaya!.trim().isNotEmpty) ||
      (hayati != null && hayati!.trim().isNotEmpty) ||
      (kimia != null && kimia!.trim().isNotEmpty) ||
      (pemantauan != null && pemantauan!.trim().isNotEmpty);
}

class PredictionItem {
  final String? historyId;
  final String? imagePath;
  final String? processedAt;
  final String? status;
  final String? prediction;
  final String? confidence;
  final double? margin;
  final double? maskRatio;
  final Map<String, dynamic>? scores;
  final ProcessedImages processedImages;
  final PredictionRecommendation recommendation;

  const PredictionItem({
    this.historyId,
    this.imagePath,
    this.processedAt,
    this.status,
    this.prediction,
    this.confidence,
    this.margin,
    this.maskRatio,
    this.scores,
    this.processedImages = const ProcessedImages(),
    this.recommendation = const PredictionRecommendation(),
  });

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  factory PredictionItem.fromJson(Map<String, dynamic> json) {
    return PredictionItem(
      historyId: json['history_id']?.toString(),
      imagePath: json['image_path']?.toString(),
      processedAt: json['processed_at']?.toString(),
      status: json['status']?.toString(),
      prediction: json['prediction']?.toString(),
      confidence: json['confidence']?.toString(),
      margin: _parseDouble(json['margin']),
      maskRatio: _parseDouble(json['mask_ratio']),
      scores: json['scores'] is Map ? (json['scores'] as Map).cast<String, dynamic>() : null,
      processedImages: ProcessedImages.fromJson(
        json['processed_images'] is Map ? (json['processed_images'] as Map).cast<String, dynamic>() : null,
      ),
      recommendation: PredictionRecommendation.fromJson(
        json['recommendation'] is Map ? (json['recommendation'] as Map).cast<String, dynamic>() : null,
      ),
    );
  }
}
