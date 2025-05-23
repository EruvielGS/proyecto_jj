// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA45-DupTGrx1wIPydmirDkcl2GiGnK_AU',
    appId: '1:232656817815:android:ad5000095afa0c2bb323d2',
    messagingSenderId: '232656817815',
    projectId: 'proyecto-jj-2ee7a',
    storageBucket: 'proyecto-jj-2ee7a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAodcKxa1-KPBxdTASFSDIyTYU3iBScdW0',
    appId: '1:232656817815:ios:9f07ecce092030cab323d2',
    messagingSenderId: '232656817815',
    projectId: 'proyecto-jj-2ee7a',
    storageBucket: 'proyecto-jj-2ee7a.firebasestorage.app',
    iosBundleId: 'com.example.proyectoJj',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAodcKxa1-KPBxdTASFSDIyTYU3iBScdW0',
    appId: '1:232656817815:ios:9f07ecce092030cab323d2',
    messagingSenderId: '232656817815',
    projectId: 'proyecto-jj-2ee7a',
    storageBucket: 'proyecto-jj-2ee7a.firebasestorage.app',
    iosBundleId: 'com.example.proyectoJj',
  );
}
