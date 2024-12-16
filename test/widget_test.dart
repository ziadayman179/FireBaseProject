import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:untitled/services/AnalyticsService.dart';

class TestAuthenticationPage extends StatefulWidget {
  const TestAuthenticationPage({Key? key}) : super(key: key);

  @override
  _TestAuthenticationPageState createState() => _TestAuthenticationPageState();
}

class _TestAuthenticationPageState extends State<TestAuthenticationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  // Phone Authentication
  Future<void> _verifyPhoneNumber() async {
    setState(() {
      _isLoading = true;
      _codeSent = false;
    });

    String phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      _showErrorDialog('Please enter a phone number');
      setState(() => _isLoading = false);
      return;
    }

    if (!phoneNumber.startsWith('+') || phoneNumber.length < 10) {
      _showErrorDialog('Please enter a valid phone number with a country code');
      setState(() => _isLoading = false);
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _showSuccessDialog('Phone Verification Completed');
      },
      verificationFailed: (FirebaseAuthException e) {
        _showErrorDialog('Verification Failed: ${e.message}');
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
      await _auth.signInWithCredential(credential);
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

      await _auth.signInWithCredential(credential);
      _showSuccessDialog('Google Sign In Successful');
    } catch (e) {
      _showErrorDialog(e.toString());
    }
    setState(() => _isLoading = false);
  }

  void _showPhoneVerificationDialog() {
    showDialog(
      context: context,
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
      appBar: AppBar(title: Text('Test Authentication')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              TextField(
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
                      onPressed: _signUpWithEmail,
                      child: Text('Sign Up'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _signInWithEmail,
                      child: Text('Sign In'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number (e.g., +1XXXXXXXXXX)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              ElevatedButton(
                onPressed: _verifyPhoneNumber,
                child: Text('Verify Phone Number'),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
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
