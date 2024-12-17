import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:untitled/model/UserModel.dart';
import 'package:untitled/services/AnalyticsService.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({Key? key}) : super(key: key);

  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();

  String _verificationId = '';
  bool _isLoading = false;
  bool _codeSent = false;

  // Email & Password Authentication
  Future<void> _signUpWithEmail() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Set display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      final userData = UserModel(
        id: userCredential.user!.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: '',
      );

      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData.toMap());

      // Move analytics service calls inside the successful try block
      final analyticsService = AnalyticsService();
      analyticsService.register(_emailController.text, "email and password");
      analyticsService.login(_emailController.text, "email and password");

      _showSuccessDialog('Email Sign Up Successful');
    } catch (e) {
      _showErrorDialog(e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _showSuccessDialog('Email Sign In Successful');
    } catch (e) {
      _showErrorDialog(e.toString());
    }
    setState(() => _isLoading = false);

  }

  // Phone Number Authentication
  Future<void> _verifyPhoneNumber() async {
    setState(() {
      _isLoading = true;
      _codeSent = false;
    });

    String phoneNumber = _phoneController.text.trim();

    // Validate phone number
    if (phoneNumber.isEmpty) {
      _showErrorDialog('Please enter a phone number');
      setState(() => _isLoading = false);
      return;
    }

    // Manually validate phone number
    if (!phoneNumber.startsWith('+') || phoneNumber.length < 10) {
      _showErrorDialog('Please enter a valid phone number with a country code');
      setState(() => _isLoading = false);
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential = await _auth.signInWithCredential(credential);

          // Set display name
          await userCredential.user?.updateDisplayName(phoneNumber);

          final userData = UserModel(
            id: userCredential.user!.uid,
            name: phoneNumber,
            email: '',
            password: '',
            phoneNumber: phoneNumber,
          );

          final FirebaseFirestore _firestore = FirebaseFirestore.instance;
          await _firestore.collection('users').doc(userCredential.user!.uid).set(userData.toMap());

          _showSuccessDialog('Phone Verification Completed');
        } catch (e) {
          _showErrorDialog('Verification Error: ${e.toString()}');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        String errorMessage = 'Verification Failed: ';
        switch (e.code) {
          case 'invalid-phone-number':
            errorMessage += 'Invalid phone number format';
            break;
          case 'too-many-requests':
            errorMessage += 'Too many requests. Please try again later';
            break;
          default:
            errorMessage += e.message ?? 'Unknown error occurred';
        }
        _showErrorDialog(errorMessage);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _isLoading = false;
        });
        _showPhoneVerificationDialog();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }

  Future<void> _signInWithPhoneCode(String smsCode) async {
    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);

      // Set display name if not already set
      await userCredential.user?.updateDisplayName(_phoneController.text.trim());
      _showSuccessDialog('Phone Sign In Successful');
    } catch (e) {
      _showErrorDialog('Verification Failed: ${e.toString()}');
    }
    setState(() => _isLoading = false);
  }

  // Google Sign-In
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Use Google account name or fall back to input name
      String displayName = googleUser?.displayName ?? _nameController.text.trim();
      await userCredential.user?.updateDisplayName(displayName);

      final userData = UserModel(
        id: userCredential.user!.uid,
        name: displayName,
        email: googleUser?.email ?? '',
        password: '',
        phoneNumber: '',
      );

      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData.toMap());

      _showSuccessDialog('Google Sign In Successful');
    } catch (e) {
      _showErrorDialog(e.toString());
    }
    setState(() => _isLoading = false);
  }

  void _showPhoneVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Enter Verification Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _smsCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'SMS Code',
                helperText: 'Enter the 6-digit code',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_smsCodeController.text.length == 6) {
                  Navigator.of(context).pop();
                  _signInWithPhoneCode(_smsCodeController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid 6-digit code')),
                  );
                }
              },
              child: Text('Verify Code'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Authentication')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key:const Key('nameField'),
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      key: const Key('emailField'),
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      key:const  Key('passwordField'),
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            key:const Key('signUpButton'),
                            onPressed: _signUpWithEmail,
                            child: Text('Sign Up'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            key:const Key('signInButton'),
                            onPressed: _signInWithEmail,
                            child: Text('Sign In'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextField(
                      key:const Key('phoneField'),
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number (e.g., +1XXXXXXXXXX)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    ElevatedButton(
                      key:const Key('verifyPhoneButton'),
                      onPressed: _verifyPhoneNumber,
                      child: Text('Verify Phone Number'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      key:const Key('googleSignInButton'),
                      icon: Icon(Icons.g_translate),
                      label: Text('Sign In with Google'),
                      onPressed: _signInWithGoogle,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
