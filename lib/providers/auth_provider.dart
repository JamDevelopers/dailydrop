import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/business.dart';
import '../services/mock_data_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser = MockDataService.demoOwner;
  Business _business = MockDataService.demoBusiness;
  bool _isAuthenticated = true;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  Business get business => _business;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    if (email.contains('staff') || email.contains('amit')) {
      _currentUser = MockDataService.demoSalesStaff;
    } else {
      _currentUser = MockDataService.demoOwner;
    }
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> registerOwner({
    required String businessName,
    required String ownerName,
    required String email,
    required String password,
    required String whatsappNumber,
    String? city,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final slug = businessName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
    _business = _business.copyWith(
      name: businessName,
      ownerName: ownerName,
      email: email,
      whatsappNumber: whatsappNumber,
      slug: slug,
      city: city ?? 'Surat',
    );

    _currentUser = User(
      id: 1,
      businessId: 1,
      name: ownerName,
      email: email,
      phone: whatsappNumber,
      role: 'owner',
    );

    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void switchRole(String role) {
    if (_currentUser != null) {
      if (role == 'owner') {
        _currentUser = MockDataService.demoOwner;
      } else {
        _currentUser = MockDataService.demoSalesStaff;
      }
      notifyListeners();
    }
  }

  void updateBusinessSettings(BusinessSettings newSettings) {
    _business = _business.copyWith(settings: newSettings);
    notifyListeners();
  }

  void updateBusinessProfile({
    required String name,
    required String whatsappNumber,
    String? gstNumber,
    String? address,
    String? city,
  }) {
    _business = _business.copyWith(
      name: name,
      whatsappNumber: whatsappNumber,
      gstNumber: gstNumber,
      addressLine1: address,
      city: city ?? _business.city,
    );
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}

