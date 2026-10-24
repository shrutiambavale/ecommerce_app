import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/payment_settings_model.dart';
import '../domain/payment_submission_model.dart';

class PaymentRepository {
  final Map<String, StreamController<PaymentSettingsModel>> _adminControllers = {};
  final _submissionsController =
      StreamController<List<PaymentSubmissionModel>>.broadcast();

  final Map<String, PaymentSettingsModel> _adminSettingsMap = {};
  final PaymentSettingsModel _defaultSettings =
      PaymentSettingsModel.defaultSettings('default');

  final List<PaymentSubmissionModel> _localSubmissions = [];

  PaymentRepository() {
    _submissionsController.add(List.from(_localSubmissions));

    if (FirebaseService.isFirebaseAvailable) {
      FirebaseService.firestore
          ?.collection(AppConstants.paymentSubmissionsCollection)
          .snapshots()
          .listen((snapshot) {
        final list = <PaymentSubmissionModel>[];
        for (final doc in snapshot.docs) {
          try {
            list.add(PaymentSubmissionModel.fromMap(doc.data(), doc.id));
          } catch (e) {
            debugPrint('Error parsing payment submission ${doc.id}: $e');
          }
        }
        _localSubmissions.clear();
        _localSubmissions.addAll(list);
        _submissionsController.add(List.from(_localSubmissions));
      }, onError: (e) {
        debugPrint('Payment submissions stream error: $e');
        _submissionsController.add(List.from(_localSubmissions));
      });
    }
  }

  StreamController<PaymentSettingsModel> _getControllerForAdmin(String key) {
    return _adminControllers.putIfAbsent(
      key,
      () => StreamController<PaymentSettingsModel>.broadcast(),
    );
  }

