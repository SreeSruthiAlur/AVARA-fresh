import 'package:avara_astrology_trial/models/finance_model.dart';
import 'package:avara_astrology_trial/services/avara_api_client.dart';
import 'package:avara_astrology_trial/services/finance_service.dart';
import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:avara_astrology_trial/theme/app_theme.dart';
import 'package:avara_astrology_trial/widgets/avara_surface_card.dart';
import 'package:flutter/material.dart';

/// Standard expense categories shared by the backend and the UI.
const List<String> kExpenseCategories = [
  'Food',
  'Transportation',
  'Shopping',
  'Education',
  'Entertainment',
  'Healthcare',
  'Bills',
  'Other',
];

/// Standard payment methods.
const List<String> kPaymentMethods = [
  'UPI',
  'Cash',
  'Card',
  'Net Banking',
  'Wallet',
  'Other',
];

/// Add-expense form screen.
///
/// Validates inputs locally before calling [FinanceService.addExpense].
/// On success shows a green [SnackBar] and pops back (`Navigator.pop(ctx, true)`)
/// so [FinanceScreen] knows to refresh the dashboard.
///
/// On [AvaraApiException] the error message surfaces in a red [SnackBar] and
/// the form stays open so the user can correct the input.
class FinanceAddExpenseScreen extends StatefulWidget {
  const FinanceAddExpenseScreen({super.key});

  @override
  State<FinanceAddExpenseScreen> createState() =>
      _FinanceAddExpenseScreenState();
}

class _FinanceAddExpenseScreenState extends State<FinanceAddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = kExpenseCategories.first;
  String _selectedPaymentMethod = kPaymentMethods.first;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Date picker
  // ---------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.deepNavy,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String get _formattedDate =>
      '${_selectedDate.year}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final expense = Expense(
      amount: double.parse(_amountController.text.trim()),
      category: _selectedCategory,
      date: _formattedDate,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      paymentMethod: _selectedPaymentMethod,
    );

    try {
      final saved = await FinanceService.instance.addExpense(expense);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense added successfully'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      // Pop back with the saved Expense so FinanceScreen can inject it
      // into the transaction list immediately (no full-reload spinner).
      Navigator.of(context).pop(saved);
    } on AvaraApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected error. Please try again.'),
          backgroundColor: Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Expense',
            style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.deepNavy),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AvaraSurfaceCard(
                  backgroundColor: AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountField(context),
                      const SizedBox(height: 16),
                      _buildCategoryDropdown(context),
                      const SizedBox(height: 16),
                      _buildDatePicker(context),
                      const SizedBox(height: 16),
                      _buildPaymentMethodDropdown(context),
                      const SizedBox(height: 16),
                      _buildDescriptionField(context),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Save Expense'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Form fields
  // ---------------------------------------------------------------------------

  Widget _buildAmountField(BuildContext context) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Amount (₹)',
        hintText: '0.00',
        prefixIcon:
            Icon(Icons.currency_rupee, color: AppColors.secondaryText),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Amount is required';
        final n = double.tryParse(v.trim());
        if (n == null) return 'Enter a valid number';
        if (n <= 0) return 'Amount must be greater than 0';
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined,
            color: AppColors.secondaryText),
      ),
      items: kExpenseCategories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _selectedCategory = v);
      },
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today_outlined,
              color: AppColors.secondaryText),
        ),
        child: Text(
          _formattedDate,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPaymentMethod,
      decoration: const InputDecoration(
        labelText: 'Payment Method',
        prefixIcon:
            Icon(Icons.payment_outlined, color: AppColors.secondaryText),
      ),
      items: kPaymentMethods
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _selectedPaymentMethod = v);
      },
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    return TextFormField(
      controller: _descriptionController,
      textInputAction: TextInputAction.done,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Description (optional)',
        hintText: 'e.g. Lunch at Subway',
        prefixIcon: Icon(Icons.notes_outlined, color: AppColors.secondaryText),
      ),
    );
  }
}
