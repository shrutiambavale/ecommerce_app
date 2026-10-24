import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/address_model.dart';

class AddressRepository {
  final _addressesController = StreamController<List<AddressModel>>.broadcast();
  final List<AddressModel> _localAddresses = [];

  AddressRepository() {
    _emitAddresses();
  }

  Stream<List<AddressModel>> getAddresses(String userId) async* {
    yield _localAddresses.where((a) => a.userId == userId).toList();

    if (FirebaseService.isFirebaseAvailable) {
      FirebaseService.firestore
          ?.collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.addressesCollection)
          .snapshots()
          .listen((snapshot) {
        final list = <AddressModel>[];
        for (final doc in snapshot.docs) {
          try {
            list.add(AddressModel.fromMap(doc.data(), doc.id));
          } catch (e) {
            debugPrint('Error parsing address ${doc.id}: $e');
          }
        }
        _localAddresses.removeWhere((a) => a.userId == userId);
        _localAddresses.addAll(list);
        _addressesController.add(List.from(_localAddresses));
      }, onError: (e) {
        debugPrint('Address stream error: $e');
      });
    }
    yield* _addressesController.stream
        .map((all) => all.where((a) => a.userId == userId).toList());
  }

  Future<List<AddressModel>> getAddressesOnce(String userId) async {
    if (FirebaseService.isFirebaseAvailable) {
      try {
        final snapshot = await FirebaseService.firestore!
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.addressesCollection)
            .get();

        final list = <AddressModel>[];
        for (final doc in snapshot.docs) {
          try {
            list.add(AddressModel.fromMap(doc.data(), doc.id));
          } catch (e) {
            debugPrint('Error parsing address in getOnce ${doc.id}: $e');
          }
        }
        _localAddresses.removeWhere((a) => a.userId == userId);
        _localAddresses.addAll(list);
        return list;
      } catch (e) {
        debugPrint('Error fetching addresses: $e');
      }
    }
    return _localAddresses.where((a) => a.userId == userId).toList();
  }

  Future<void> addAddress(String userId, AddressModel address) async {
    if (FirebaseService.isFirebaseAvailable) {
      if (address.isDefault) {
        // Reset any existing default
        await _resetOtherDefaults(userId);
      }
      await FirebaseService.firestore!
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.addressesCollection)
          .doc(address.id)
          .set(address.toMap());
    } else {
      if (address.isDefault) {
        for (var i = 0; i < _localAddresses.length; i++) {
          _localAddresses[i] = _localAddresses[i].copyWith(isDefault: false);
        }
      }
      _localAddresses.add(address);
      _emitAddresses();
    }
  }

  Future<void> updateAddress(String userId, AddressModel address) async {
    if (FirebaseService.isFirebaseAvailable) {
      if (address.isDefault) {
        await _resetOtherDefaults(userId);
      }
      await FirebaseService.firestore!
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.addressesCollection)
          .doc(address.id)
          .update(address.toMap());
    } else {
      final idx = _localAddresses.indexWhere((a) => a.id == address.id);
      if (idx != -1) {
        if (address.isDefault) {
          for (var i = 0; i < _localAddresses.length; i++) {
            _localAddresses[i] = _localAddresses[i].copyWith(isDefault: false);
          }
        }
        _localAddresses[idx] = address;
        _emitAddresses();
      }
    }
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.addressesCollection)
          .doc(addressId)
          .delete();
    } else {
      _localAddresses.removeWhere((a) => a.id == addressId);
      _emitAddresses();
    }
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    if (FirebaseService.isFirebaseAvailable) {
      await _resetOtherDefaults(userId);
      await FirebaseService.firestore!
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.addressesCollection)
          .doc(addressId)
          .update({'isDefault': true});
    } else {
      for (var i = 0; i < _localAddresses.length; i++) {
        _localAddresses[i] = _localAddresses[i].copyWith(
          isDefault: _localAddresses[i].id == addressId,
        );
      }
      _emitAddresses();
    }
  }

  Future<void> _resetOtherDefaults(String userId) async {
    final snapshot = await FirebaseService.firestore!
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.addressesCollection)
        .where('isDefault', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }

  void _emitAddresses() {
    _addressesController.add(List.from(_localAddresses));
  }

  void dispose() {
    _addressesController.close();
  }
}
