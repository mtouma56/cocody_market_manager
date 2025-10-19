class DashboardMockData {
  // Stats globales
  static const int totalLocaux = 500;
  static const int occupes = 425;
  static const int disponibles = 75;
  static const int inactifs = 12;
  static const double tauxOccupation = 85.0;

  // Encaissements
  static const double encaissementsJour = 2450000.0;
  static const double encaissementsSemaine = 14750000.0;
  static const double encaissementsMois = 58900000.0;
  static const String variationJour = "+12% vs hier";

  // Impayés
  static const double impayes = 1200000.0;
  static const int impayesNombre = 15;

  // Activité commerçants
  static const int commercantsActifs = 488;
  static const int commercantsTotal = 500;
  static const int commercantsInactifs = 12;
  static const double tauxActivite = 97.6;

  // Données graphiques - Tendance 7 jours (en millions)
  static const List<double> tendance7Jours = [
    1.8,
    2.1,
    1.9,
    2.3,
    2.0,
    2.4,
    2.5
  ];
  static const List<String> labelsTendance = [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim'
  ];

  // Encaissements par type de local
  static const Map<String, double> encaissementsParType = {
    'Magasin 9m²': 28.5,
    'Magasin 4.5m²': 14.2,
    'Restaurant': 8.9,
    'Box': 4.8,
    'Étal': 2.1,
    'Banque': 0.4,
  };

  // Stats détaillées par étage
  static const Map<String, Map<String, dynamic>> statsEtages = {
    'RDC': {
      'nom': 'RDC',
      'tauxOccupation': 92.0,
      'occupes': 120,
      'disponibles': 10,
      'total': 130,
      'types': {
        'Boutiques': {'occupes': 45, 'total': 50},
        'Restaurants': {'occupes': 30, 'total': 35},
        'Banques': {'occupes': 8, 'total': 10},
        'Services': {'occupes': 37, 'total': 35},
      }
    },
    '1er': {
      'nom': '1er étage',
      'tauxOccupation': 88.0,
      'occupes': 110,
      'disponibles': 15,
      'total': 125,
      'types': {
        'Magasins 9m²': {'occupes': 45, 'total': 50},
        'Magasins 4.5m²': {'occupes': 35, 'total': 40},
        'Box': {'occupes': 25, 'total': 30},
        'Bureaux': {'occupes': 5, 'total': 5},
      }
    },
    '2e': {
      'nom': '2e étage',
      'tauxOccupation': 80.0,
      'occupes': 96,
      'disponibles': 24,
      'total': 120,
      'types': {
        'Magasins': {'occupes': 40, 'total': 50},
        'Étals': {'occupes': 30, 'total': 35},
        'Box': {'occupes': 20, 'total': 25},
        'Stockage': {'occupes': 6, 'total': 10},
      }
    },
    '3e': {
      'nom': '3e étage',
      'tauxOccupation': 79.0,
      'occupes': 99,
      'disponibles': 26,
      'total': 125,
      'types': {
        'Étals': {'occupes': 35, 'total': 45},
        'Magasins': {'occupes': 25, 'total': 30},
        'Box': {'occupes': 20, 'total': 25},
        'Entrepôts': {'occupes': 19, 'total': 25},
      }
    },
  };

  // Couleurs pour les graphiques
  static const Map<String, int> couleursGraphiques = {
    'bleu': 0xFF2196F3,
    'vert': 0xFF4CAF50,
    'orange': 0xFFFF9800,
    'violet': 0xFF9C27B0,
    'jaune': 0xFFFFEB3B,
    'rouge': 0xFFF44336,
    'rouge_clair': 0xFFEF5350,
  };
}
