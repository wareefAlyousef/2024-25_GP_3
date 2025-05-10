import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'splash.dart';

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({Key? key}) : super(key: key);

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  String? asyncEmailError;
  String? asyncPasswordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Form Validator Functions
  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<bool> _showConfirmationDialog() async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Color.fromARGB(41, 248, 77, 117),
                  child: FaIcon(
                    FontAwesomeIcons.userTimes,
                    color: Theme.of(context).colorScheme.error,
                    size: 90.0,
                  ),
                ),
                SizedBox(height: 20),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Are You Sure?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'This action will permanently delete your account and cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(120, 44),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop(true);
                          print(
                              'debug delete account: between pop and handleDeleteAccount');
                          // await handleDeleteAccount(authService);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(120, 44),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    print(
        'debug delete account: inside _showConfirmationDialog returned ${result ?? false}');
    return result ?? false;
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Auto-dismiss after 3 seconds and navigate
        Future.delayed(Duration(seconds: 3), () {
          Navigator.of(context).pop(); // Dismiss dialog
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => OnboardingWidget()),
            (Route<dynamic> route) => false,
          );
        });

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Color(0xff023b96),
                size: 80,
              ),
              SizedBox(height: 25),
              Text(
                'Your account and all associated data have been permanently removed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22),
              ),
              SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteAccount(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      asyncEmailError = null;
      asyncPasswordError = null;
    });

    try {
      // First reauthenticate the user
      bool reauthSuccess = await authService.reauthenticateUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!reauthSuccess) {
        setState(() {
          _isLoading = false;
          asyncEmailError = 'Either the email or password is incorrect.';
          asyncPasswordError = 'Either the email or password is incorrect.';
        });
        return;
      }

      // Show confirmation dialog
      bool confirm = await _showConfirmationDialog();
      if (!confirm) {
        setState(() => _isLoading = false);
        return;
      }

      // Now delete the account
      setState(() => _isLoading = true);

      bool deleteSuccess = await authService.deleteAccountWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!deleteSuccess) {
        setState(() {
          _isLoading = false;
          asyncEmailError = 'Account deletion failed. Please try again.';
          asyncPasswordError = 'Account deletion failed. Please try again.';
        });
        return;
      }

      // Clear shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_notified');

      // Show success dialog
      await _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
        asyncEmailError = 'An error occurred. Please try again.';
        asyncPasswordError = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Stack(
      children: [
        GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: Theme.of(context).primaryColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).primaryColor,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 30.0),
                onPressed: () => Navigator.of(context).pop(),
              ),
              elevation: 0.0,
            ),
            body: Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Center(
                    child: FaIcon(
                      FontAwesomeIcons.userTimes,
                      color: Colors.white,
                      size: 60.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Delete Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 3.0,
                              color: Color(0x33000000),
                              offset: Offset(0.0, -1.0),
                            )
                          ],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16.0),
                            topRight: Radius.circular(16.0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildEmailField(),
                                  const SizedBox(height: 16.0),
                                  _buildPasswordField(),
                                  const SizedBox(height: 30.0),
                                  ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _deleteAccount(authService),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize:
                                          const Size(double.infinity, 44),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.error,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'Delete Account',
                                      style: TextStyle(
                                        fontSize: 25,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Email', style: TextStyle(fontSize: 18.0)),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            validator: emailValidator,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'your@email.com',
              errorText: asyncEmailError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 168, 167, 167),
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 168, 167, 167),
                  width: 1.0,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Password', style: TextStyle(fontSize: 18.0)),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: !_isPasswordVisible,
            validator: passwordValidator,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              errorText: asyncPasswordError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 168, 167, 167),
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 168, 167, 167),
                  width: 1.0,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> handleDeleteAccount(AuthService authService) async {
    print('debug delete account: inside handleDeleteAccount');
    bool success = await authService.deleteAccountWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim());
    if (!success) {
      print('debug delete account: deletion failed');
      asyncEmailError =
          'Either the email or password is incorrect. Please try again.';
      asyncPasswordError =
          'Either the email or password is incorrect. Please try again.';
    } else {
      // Show account have been deleted succussfuly
      print('debug delete account: deletion successfull');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_notified');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // Auto-dismiss after 3 seconds and navigate
          Future.delayed(Duration(seconds: 3), () {
            Navigator.of(context).pop(); // Dismiss dialog
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => OnboardingWidget()),
              (Route<dynamic> route) => false,
            );
          });

          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Color(0xff023b96),
                  size: 80,
                ),
                SizedBox(height: 25),
                Text(
                  'Account is deleted successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22),
                ),
                SizedBox(height: 30),
              ],
            ),
          );
        },
      );
    }
  }
}
