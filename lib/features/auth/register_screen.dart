import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController(text: 'Ambaji Fashion Surat');
  final _ownerNameController = TextEditingController(text: 'Hiteshbhai Chovatiya');
  final _whatsappController = TextEditingController(text: '9825099887');
  final _emailController = TextEditingController(text: 'contact@ambajifashion.com');
  final _passwordController = TextEditingController(text: 'Surat@2026');
  String _selectedMarket = AppConstants.suratMarkets.first;

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      final auth = context.read<AuthProvider>();
      final success = await auth.registerOwner(
        businessName: _businessNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        whatsappNumber: _whatsappController.text.trim(),
        city: 'Surat',
      );

      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Register Textile Business'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Start Your TextileDrop SaaS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Publish daily drops, generate auto design codes, and track WhatsApp inquiries.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: 'Business / Shop Name *',
                          hintText: 'e.g. Shree Radhe Textiles',
                          prefixIcon: Icon(Icons.store_outlined),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Enter business name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _ownerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Owner / Contact Person *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Enter owner name' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp Business Number *',
                          hintText: 'e.g. 9825123456 (For buyer inquiries)',
                          prefixIcon: Icon(Icons.chat_bubble_outline),
                        ),
                        validator: (val) => val == null || val.length < 10
                            ? 'Enter 10-digit WhatsApp number'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _selectedMarket,
                        decoration: const InputDecoration(
                          labelText: 'Textile Market / Location',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        items: AppConstants.suratMarkets.map((market) {
                          return DropdownMenuItem(
                            value: market,
                            child: Text(market, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMarket = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Login Email Address *',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (val) =>
                            val == null || !val.contains('@') ? 'Enter valid email' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password *',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (val) =>
                            val == null || val.length < 6 ? 'Minimum 6 chars' : null,
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleRegister,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create Store & Start 14-Day Free Trial'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

