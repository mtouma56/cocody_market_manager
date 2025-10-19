class DashboardStats {
  final int totalLocaux;
  final int occupes;
  final int disponibles;
  final int inactifs;
  final double tauxOccupation;
  final double encaissementsJour;
  final double encaissementsSemaine;
  final double encaissementsMois;
  final double impayes;
  final int impayesNombre;
  final int commercantsActifs;
  final int commercantsTotal;

  const DashboardStats({
    required this.totalLocaux,
    required this.occupes,
    required this.disponibles,
    required this.inactifs,
    required this.tauxOccupation,
    required this.encaissementsJour,
    required this.encaissementsSemaine,
    required this.encaissementsMois,
    required this.impayes,
    required this.impayesNombre,
    required this.commercantsActifs,
    required this.commercantsTotal,
  });

  // Legacy constructor for backward compatibility
  factory DashboardStats.legacy({
    required int totalLocaux,
    required int occupes,
    required int disponibles,
    required int inactifs,
    required double tauxOccupation,
    required double encaissements,
    required double impayes,
    required int commercants,
  }) {
    return DashboardStats(
      totalLocaux: totalLocaux,
      occupes: occupes,
      disponibles: disponibles,
      inactifs: inactifs,
      tauxOccupation: tauxOccupation,
      encaissementsJour: encaissements,
      encaissementsSemaine: encaissements,
      encaissementsMois: encaissements,
      impayes: impayes,
      impayesNombre: 0,
      commercantsActifs: commercants,
      commercantsTotal: commercants,
    );
  }

  // Backward compatibility getter
  double get encaissements => encaissementsJour;
  int get commercants => commercantsActifs;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalLocaux: json['total_locaux'] ?? 0,
      occupes: json['occupes'] ?? 0,
      disponibles: json['disponibles'] ?? 0,
      inactifs: json['inactifs'] ?? 0,
      tauxOccupation: (json['taux_occupation'] ?? 0.0).toDouble(),
      encaissementsJour: (json['encaissements_jour'] ?? 0.0).toDouble(),
      encaissementsSemaine: (json['encaissements_semaine'] ?? 0.0).toDouble(),
      encaissementsMois: (json['encaissements_mois'] ?? 0.0).toDouble(),
      impayes: (json['impayes'] ?? 0.0).toDouble(),
      impayesNombre: json['impayes_nombre'] ?? 0,
      commercantsActifs: json['commercants_actifs'] ?? 0,
      commercantsTotal: json['commercants_total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_locaux': totalLocaux,
      'occupes': occupes,
      'disponibles': disponibles,
      'inactifs': inactifs,
      'taux_occupation': tauxOccupation,
      'encaissements_jour': encaissementsJour,
      'encaissements_semaine': encaissementsSemaine,
      'encaissements_mois': encaissementsMois,
      'impayes': impayes,
      'impayes_nombre': impayesNombre,
      'commercants_actifs': commercantsActifs,
      'commercants_total': commercantsTotal,
    };
  }

  DashboardStats copyWith({
    int? totalLocaux,
    int? occupes,
    int? disponibles,
    int? inactifs,
    double? tauxOccupation,
    double? encaissementsJour,
    double? encaissementsSemaine,
    double? encaissementsMois,
    double? impayes,
    int? impayesNombre,
    int? commercantsActifs,
    int? commercantsTotal,
  }) {
    return DashboardStats(
      totalLocaux: totalLocaux ?? this.totalLocaux,
      occupes: occupes ?? this.occupes,
      disponibles: disponibles ?? this.disponibles,
      inactifs: inactifs ?? this.inactifs,
      tauxOccupation: tauxOccupation ?? this.tauxOccupation,
      encaissementsJour: encaissementsJour ?? this.encaissementsJour,
      encaissementsSemaine: encaissementsSemaine ?? this.encaissementsSemaine,
      encaissementsMois: encaissementsMois ?? this.encaissementsMois,
      impayes: impayes ?? this.impayes,
      impayesNombre: impayesNombre ?? this.impayesNombre,
      commercantsActifs: commercantsActifs ?? this.commercantsActifs,
      commercantsTotal: commercantsTotal ?? this.commercantsTotal,
    );
  }
}

class OccupationEtage {
  final String etage;
  final int total;
  final int occupes;
  final int disponibles;
  final double taux;

  const OccupationEtage({
    required this.etage,
    required this.total,
    required this.occupes,
    required this.disponibles,
    required this.taux,
  });

  factory OccupationEtage.fromJson(Map<String, dynamic> json) {
    return OccupationEtage(
      etage: json['etage'] ?? '',
      total: json['total'] ?? 0,
      occupes: json['occupes'] ?? 0,
      disponibles: json['disponibles'] ?? 0,
      taux: (json['taux'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etage': etage,
      'total': total,
      'occupes': occupes,
      'disponibles': disponibles,
      'taux': taux,
    };
  }

  OccupationEtage copyWith({
    String? etage,
    int? total,
    int? occupes,
    int? disponibles,
    double? taux,
  }) {
    return OccupationEtage(
      etage: etage ?? this.etage,
      total: total ?? this.total,
      occupes: occupes ?? this.occupes,
      disponibles: disponibles ?? this.disponibles,
      taux: taux ?? this.taux,
    );
  }
}

class TendanceData {
  final DateTime date;
  final double montant;

  const TendanceData({required this.date, required this.montant});

  factory TendanceData.fromJson(Map<String, dynamic> json) {
    return TendanceData(
      date: DateTime.parse(json['date']),
      montant: (json['montant'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'montant': montant};
  }

  TendanceData copyWith({DateTime? date, double? montant}) {
    return TendanceData(
      date: date ?? this.date,
      montant: montant ?? this.montant,
    );
  }
}

class EncaissementType {
  final String type;
  final double montant;

  const EncaissementType({required this.type, required this.montant});

  factory EncaissementType.fromJson(Map<String, dynamic> json) {
    return EncaissementType(
      type: json['type'] ?? '',
      montant: (json['montant'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'montant': montant};
  }

  EncaissementType copyWith({String? type, double? montant}) {
    return EncaissementType(
      type: type ?? this.type,
      montant: montant ?? this.montant,
    );
  }
}
