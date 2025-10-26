import 'package:flutter/material.dart';

class DocumentFilterWidget extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const DocumentFilterWidget({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      _getFilterLabel(item),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getFilterLabel(String value) {
    switch (value) {
      case 'all':
        return 'Tous';
      case 'contract':
        return 'Contrats';
      case 'receipt':
        return 'Reçus';
      case 'photo':
        return 'Photos';
      case 'identity':
        return 'Pièces d\'identité';
      case 'other':
        return 'Autres';
      case 'commercant':
        return 'Commerçants';
      case 'local':
        return 'Locaux';
      case 'bail':
        return 'Baux';
      case 'paiement':
        return 'Paiements';
      default:
        return value;
    }
  }
}
