import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

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
        return windows;
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
    apiKey: 'AIzaSyBV3bflJiWsWnfTk1UpiyHEgUq0NxdLaRc',
    appId: '1:194069516564:web:cbfa96435d514d8e387201',
    messagingSenderId: '194069516564',
    projectId: 'stylezone-16c43',
    authDomain: 'stylezone-16c43.firebaseapp.com',
    storageBucket: 'stylezone-16c43.firebasestorage.app',
    measurementId: 'G-M7KRPXQM6Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBV3bflJiWsWnfTk1UpiyHEgUq0NxdLaRc',
    appId: '1:194069516564:android:cbfa96435d514d8e387201',
    messagingSenderId: '194069516564',
    projectId: 'stylezone-16c43',
    storageBucket: 'stylezone-16c43.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBV3bflJiWsWnfTk1UpiyHEgUq0NxdLaRc',
    appId: '1:194069516564:ios:cbfa96435d514d8e387201',
    messagingSenderId: '194069516564',
    projectId: 'stylezone-16c43',
    storageBucket: 'stylezone-16c43.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBV3bflJiWsWnfTk1UpiyHEgUq0NxdLaRc',
    appId: '1:194069516564:ios:cbfa96435d514d8e387201',
    messagingSenderId: '194069516564',
    projectId: 'stylezone-16c43',
    storageBucket: 'stylezone-16c43.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBV3bflJiWsWnfTk1UpiyHEgUq0NxdLaRc',
    appId: '1:194069516564:web:cbfa96435d514d8e387201',
    messagingSenderId: '194069516564',
    projectId: 'stylezone-16c43',
    storageBucket: 'stylezone-16c43.firebasestorage.app',
  );
}
