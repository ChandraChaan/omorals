import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for the `omorals` project.
///
/// These values identify the project to Firebase; they are not secrets.
/// Access is controlled by `firestore.rules`.
class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCLAygfuVBSHd3IkCuhJeqwQab5nMh7UuA',
    appId: '1:272701331042:web:09f152135f0cf900a3a33b',
    messagingSenderId: '272701331042',
    projectId: 'omorals',
    authDomain: 'omorals.firebaseapp.com',
    storageBucket: 'omorals.firebasestorage.app',
  );
}
