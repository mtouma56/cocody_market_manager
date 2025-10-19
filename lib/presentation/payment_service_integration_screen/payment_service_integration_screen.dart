import 'package:flutter/material.dart';
import '../../services/paiements_service.dart';

class PaymentServiceIntegrationScreen extends StatefulWidget {
  const PaymentServiceIntegrationScreen({super.key});

  @override
  State<PaymentServiceIntegrationScreen> createState() =>
      _PaymentServiceIntegrationScreenState();
}

class _PaymentServiceIntegrationScreenState
    extends State<PaymentServiceIntegrationScreen> {
  final PaiementsService _service = PaiementsService();
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _testService() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Test en cours...';
    });

    try {
      // Test de récupération des paiements
      final paiements = await _service.getPaiements();

      // Test de recherche des baux actifs
      final baux = await _service.searchBauxActifs('');

      setState(() {
        _isLoading = false;
        _statusMessage =
            'Service opérationnel!\n'
            '${paiements.length} paiements trouvés\n'
            '${baux.length} baux actifs trouvés';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Integration Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.integration_instructions,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Service Integration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _testService,
                child: const Text('Tester le Service'),
              ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
