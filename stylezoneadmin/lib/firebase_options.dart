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
    apiKey: 'AIzaSyCRmBIZPKxfF97aIEntEprVbPIcKObF3M4',
    appId: '1:936193446304:web:016c9f6ca65c20944954c5',
    messagingSenderId: '936193446304',
    projectId: 'stylezone-e37ec',
    authDomain: 'stylezone-e37ec.firebaseapp.com',
    storageBucket: 'stylezone-e37ec.firebasestorage.app',
    measurementId: 'G-W90H4K7V4D',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCRmBIZPKxfF97aIEntEprVbPIcKObF3M4',
    appId: '1:936193446304:android:016c9f6ca65c20944954c5',
    messagingSenderId: '936193446304',
    projectId: 'stylezone-e37ec',
    storageBucket: 'stylezone-e37ec.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCRmBIZPKxfF97aIEntEprVbPIcKObF3M4',
    appId: '1:936193446304:ios:016c9f6ca65c20944954c5',
    messagingSenderId: '936193446304',
    projectId: 'stylezone-e37ec',
    storageBucket: 'stylezone-e37ec.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCRmBIZPKxfF97aIEntEprVbPIcKObF3M4',
    appId: '1:936193446304:ios:016c9f6ca65c20944954c5',
    messagingSenderId: '936193446304',
    projectId: 'stylezone-e37ec',
    storageBucket: 'stylezone-e37ec.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCRmBIZPKxfF97aIEntEprVbPIcKObF3M4',
    appId: '1:936193446304:web:016c9f6ca65c20944954c5',
    messagingSenderId: '936193446304',
    projectId: 'stylezone-e37ec',
    storageBucket: 'stylezone-e37ec.firebasestorage.app',
  );
}
