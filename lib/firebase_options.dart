// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAVji8t85eU2_ABdCp-ikGn7WdpAKxqIh8',
    appId: '1:940446628757:web:44d92288f3cdf23fb5549c',
    messagingSenderId: '940446628757',
    projectId: 'moyubie-cbfbb',
    authDomain: 'moyubie-cbfbb.firebaseapp.com',
    storageBucket: 'moyubie-cbfbb.appspot.com',
    measurementId: 'G-SJ05TWV52Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCClhx2WxuK2Mn3iuzsdfP5lCa_RETQIbs',
    appId: '1:940446628757:android:5a9bc1d91ac4ce0ab5549c',
    messagingSenderId: '940446628757',
    projectId: 'moyubie-cbfbb',
    storageBucket: 'moyubie-cbfbb.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBb-3PpZS9shNJW6MFwOjval9KpPxL60SM',
    appId: '1:940446628757:ios:97d377b8187c8e5db5549c',
    messagingSenderId: '940446628757',
    projectId: 'moyubie-cbfbb',
    storageBucket: 'moyubie-cbfbb.appspot.com',
    iosClientId: '940446628757-qcck4cjmcbej8q4esctbf7lagpmb1nlt.apps.googleusercontent.com',
    iosBundleId: 'com.moyuteam.moyubie',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBb-3PpZS9shNJW6MFwOjval9KpPxL60SM',
    appId: '1:940446628757:ios:97d377b8187c8e5db5549c',
    messagingSenderId: '940446628757',
    projectId: 'moyubie-cbfbb',
    storageBucket: 'moyubie-cbfbb.appspot.com',
    iosClientId: '940446628757-qcck4cjmcbej8q4esctbf7lagpmb1nlt.apps.googleusercontent.com',
    iosBundleId: 'com.moyuteam.moyubie',
  );
}
