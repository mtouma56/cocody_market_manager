import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PropertyInfoSectionWidget extends StatelessWidget {
  final Map<String, dynamic> local;
  final Map<String, dynamic>? bailActif;

  const PropertyInfoSectionWidget({
    super.key,
    required this.local,
    this.bailActif,
  });

  @override
  Widget build(BuildContext context) {
    final numero = local['numero'] ?? '';
    final type = local['types_locaux']?['nom'] ?? '';
    final etage = local['etages']?['nom'] ?? '';
    final surface = local['types_locaux']?['surface_m2'] ?? 0;
    final statut = local['statut'] ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations générales
          Card(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations générales',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3.w),
                  _InfoRow(
                    icon: Icons.location_city,
                    label: 'Numéro',
                    value: numero,
                  ),
                  _InfoRow(
                    icon: Icons.store,
                    label: 'Type',
                    value: type,
                  ),
                  _InfoRow(
                    icon: Icons.straighten,
                    label: 'Surface',
                    value: '${surface}m²',
                  ),
                  _InfoRow(
                    icon: Icons.layers,
                    label: 'Étage',
                    value: etage,
                  ),
                  _InfoRow(
                    icon: Icons.info,
                    label: 'Statut',
                    value: statut,
                    valueColor: _getStatusColor(statut),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 4.w),

          // Informations locataire (si bail actif)
          if (bailActif != null) ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locataire actuel',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3.w),
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Nom',
                      value: bailActif!['commercants']?['nom'] ?? 'N/A',
                    ),
                    _InfoRow(
                      icon: Icons.business,
                      label: 'Activité',
                      value: bailActif!['commercants']?['activite'] ?? 'N/A',
                    ),
                    _InfoRow(
                      icon: Icons.phone,
                      label: 'Contact',
                      value: bailActif!['commercants']?['contact'] ?? 'N/A',
                    ),
                    _InfoRow(
                      icon: Icons.payments,
                      label: 'Loyer mensuel',
                      value:
                          '${((bailActif!['montant_loyer'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} FCFA',
                    ),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Début de bail',
                      value: bailActif!['date_debut'] ?? 'N/A',
                    ),
                    _InfoRow(
                      icon: Icons.event,
                      label: 'Fin de bail',
                      value: bailActif!['date_fin'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Message si local disponible
            Card(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Local disponible',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            'Ce local n\'a pas de locataire actuel. Il est disponible à la location.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'Occupé':
        return Colors.green;
      case 'Disponible':
        return Colors.blue;
      case 'Maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.w),
      child: Row(
        children: [
          Icon(
            icon,
            size: 5.w,
            color: Colors.grey.shade600,
          ),
          SizedBox(width: 3.w),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
