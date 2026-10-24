import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/user_model.dart';
import '../domain/user_role.dart';

class AuthRepository {
  final _authStateController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  static final List<UserModel> _mockUsers = [];

  AuthRepository() {
    if (FirebaseService.isFirebaseAvailable) {
      final initialFbUser = FirebaseService.auth?.currentUser;
      if (initialFbUser != null) {
        _currentUser = UserModel(
          id: initialFbUser.uid,
          email: initialFbUser.email ?? '',
          fullName: (initialFbUser.displayName != null && initialFbUser.displayName!.isNotEmpty)
              ? initialFbUser.displayName!
              : (initialFbUser.email?.split('@').first ?? 'Customer'),
          role: (initialFbUser.email?.contains('admin') ?? false)
              ? UserRole.admin
              : UserRole.customer,
          createdAt: DateTime.now(),
        );
      }

      FirebaseService.auth?.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser == null) {
          _currentUser = null;
          _authStateController.add(null);
        } else {
          try {
            final doc = await FirebaseService.firestore
                ?.collection(AppConstants.usersCollection)
                .doc(firebaseUser.uid)
                .get();
            if (doc != null && doc.exists && doc.data() != null) {
              _currentUser = UserModel.fromMap(doc.data()!, doc.id);
            } else {
              // Fallback if doc not yet created
              _currentUser = UserModel(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? '',
                fullName: firebaseUser.displayName ?? 'Customer',
                role: (firebaseUser.email?.contains('admin') ?? false)
                    ? UserRole.admin
                    : UserRole.customer,
                createdAt: DateTime.now(),
              );
            }
            _authStateController.add(_currentUser);
          } catch (e) {
            _authStateController.add(_currentUser);
          }
        }
      });
    } else {
      // Default to guest or pre-set customer for immediate preview
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  Stream<UserModel?> get authStateChanges async* {
    yield currentUser;
    yield* _authStateController.stream;
  }

  UserModel? get currentUser {
    if (_currentUser != null) return _currentUser;
    final fbUser = FirebaseService.auth?.currentUser;
    if (fbUser != null) {
      return UserModel(
        id: fbUser.uid,
        email: fbUser.email ?? '',
        fullName: (fbUser.displayName != null && fbUser.displayName!.isNotEmpty)
            ? fbUser.displayName!
            : (fbUser.email?.split('@').first ?? 'Customer'),
        role: (fbUser.email?.contains('admin') ?? false)
            ? UserRole.admin
            : UserRole.customer,
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final cleanEmail = email.trim().toLowerCase();

    if (FirebaseService.isFirebaseAvailable) {
      try {
        final credential =
            await FirebaseService.auth!.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );

        final uid = credential.user!.uid;
        final doc = await FirebaseService.firestore!
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get();

        if (doc.exists && doc.data() != null) {
          _currentUser = UserModel.fromMap(doc.data()!, doc.id);
        } else {
          _currentUser = UserModel(
            id: uid,
            email: cleanEmail,
            fullName: credential.user!.displayName ?? 'User',
            role: UserRole.customer,
            createdAt: DateTime.now(),
          );
          await FirebaseService.firestore!
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .set(_currentUser!.toMap());
        }

        _authStateController.add(_currentUser);
        return _currentUser!;
      } on FirebaseAuthException catch (e) {
        throw _mapFirebaseAuthError(e);
      }
    } else {
      // Local verification
      await Future.delayed(const Duration(milliseconds: 400));
      final user = _mockUsers.firstWhere(
        (u) => u.email.toLowerCase() == cleanEmail,
        orElse: () {
          // Allow dynamic login in local mode
          final isAdm = cleanEmail.contains('admin');
          final newUser = UserModel(
            id: 'user_${DateTime.now().millisecondsSinceEpoch}',
            email: cleanEmail,
            fullName: isAdm ? 'Admin User' : 'Valued Customer',
            phoneNumber: '9876543210',
            role: isAdm ? UserRole.admin : UserRole.customer,
            createdAt: DateTime.now(),
          );
          _mockUsers.add(newUser);
          return newUser;
        },
      );

      _currentUser = user;
      _authStateController.add(_currentUser);
      return user;
    }
  }

  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    UserRole role = UserRole.customer,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (FirebaseService.isFirebaseAvailable) {
      try {
        final credential =
            await FirebaseService.auth!.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );

        final uid = credential.user!.uid;
        final newUser = UserModel(
          id: uid,
          email: cleanEmail,
          fullName: fullName.trim(),
          phoneNumber: phoneNumber.trim(),
          role: role,
          createdAt: DateTime.now(),
        );

        await FirebaseService.firestore!
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .set(newUser.toMap());

        _currentUser = newUser;
        _authStateController.add(_currentUser);
        return newUser;
      } on FirebaseAuthException catch (e) {
        throw _mapFirebaseAuthError(e);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_mockUsers.any((u) => u.email.toLowerCase() == cleanEmail)) {
        throw 'An account already exists with this email address.';
      }

      final newUser = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: cleanEmail,
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      _mockUsers.add(newUser);
      _currentUser = newUser;
      _authStateController.add(_currentUser);
      return newUser;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (FirebaseService.isFirebaseAvailable) {
      try {
        await FirebaseService.auth!.sendPasswordResetEmail(email: cleanEmail);
      } on FirebaseAuthException catch (e) {
        throw _mapFirebaseAuthError(e);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      // Simulated success
    }
  }

  Future<void> signOut() async {
    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.auth?.signOut();
    }
    _currentUser = null;
    _authStateController.add(null);
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.usersCollection)
          .doc(updatedUser.id)
          .update(updatedUser.toMap());
    } else {
      final index = _mockUsers.indexWhere((u) => u.id == updatedUser.id);
      if (index != -1) {
        _mockUsers[index] = updatedUser;
      }
    }
    _currentUser = updatedUser;
    _authStateController.add(_currentUser);
  }

  Future<List<UserModel>> getAllCustomers() async {
    if (FirebaseService.isFirebaseAvailable) {
      final snapshot = await FirebaseService.firestore!
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'customer')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } else {
      return _mockUsers.where((u) => u.role == UserRole.customer).toList();
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user registered with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The provided email is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network connection failure. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