  Stream<PaymentSettingsModel> getPaymentSettings({String? adminId}) async* {
    final key = adminId != null && adminId.isNotEmpty ? adminId : 'default';
    final cached = _adminSettingsMap[key] ??
        (key == 'default'
            ? _defaultSettings
            : PaymentSettingsModel.defaultSettings(adminId));

    yield cached;

    if (FirebaseService.isFirebaseAvailable) {
      FirebaseService.firestore
          ?.collection(AppConstants.paymentSettingsCollection)
          .doc(key)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          try {
            final parsed =
                PaymentSettingsModel.fromMap(snapshot.data()!, snapshot.id);
            _adminSettingsMap[key] = parsed;
            _getControllerForAdmin(key).add(parsed);
          } catch (e) {
            debugPrint('Error parsing payment settings for $key: $e');
          }
        } else if (key != 'default') {
          try {
            final defaultDoc = await FirebaseService.firestore!
                .collection(AppConstants.paymentSettingsCollection)
                .doc('default')
                .get();
            if (defaultDoc.exists && defaultDoc.data() != null) {
              final fallback =
                  PaymentSettingsModel.fromMap(defaultDoc.data()!, 'default');
              _getControllerForAdmin(key).add(fallback);
            }
          } catch (_) {}
        }
      }, onError: (e) {
        debugPrint('Payment settings stream error for $key: $e');
      });
    }

    yield* _getControllerForAdmin(key).stream;
  }

  Future<PaymentSettingsModel> getPaymentSettingsOnce({String? adminId}) async {
    final key = adminId != null && adminId.isNotEmpty ? adminId : 'default';

    if (FirebaseService.isFirebaseAvailable) {
      try {
        final doc = await FirebaseService.firestore!
            .collection(AppConstants.paymentSettingsCollection)
            .doc(key)
            .get();
        if (doc.exists && doc.data() != null) {
          final settings = PaymentSettingsModel.fromMap(doc.data()!, doc.id);
          _adminSettingsMap[key] = settings;
          return settings;
        } else if (key != 'default') {
          final defaultDoc = await FirebaseService.firestore!
              .collection(AppConstants.paymentSettingsCollection)
              .doc('default')
              .get();
          if (defaultDoc.exists && defaultDoc.data() != null) {
            return PaymentSettingsModel.fromMap(defaultDoc.data()!, 'default');
          }
        }
      } catch (e) {
        debugPrint('Error fetching payment settings for $key: $e');
      }
    }

    return _adminSettingsMap[key] ??
        (key == 'default'
            ? _defaultSettings
            : PaymentSettingsModel.defaultSettings(adminId));
  }

  Future<void> updatePaymentSettings(
    PaymentSettingsModel settings, {
    required String adminId,
  }) async {
    final key = adminId.isNotEmpty ? adminId : 'default';
    final bound = settings.copyWith(
      ownerId: key,
      updatedBy: adminId,
    );

    _adminSettingsMap[key] = bound;
    _getControllerForAdmin(key).add(bound);

    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.paymentSettingsCollection)
          .doc(key)
          .set(bound.toMap(), SetOptions(merge: true));
    }
  }

  Future<String> uploadQrCodeImage(
    Uint8List bytes,
    String fileName, {
    String? adminId,
  }) async {
    if (FirebaseService.isFirebaseAvailable && FirebaseService.storage != null) {
      final ref = FirebaseService.storage!
          .ref()
          .child(AppConstants.qrImagesPath)
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } else {
      final key = (adminId != null && adminId.isNotEmpty) ? adminId : 'default';
      final settings = _adminSettingsMap[key] ?? _defaultSettings;
      // Return a simulated URL
      return 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=upi%3A%2F%2Fpay%3Fpa%3D${Uri.encodeComponent(settings.upiId)}%26pn%3D${Uri.encodeComponent(settings.receiverName)}%26cu%3DINR';
    }
  }

  Future<String> uploadPaymentScreenshot(Uint8List bytes, String fileName) async {
    if (FirebaseService.isFirebaseAvailable && FirebaseService.storage != null) {
      final ref = FirebaseService.storage!
          .ref()
          .child(AppConstants.paymentReceiptsPath)
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } else {
      // In local mode, store as data URI or placeholder
      return 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=600&q=80';
    }
  }

  Future<PaymentSubmissionModel> submitPaymentVerification({
    required String orderId,
    required String customerId,
    required String customerName,
    required double amount,
    required String utrNumber,
    String? screenshotUrl,
  }) async {
    final submissionId = 'sub_${DateTime.now().millisecondsSinceEpoch}';
    final submission = PaymentSubmissionModel(
      id: submissionId,
      orderId: orderId,
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      utrNumber: utrNumber.trim(),
      screenshotUrl: screenshotUrl ?? '',
      status: 'pending',
      submittedAt: DateTime.now(),
    );

    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.paymentSubmissionsCollection)
          .doc(submissionId)
          .set(submission.toMap());
    } else {
      _localSubmissions.add(submission);
      _submissionsController.add(List.from(_localSubmissions));
    }

    return submission;
  }

  Stream<List<PaymentSubmissionModel>> getPendingPaymentSubmissions() async* {
    yield _localSubmissions.where((s) => s.isPending).toList();
    yield* _submissionsController.stream.map((list) {
      return list.where((s) => s.isPending).toList();
    });
  }

  Future<void> updateSubmissionStatus({
    required String orderId,
    required String status,
    String? rejectionReason,
    required String adminId,
  }) async {
    final now = DateTime.now();

    if (FirebaseService.isFirebaseAvailable) {
      final snapshot = await FirebaseService.firestore!
          .collection(AppConstants.paymentSubmissionsCollection)
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'status': status,
          'rejectionReason': rejectionReason,
          'verifiedAt': now.toIso8601String(),
          'verifiedBy': adminId,
        });
      }
    } else {
      final idx = _localSubmissions.indexWhere((s) => s.orderId == orderId);
      if (idx != -1) {
        final current = _localSubmissions[idx];
        _localSubmissions[idx] = PaymentSubmissionModel(
          id: current.id,
          orderId: current.orderId,
          customerId: current.customerId,
          customerName: current.customerName,
          amount: current.amount,
          utrNumber: current.utrNumber,
          screenshotUrl: current.screenshotUrl,
          status: status,
          rejectionReason: rejectionReason,
          submittedAt: current.submittedAt,
          verifiedAt: now,
          verifiedBy: adminId,
        );
        _submissionsController.add(List.from(_localSubmissions));
      }
    }
  }

  void dispose() {
    for (final controller in _adminControllers.values) {
      controller.close();
    }
    _adminControllers.clear();
    _submissionsController.close();
  }
}
