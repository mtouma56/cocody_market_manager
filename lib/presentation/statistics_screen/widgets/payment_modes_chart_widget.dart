import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sizer/sizer.dart';

class PaymentModesChartWidget extends StatelessWidget {
  final Map<String, int> data;

  const PaymentModesChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        elevation: 2,
        child: Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart_outline,
                    size: 48, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Aucune donnée disponible',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final total = data.values.reduce((a, b) => a + b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.green, size: 24),
                SizedBox(width: 2.w),
                Text(
                  'Modes de paiement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.w),

            // Section principale avec graphique et légende
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  // Graphique pie - plus large et sans texte à l'intérieur
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 35,
                        sections: data.entries.map((e) {
                          final percentage = (e.value / total) * 100;
                          return PieChartSectionData(
                            value: e.value.toDouble(),
                            title: '', // Pas de texte dans le graphique
                            color: _getColorForMode(e.key),
                            radius: 55,
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  SizedBox(width: 4.w),

                  // Légende optimisée - plus d'espace
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.entries.map((e) {
                        final percentage = (e.value / total) * 100;
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 1.5.w),
                          padding: EdgeInsets.all(2.5.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              // Indicateur de couleur plus grand
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getColorForMode(e.key),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(width: 3.w),

                              // Nom du mode
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              // Valeurs dans une colonne
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _getColorForMode(e.key),
                                    ),
                                  ),
                                  Text(
                                    '${e.value}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Résumé en bas
            SizedBox(height: 4.w),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total des paiements',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'espèces':
        return Colors.green;
      case 'chèque':
        return Colors.blue;
      case 'mobile money':
        return Colors.orange;
      case 'virement':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
