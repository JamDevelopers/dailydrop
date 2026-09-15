import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../providers/auth_provider.dart';
import '../products/excel_import_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _gstController;
  late final TextEditingController _addressController;
  late final TextEditingController _watermarkController;
  late final TextEditingController _catalogTitleController;
  late final TextEditingController _waTemplateController;

  bool _watermarkEnabled = true;
  bool _showPricesPublicly = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final b = auth.business;
    final s = b.settings;

    _businessNameController = TextEditingController(text: b.name);
    _whatsappController = TextEditingController(text: b.whatsappNumber);
    _gstController = TextEditingController(text: b.gstNumber ?? '');
    _addressController = TextEditingController(text: b.addressLine1 ?? '');
    _watermarkController = TextEditingController(text: s.watermarkText);
    _catalogTitleController = TextEditingController(text: s.catalogTitle);
    _waTemplateController = TextEditingController(
      text: s.inquiryWhatsappTemplate,
    );

    _watermarkEnabled = s.watermarkEnabled;
    _showPricesPublicly = s.showPricesPublicly;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _whatsappController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _watermarkController.dispose();
    _catalogTitleController.dispose();
    _waTemplateController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final auth = context.read<AuthProvider>();

    auth.updateBusinessProfile(
      name: _businessNameController.text.trim(),
      whatsappNumber: _whatsappController.text.trim(),
      gstNumber: _gstController.text.trim(),
      address: _addressController.text.trim(),
    );

    auth.updateBusinessSettings(
      auth.business.settings.copyWith(
        watermarkEnabled: _watermarkEnabled,
        watermarkText: _watermarkController.text.trim(),
        catalogTitle: _catalogTitleController.text.trim(),
        inquiryWhatsappTemplate: _waTemplateController.text.trim(),
        showPricesPublicly: _showPricesPublicly,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: AppTheme.primaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final business = auth.business;
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Settings & SaaS Configuration'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check, color: AppTheme.primaryEmerald),
            label: const Text(
              'Save Changes',
              style: TextStyle(
                color: AppTheme.primaryEmerald,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: _saveSettings,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: MaxWidthContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role Context Switcher Card
              Card(
                color: AppTheme.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppTheme.primaryEmerald.withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        color: AppTheme.primaryEmerald,
                        size: 36,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Logged in as: ${user?.name ?? "User"} (${user?.roleDisplay})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Role Toggle
                      DropdownButton<String>(
                        value: user?.role == 'sales_staff'
                            ? 'sales_staff'
                            : 'owner',
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: 'owner',
                            child: Text('Switch: Owner View'),
                          ),
                          DropdownMenuItem(
                            value: 'sales_staff',
                            child: Text('Switch: Sales Staff'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) auth.switchRole(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Business Profile Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Textile Business Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText:
                              'Seller WhatsApp Number (For receiving inquiries)',
                          prefixIcon: Icon(Icons.chat_bubble_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _gstController,
                        decoration: const InputDecoration(
                          labelText: 'GST Number',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Shop / Market Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Watermark & Catalog Settings Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catalog & Photo Watermarking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Apply Watermark on Daily Drop Photos',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Protects your exclusive Surat design photos from unauthorized copy-paste.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _watermarkEnabled,
                        activeColor: AppTheme.primaryEmerald,
                        onChanged: (val) =>
                            setState(() => _watermarkEnabled = val),
                      ),
                      if (_watermarkEnabled) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _watermarkController,
                          decoration: const InputDecoration(
                            labelText: 'Watermark Text',
                            hintText: 'e.g. Surat Silk Mills',
                            prefixIcon: Icon(Icons.branding_watermark_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Show Prices Publicly in Catalog',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'When disabled, buyers see "Price on Request" and tap WhatsApp.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _showPricesPublicly,
                        activeColor: AppTheme.primaryEmerald,
                        onChanged: (val) =>
                            setState(() => _showPricesPublicly = val),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _catalogTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Public Catalog Header Tagline',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _waTemplateController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp Inquiry Message Template',
                          helperText:
                              'Variables: {product_code}, {collection_name}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data & Excel / CSV Catalog Import Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.table_chart_outlined,
                              color: AppTheme.primaryEmerald,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Excel & CSV Product / Drop Importer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Batch insert wholesale designs with fabrics, sizes, festivals, and multi-photos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppTheme.primaryEmerald,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Supported Excel headers: design_code, title, fabric, color, size, occasion, festival, set_count, price, cost_price, stock_quantity, stock_status, short_description, image_urls',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.file_upload_outlined,
                              size: 18,
                            ),
                            label: const Text('Launch Excel / CSV Importer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryEmerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const ExcelImportModal(),
                              );
                            },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.file_download_outlined,
                              size: 18,
                              color: AppTheme.primaryEmerald,
                            ),
                            label: const Text(
                              'Download / Copy Demo Template',
                              style: TextStyle(
                                color: AppTheme.primaryEmerald,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.primaryEmerald,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                const ClipboardData(
                                  text: ExcelImportModal.sampleCsvTemplate,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '✅ Sample Excel/CSV template copied to clipboard! Paste directly into Excel or Google Sheets.',
                                  ),
                                  backgroundColor: AppTheme.primaryDark,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SaaS Quota & Storage Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SaaS Subscription & Storage Quota',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Active Plan: Wholesaler Pro',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Storage Used: ${business.storageUsedMb} MB / 10,240 MB',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'ACTIVE TIER',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        child: LinearProgressIndicator(
                          value: 0.04,
                          minHeight: 8,
                          backgroundColor: AppTheme.backgroundLight,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save All Settings'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sign Out of Store',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () {
                  auth.logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
