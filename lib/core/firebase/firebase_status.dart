/// True only after Firebase.initializeApp() succeeds in main(). When false,
/// every Firebase-backed feature degrades gracefully instead of crashing.
/// A missing/placeholder GoogleService-Info.plist makes init throw, so the
/// app must keep running with this flag false.
bool firebaseReady = false;
