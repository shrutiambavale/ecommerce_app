import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/payment_repository.dart';
import '../domain/payment_settings_model.dart';
import '../domain/payment_submission_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final repo = PaymentRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// Account-isolated payment settings stream for current administrator
final paymentSettingsProvider = StreamProvider<PaymentSettingsModel>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return repo.getPaymentSettings(adminId: user?.id);
});

/// Specific merchant payment settings stream for customer order checkout
final merchantPaymentSettingsProvider =
    StreamProvider.family<PaymentSettingsModel, String?>((ref, merchantId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getPaymentSettings(adminId: merchantId);
});

final pendingSubmissionsProvider =
    StreamProvider<List<PaymentSubmissionModel>>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getPendingPaymentSubmissions();
});

class PaymentController extends StateNotifier<AsyncValue<void>> {
  final PaymentRepository _repo;
  final Ref _ref;

  PaymentController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<PaymentSubmissionModel?> submitPayment({
    required String orderId,
    required String customerId,
    required String customerName,
    required double amount,
    required String utrNumber,
    String? screenshotUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final submission = await _repo.submitPaymentVerification(
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        amount: amount,
        utrNumber: utrNumber,
        screenshotUrl: screenshotUrl,
      );
      state = const AsyncValue.data(null);
      return submission;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> updateSettings(PaymentSettingsModel settings) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw 'Authentication required to update payment settings.';
      }
      await _repo.updatePaymentSettings(settings, adminId: user.id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<String?> uploadQrImage(Uint8List bytes, String fileName) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      final url = await _repo.uploadQrCodeImage(bytes, fileName, adminId: user?.id);
      state = const AsyncValue.data(null);
      return url;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<String?> uploadScreenshot(Uint8List bytes, String fileName) async {
    state = const AsyncValue.loading();
    try {
      final url = await _repo.uploadPaymentScreenshot(bytes, fileName);
      state = const AsyncValue.data(null);
      return url;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, AsyncValue<void>>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return PaymentController(repo, ref);
});

