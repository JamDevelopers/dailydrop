import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/contact.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';

class AddEditContactModal extends StatefulWidget {
  final Contact? contact;

  const AddEditContactModal({super.key, this.contact});

  @override
  State<AddEditContactModal> createState() => _AddEditContactModalState();
}

class _AddEditContactModalState extends State<AddEditContactModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _cityController;
  late final TextEditingController _tagsController;

  String _contactType = 'buyer';
  String _preferredLang = 'hi';

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _phoneController = TextEditingController(text: c?.phoneE164 ?? '');
    _nameController = TextEditingController(text: c?.name ?? '');
    _companyController = TextEditingController(text: c?.companyName ?? '');
    _cityController = TextEditingController(text: c?.city ?? '');
    _tagsController = TextEditingController(text: c?.tags.join(', ') ?? '');

    if (c?.contactType != null) _contactType = c!.contactType;
    if (c?.preferredLanguage != null) _preferredLang = c!.preferredLanguage;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _cityController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _saveContact() {
    if (_formKey.currentState?.validate() ?? false) {
      final auth = context.read<AuthProvider>();
      final contactProvider = context.read<ContactProvider>();

      final tagList = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (widget.contact != null) {
        final updated = widget.contact!.copyWith(
          phoneE164: _phoneController.text.trim(),
          name: _nameController.text.trim(),
          companyName: _companyController.text.trim(),
          city: _cityController.text.trim(),
          contactType: _contactType,
          preferredLanguage: _preferredLang,
          tags: tagList,
        );
        contactProvider.updateContact(updated);
      } else {
        contactProvider.addContact(
          businessId: auth.business.id,
          phoneE164: _phoneController.text.trim(),
          name: _nameController.text.trim(),
          companyName: _companyController.text.trim(),
          city: _cityController.text.trim(),
          contactType: _contactType,
          preferredLanguage: _preferredLang,
          tags: tagList,
        );
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.contact != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_add_rounded, color: AppTheme.primaryEmerald),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Buyer Contact' : 'Add New Buyer to CRM',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Phone Number *',
                    hintText: 'e.g. +91 98765 43210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (val) =>
                      val == null || val.length < 10 ? 'Enter valid phone number' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company / Shop Name',
                    hintText: 'e.g. Riya Boutique',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City (e.g. Ahmedabad)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _contactType,
                        decoration: const InputDecoration(labelText: 'Buyer Type'),
                        items: const [
                          DropdownMenuItem(value: 'buyer', child: Text('Direct Buyer')),
                          DropdownMenuItem(value: 'dealer', child: Text('Dealer')),
                          DropdownMenuItem(value: 'reseller', child: Text('Reseller')),
                          DropdownMenuItem(value: 'boutique', child: Text('Boutique')),
                          DropdownMenuItem(value: 'retailer', child: Text('Retailer')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _contactType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _preferredLang,
                  decoration: const InputDecoration(labelText: 'Preferred Language'),
                  items: const [
                    DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                    DropdownMenuItem(value: 'gu', child: Text('Gujarati')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _preferredLang = val);
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (Comma separated)',
                    hintText: 'e.g. Silk Sarees, Regular Buyer, Bulk',
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _saveContact,
                  child: Text(isEdit ? 'Save Changes' : 'Add to Buyer CRM'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

