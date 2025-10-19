import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NewPaymentDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onPaymentCreated;

  const NewPaymentDialog({
    super.key,
    required this.onPaymentCreated,
  });

  @override
  State<NewPaymentDialog> createState() => _NewPaymentDialogState();
}

class _NewPaymentDialogState extends State<NewPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedMerchant;
  String? _selectedProperty;
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _merchants = [
    {'id': 1, 'name': 'Boutique Fatou', 'property': 'Local A-12'},
    {'id': 2, 'name': 'Pharmacie Moderne', 'property': 'Local B-05'},
    {'id': 3, 'name': 'Restaurant Chez Marie', 'property': 'Local C-18'},
    {'id': 4, 'name': 'Coiffure Elegance', 'property': 'Local A-07'},
    {'id': 5, 'name': 'Épicerie du Coin', 'property': 'Local D-22'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 80.h,
          maxWidth: 90.w,
        ),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMerchantDropdown(),
                      SizedBox(height: 3.h),
                      _buildAmountField(),
                      SizedBox(height: 3.h),
                      _buildDateField(),
                      SizedBox(height: 3.h),
                      _buildDescriptionField(),
                      SizedBox(height: 4.h),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'payment',
            color: AppTheme.primaryGreen,
            size: 6.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'Nouveau Paiement',
              style: GoogleFonts.roboto(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CustomIconWidget(
              iconName: 'close',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Commerçant',
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          value: _selectedMerchant,
          decoration: InputDecoration(
            hintText: 'Sélectionner un commerçant',
            hintStyle: GoogleFonts.roboto(
              fontSize: 12.sp,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
          ),
          items: _merchants.map((merchant) {
            return DropdownMenuItem<String>(
              value: merchant['name'],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    merchant['name'],
                    style: GoogleFonts.roboto(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    merchant['property'],
                    style: GoogleFonts.roboto(
                      fontSize: 10.sp,
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMerchant = value;
              _selectedProperty =
                  _merchants.firstWhere((m) => m['name'] == value)['property'];
            });
          },
          validator: (value) {
            return value == null ? 'Veuillez sélectionner un commerçant' : null;
          },
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant (XOF)',
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: 'Entrer le montant',
            hintStyle: GoogleFonts.roboto(
              fontSize: 12.sp,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            prefixText: 'XOF ',
            prefixStyle: GoogleFonts.roboto(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
          ),
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un montant';
            }
            if (int.tryParse(value) == null) {
              return 'Veuillez entrer un montant valide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date d\'échéance',
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'calendar_today',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 5.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                  style: GoogleFonts.roboto(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (optionnel)',
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ajouter une description...',
            hintStyle: GoogleFonts.roboto(
              fontSize: 12.sp,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
          ),
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              side: BorderSide(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
            ),
            child: Text(
              'Annuler',
              style: GoogleFonts.roboto(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: ElevatedButton(
            onPressed: _createPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: EdgeInsets.symmetric(vertical: 2.h),
            ),
            child: Text(
              'Créer',
              style: GoogleFonts.roboto(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.surfaceWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _createPayment() {
    if (_formKey.currentState!.validate()) {
      final amount = int.parse(_amountController.text);
      final formattedAmount = '${amount.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]} ',
          )} XOF';

      final payment = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'merchantName': _selectedMerchant!,
        'propertyNumber': _selectedProperty!,
        'amount': formattedAmount,
        'dueDate':
            '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
        'status': 'pending',
        'description': _descriptionController.text.isEmpty
            ? 'Paiement de loyer'
            : _descriptionController.text,
        'createdAt': DateTime.now(),
      };

      widget.onPaymentCreated(payment);
      Navigator.pop(context);
    }
  }
}
