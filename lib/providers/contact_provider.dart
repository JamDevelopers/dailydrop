import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/inquiry_service.dart';

class ContactProvider extends ChangeNotifier {
  final InquiryService _service = InquiryService();

  List<Contact> _contacts = [];
  String? _selectedTypeFilter;
  String _searchQuery = '';

  ContactProvider() {
    _loadInitialData();
  }

  void _loadInitialData() {
    _contacts = _service.getContacts();
    notifyListeners();
  }

  List<Contact> get allContacts => _contacts;

  List<Contact> get filteredContacts {
    return _contacts.where((c) {
      if (_selectedTypeFilter != null && _selectedTypeFilter!.isNotEmpty) {
        if (c.contactType != _selectedTypeFilter) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchPhone = c.phoneE164.toLowerCase().contains(q);
        final matchName = (c.name ?? '').toLowerCase().contains(q);
        final matchCompany = (c.companyName ?? '').toLowerCase().contains(q);
        final matchCity = (c.city ?? '').toLowerCase().contains(q);
        if (!matchPhone && !matchName && !matchCompany && !matchCity) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String? get selectedTypeFilter => _selectedTypeFilter;
  String get searchQuery => _searchQuery;

  void setTypeFilter(String? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Contact addContact({
    required int businessId,
    required String phoneE164,
    String? name,
    String? companyName,
    String? city,
    String? state,
    String contactType = 'buyer',
    String preferredLanguage = 'hi',
    List<String> tags = const [],
  }) {
    final contact = _service.addContact(
      businessId: businessId,
      phoneE164: phoneE164,
      name: name,
      companyName: companyName,
      city: city,
      state: state,
      contactType: contactType,
      preferredLanguage: preferredLanguage,
      tags: tags,
    );
    _contacts = _service.getContacts();
    notifyListeners();
    return contact;
  }

  void updateContact(Contact contact) {
    _service.updateContact(contact);
    _contacts = _service.getContacts();
    notifyListeners();
  }

  void deleteContact(int id) {
    _service.deleteContact(id);
    _contacts = _service.getContacts();
    notifyListeners();
  }
}

