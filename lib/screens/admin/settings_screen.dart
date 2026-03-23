import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _storeNameController;
  late TextEditingController _upiController;
  late TextEditingController _upiNameController;
  late int _threshold;
  late String _currency;
  late double _taxRate;
  late TextEditingController _ownerNameController;
  late TextEditingController _ownerEmailController;
  late TextEditingController _ownerPhoneController;
  late TextEditingController _openAIController;
  late TextEditingController _githubTokenController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _storeNameController = TextEditingController(text: state.storeName);
    _upiController = TextEditingController(text: state.upiId);
    _upiNameController = TextEditingController(text: state.upiName);
    _openAIController = TextEditingController(text: state.openAIApiKey);
    _githubTokenController = TextEditingController(text: state.githubToken);
    _threshold = state.globalThreshold;
    _currency = state.currency;
    _taxRate = state.taxRate;
    _ownerNameController = TextEditingController(text: state.ownerProfile['name']);
    _ownerEmailController = TextEditingController(text: state.ownerProfile['email']);
    _ownerPhoneController = TextEditingController(text: state.ownerProfile['phone']);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Admin Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _sectionHeader('Store Identity'),
          _buildCard(context, [
            _buildTextField(
              controller: _storeNameController,
              label: 'Store Name',
              icon: LucideIcons.store,
            ),
            const Divider(height: 1),
            _buildTextField(
              controller: _upiController,
              label: 'UPI ID (for QR Payments)',
              icon: LucideIcons.qrCode,
              hint: 'e.g. yourname@bank',
            ),
            const Divider(height: 1),
            _buildTextField(
              controller: _upiNameController,
              label: 'Payee Name (displayed on QR)',
              icon: LucideIcons.user,
            ),
          ]),
          const SizedBox(height: 32),

          _sectionHeader('Owner Information'),
          _buildCard(context, [
            _buildTextField(
              controller: _ownerNameController,
              label: 'Owner Full Name',
              icon: LucideIcons.user,
            ),
            const Divider(height: 1),
            _buildTextField(
              controller: _ownerEmailController,
              label: 'Owner Email',
              icon: LucideIcons.mail,
            ),
            const Divider(height: 1),
            _buildTextField(
              controller: _ownerPhoneController,
              label: 'Owner Phone',
              icon: LucideIcons.phone,
            ),
          ]),
          const SizedBox(height: 32),

          _sectionHeader('Inventory Logic'),
          _buildCard(context, [
            _buildDropdownTile(
              label: 'Low Stock Threshold',
              subtitle: 'Trigger alerts when stock falls below this',
              icon: LucideIcons.alertTriangle,
              value: '$_threshold Units',
              onTap: () => _showThresholdPicker(context),
            ),
            const Divider(height: 32),
            _buildDropdownTile(
              label: 'Default Currency',
              subtitle: 'Symbol used across all reports',
              icon: LucideIcons.indianRupee,
              value: _currency,
              onTap: () => _showCurrencyPicker(context),
            ),
            const Divider(height: 32),
            _buildDropdownTile(
              label: 'Tax (GST/VAT) rate',
              subtitle: 'Applied to all taxable billing',
              icon: LucideIcons.percent,
              value: '${_taxRate.toInt()}%',
              onTap: () => _showTaxPicker(context),
            ),
          ]),
          const SizedBox(height: 32),

          const SizedBox(height: 32),

          _sectionHeader('AI Configuration'),
          _buildCard(context, [
            _buildTextField(
              controller: _openAIController,
              label: 'OpenAI API Key',
              icon: LucideIcons.bot,
              hint: 'sk-xxxxxxxxxxxxxxxxxxxxxxxx',
              obscureText: true,
            ),
            _buildTextField(
              controller: _githubTokenController,
              label: 'GitHub Models Token',
              icon: LucideIcons.github,
              hint: 'ghp_xxxxxxxxxxxxxxxxxxxx',
              obscureText: true,
            ),
          ]),
          const SizedBox(height: 32),

          _sectionHeader('System Preferences'),
          _buildCard(context, [
            SwitchListTile(
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Toggle app visual theme', style: TextStyle(fontSize: 12)),
              secondary: Icon(state.themeMode == ThemeMode.dark ? LucideIcons.moon : LucideIcons.sun, color: AppTheme.primary),
              value: state.themeMode == ThemeMode.dark,
              onChanged: (v) => state.toggleTheme(),
            ),

          ]),
          const SizedBox(height: 48),

          ElevatedButton(
            onPressed: () {
              state.updateSettings(
                storeName: _storeNameController.text,
                upiId: _upiController.text,
                upiName: _upiNameController.text,
                globalThreshold: _threshold,
                currency: _currency,
                taxRate: _taxRate,
                openAIApiKey: _openAIController.text,
                githubToken: _githubTokenController.text,
                ownerName: _ownerNameController.text,
                ownerEmail: _ownerEmailController.text,
                ownerPhone: _ownerPhoneController.text,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Colors.green),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => _showResetConfirmation(context, state),
              child: const Text('Reset to Factory Defaults', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.withOpacity(0.8), letterSpacing: 1.2)),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.divider(context)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, String? hint, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdownTile({required String label, required String subtitle, required IconData icon, required String value, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: AppTheme.primary),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
          const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  void _showThresholdPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [5, 10, 15, 20, 50].map((t) => ListTile(
          title: Text('$t Units'),
          onTap: () {
            setState(() => _threshold = t);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['₹', '\$', '€', '£'].map((c) => ListTile(
          title: Text(c == '₹' ? 'INR (₹)' : c == '\$' ? 'USD (\$)' : c),
          onTap: () {
            setState(() => _currency = c);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }



  void _showTaxPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [0.0, 5.0, 12.0, 18.0, 28.0].map((t) => ListTile(
          title: Text('${t.toInt()}%'),
          onTap: () {
            setState(() => _taxRate = t);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App Data?'),
        content: const Text('This will clear all inventory and sales data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              // Implementation of clear boxes
              Navigator.pop(context);
            }, 
            child: const Text('RESET ALL', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}
