import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_status.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  // Lazy — touching FirebaseAuth.instance/FirebaseFirestore.instance throws
  // if Firebase didn't initialize, so we never build these at construction
  // and never build them at all when Firebase is unavailable.
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _dbInstance;
  GoogleSignIn? _googleSignInInstance;

  bool get _available => firebaseReady;

  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;
  FirebaseFirestore get _db => _dbInstance ??= FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn =>
      _googleSignInInstance ??= GoogleSignIn();

  // ── Auth state ───────────────────────────────────────────────
  User? get currentUser => _available ? _auth.currentUser : null;
  Stream<User?> get authStateChanges =>
      _available ? _auth.authStateChanges() : Stream.value(null);
  bool get isSignedIn => currentUser != null;

  // ── Sign-in methods ──────────────────────────────────────────
  void _requireFirebase() {
    if (!_available) {
      throw Exception(
          'Sign-in unavailable: Firebase is not configured on this build.');
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    _requireFirebase();
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    await _ensureUserDoc(result.user!);
    return result;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    _requireFirebase();
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureUserDoc(result.user!);
    return result;
  }

  Future<UserCredential> registerWithEmail(
      String email, String password, String displayName) async {
    _requireFirebase();
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await result.user!.updateDisplayName(displayName);
    await _ensureUserDoc(result.user!, displayName: displayName);
    return result;
  }

  Future<void> signOut() async {
    if (!_available) return;
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) {
    _requireFirebase();
    return _auth.sendPasswordResetEmail(email: email);
  }

  // ── User document ────────────────────────────────────────────
  Future<void> _ensureUserDoc(User user, {String? displayName}) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': displayName ?? user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({'lastSeen': FieldValue.serverTimestamp()});
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = currentUser;
    if (user == null) return;
    await user.updateDisplayName(name);
    await _db.collection('users').doc(user.uid).update({'displayName': name});
  }

  // ── Settings sync ────────────────────────────────────────────
  DocumentReference? get _settingsRef {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('data').doc('settings');
  }

  Future<void> pushSettings(Map<String, dynamic> settings) async {
    final ref = _settingsRef;
    if (ref == null) return;
    await ref.set(settings, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> pullSettings() async {
    final ref = _settingsRef;
    if (ref == null) return null;
    final snap = await ref.get();
    return snap.data() as Map<String, dynamic>?;
  }

  Stream<Map<String, dynamic>?> watchSettings() {
    final ref = _settingsRef;
    if (ref == null) return const Stream.empty();
    return ref.snapshots().map((s) => s.data() as Map<String, dynamic>?);
  }

  // ── Liked songs sync ─────────────────────────────────────────
  CollectionReference? get _likedRef {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('liked_songs');
  }

  Future<void> pushLikedSong(Map<String, dynamic> songData) async {
    final ref = _likedRef;
    if (ref == null) return;
    await ref.doc(songData['id'] as String).set({
      ...songData,
      'likedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeLikedSong(String songId) async {
    final ref = _likedRef;
    if (ref == null) return;
    await ref.doc(songId).delete();
  }

  Future<List<Map<String, dynamic>>> fetchLikedSongs() async {
    final ref = _likedRef;
    if (ref == null) return [];
    final snap = await ref.orderBy('likedAt', descending: true).get();
    return snap.docs
        .map((d) => d.data() as Map<String, dynamic>)
        .toList();
  }

  Stream<List<Map<String, dynamic>>> watchLikedSongs() {
    final ref = _likedRef;
    if (ref == null) return const Stream.empty();
    return ref
        .orderBy('likedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data() as Map<String, dynamic>).toList());
  }

  // ── Recently played sync ─────────────────────────────────────
  Future<void> pushRecentlyPlayed(Map<String, dynamic> songData) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('recently_played')
        .doc(songData['id'] as String);
    await ref.set({
      ...songData,
      'playedAt': FieldValue.serverTimestamp(),
    });
  }
}
