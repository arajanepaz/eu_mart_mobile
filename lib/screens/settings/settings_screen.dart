import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storePhoneController = TextEditingController();
  final TextEditingController _storeAddressController = TextEditingController();
  final TextEditingController _receiptFooterController =
      TextEditingController();
  final TextEditingController _lowStockThresholdController =
      TextEditingController();
  final TextEditingController _expirationAlertDaysController =
      TextEditingController();
  final TextEditingController _feedbackUrlController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>> get _settingsDocument =>
      FirebaseFirestore.instance.collection('settings').doc('general');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final snapshot = await _settingsDocument.get();
      final data = snapshot.data() ?? <String, dynamic>{};

      _storeNameController.text = (data['storeName'] ?? 'EÜ MART').toString();
      _storePhoneController.text = (data['storePhone'] ?? '').toString();
      _storeAddressController.text = (data['storeAddress'] ?? '').toString();
      _receiptFooterController.text =
          (data['receiptFooter'] ?? 'Thank you for shopping at EÜ MART!')
              .toString();
      _lowStockThresholdController.text =
          ((data['lowStockThreshold'] as num?)?.toInt() ?? 10).toString();
      _expirationAlertDaysController.text =
          ((data['expirationAlertDays'] as num?)?.toInt() ?? 7).toString();
      _feedbackUrlController.text = (data['feedbackUrl'] ?? '').toString();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load settings: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _settingsDocument.set({
        'storeName': _storeNameController.text.trim(),
        'storePhone': _storePhoneController.text.trim(),
        'storeAddress': _storeAddressController.text.trim(),
        'receiptFooter': _receiptFooterController.text.trim(),
        'lowStockThreshold': int.parse(
          _lowStockThresholdController.text.trim(),
        ),
        'expirationAlertDays': int.parse(
          _expirationAlertDaysController.text.trim(),
        ),
        'feedbackUrl': _feedbackUrlController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save settings: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    final int? number = int.tryParse(value.trim());

    if (number == null || number < 0) {
      return 'Enter a valid non-negative number.';
    }
    return null;
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: colors.primaryContainer,
          child: Icon(icon, color: colors.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Appearance', Icons.palette_outlined),
                    const SizedBox(height: 12),
                    _card([
                      AnimatedBuilder(
                        animation: themeController,
                        builder: (context, _) {
                          return SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(
                              themeController.isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                            ),
                            title: const Text(
                              'Dark Mode',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              themeController.isDarkMode
                                  ? 'Dark appearance is enabled.'
                                  : 'Light appearance is enabled.',
                            ),
                            value: themeController.isDarkMode,
                            onChanged: themeController.setDarkMode,
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _sectionTitle('Store Information', Icons.store),
                    const SizedBox(height: 12),
                    _card([
                      TextFormField(
                        controller: _storeNameController,
                        validator: _requiredValidator,
                        decoration: _decoration(
                          label: 'Store Name',
                          icon: Icons.storefront_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _storePhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _decoration(
                          label: 'Store Phone',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _storeAddressController,
                        maxLines: 2,
                        decoration: _decoration(
                          label: 'Store Address',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _sectionTitle(
                      'Inventory Alerts',
                      Icons.notifications_active_outlined,
                    ),
                    const SizedBox(height: 12),
                    _card([
                      TextFormField(
                        controller: _lowStockThresholdController,
                        keyboardType: TextInputType.number,
                        validator: _numberValidator,
                        decoration: _decoration(
                          label: 'Low Stock Threshold',
                          icon: Icons.warning_amber_rounded,
                          hint: 'Example: 10',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _expirationAlertDaysController,
                        keyboardType: TextInputType.number,
                        validator: _numberValidator,
                        decoration: _decoration(
                          label: 'Expiration Alert Days',
                          icon: Icons.event_busy_outlined,
                          hint: 'Example: 7',
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _sectionTitle('Receipt and Feedback', Icons.receipt_long),
                    const SizedBox(height: 12),
                    _card([
                      TextFormField(
                        controller: _receiptFooterController,
                        maxLines: 2,
                        decoration: _decoration(
                          label: 'Receipt Footer',
                          icon: Icons.notes_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _feedbackUrlController,
                        keyboardType: TextInputType.url,
                        decoration: _decoration(
                          label: 'Customer Feedback URL',
                          icon: Icons.link,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveSettings,
                        icon: _saving
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _saving ? 'Saving...' : 'Save Settings',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storePhoneController.dispose();
    _storeAddressController.dispose();
    _receiptFooterController.dispose();
    _lowStockThresholdController.dispose();
    _expirationAlertDaysController.dispose();
    _feedbackUrlController.dispose();
    super.dispose();
  }
}
