import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>(
  (_) => FirebaseService.instance,
);

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.instance.authStateChanges;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
