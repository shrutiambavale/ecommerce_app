import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/address_repository.dart';
import '../domain/address_model.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final repo = AddressRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final userAddressesProvider = StreamProvider<List<AddressModel>>((ref) {
  final repo = ref.watch(addressRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value([]);
  }
  return repo.getAddresses(user.id);
});

final selectedAddressProvider = StateProvider<AddressModel?>((ref) {
  final addressesAsync = ref.watch(userAddressesProvider);
  return addressesAsync.maybeWhen(
    data: (list) {
      if (list.isEmpty) return null;
      final defaultAddr = list.where((a) => a.isDefault);
      return defaultAddr.isNotEmpty ? defaultAddr.first : list.first;
    },
    orElse: () => null,
  );
});

class AddressController extends StateNotifier<AsyncValue<void>> {
  final AddressRepository _repo;

  AddressController(this._repo) : super(const AsyncValue.data(null));

  Future<bool> saveAddress(String userId, AddressModel address, {bool isNew = true}) async {
    state = const AsyncValue.loading();
    try {
      if (isNew) {
        await _repo.addAddress(userId, address);
      } else {
        await _repo.updateAddress(userId, address);
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteAddress(String userId, String addressId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteAddress(userId, addressId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<void> setDefault(String userId, String addressId) async {
    try {
      await _repo.setDefaultAddress(userId, addressId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final addressControllerProvider =
    StateNotifierProvider<AddressController, AsyncValue<void>>((ref) {
  final repo = ref.watch(addressRepositoryProvider);
  return AddressController(repo);
});
