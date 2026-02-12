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
    apiKey: 'AIzaSyC5jmN0GOjjFGpgp0NZgjTucoKTwVnUSKU',
    appId: '1:998340397020:web:40e7a51be6e97d0c653119',
    messagingSenderId: '998340397020',
    projectId: 'stylezone-1bed2',
    authDomain: 'stylezone-1bed2.firebaseapp.com',
    storageBucket: 'stylezone-1bed2.firebasestorage.app',
    measurementId: 'G-Q28MKFCHBB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC5jmN0GOjjFGpgp0NZgjTucoKTwVnUSKU',
    appId: '1:998340397020:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '998340397020',
    projectId: 'stylezone-1bed2',
    storageBucket: 'stylezone-1bed2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC5jmN0GOjjFGpgp0NZgjTucoKTwVnUSKU',
    appId: '1:998340397020:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '998340397020',
    projectId: 'stylezone-1bed2',
    storageBucket: 'stylezone-1bed2.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC5jmN0GOjjFGpgp0NZgjTucoKTwVnUSKU',
    appId: '1:998340397020:ios:YOUR_MACOS_APP_ID',
    messagingSenderId: '998340397020',
    projectId: 'stylezone-1bed2',
    storageBucket: 'stylezone-1bed2.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC5jmN0GOjjFGpgp0NZgjTucoKTwVnUSKU',
    appId: '1:998340397020:windows:YOUR_WINDOWS_APP_ID',
    messagingSenderId: '998340397020',
    projectId: 'stylezone-1bed2',
    storageBucket: 'stylezone-1bed2.firebasestorage.app',
  );
}

