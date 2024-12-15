import 'package:firebase_auth/firebase_auth.dart';
class UserServices{
  static Future<String?> getUserId() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      return user?.uid;
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }
  static Future<String?>getUserName()async{
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      return user?.displayName;
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }
}