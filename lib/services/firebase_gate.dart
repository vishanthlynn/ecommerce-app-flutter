import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseGate {
  static bool ready = false;

  static Future<void> tryInit() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      ready = true;
    } catch (error) {
      ready = false;
      debugPrint('Firebase is not configured. Mercer is using the REST API. $error');
    }
  }

  static Future<void> mirrorSignIn({required String email, required String password}) async {
    if (!ready) return;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found' || error.code == 'invalid-credential') {
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        } catch (createError) {
          debugPrint('Firebase auth skipped: $createError');
        }
      }
    } catch (error) {
      debugPrint('Firebase auth skipped: $error');
    }
  }

  static Future<void> pushOrder(Map<String, dynamic> order) async {
    if (!ready) return;
    try {
      await FirebaseFirestore.instance.collection('orders').doc('${order['id']}').set(order);
    } catch (error) {
      debugPrint('Firestore order sync skipped: $error');
    }
  }
}
