import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({Key? key}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _currentPasswordFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool current = false;
  bool neww = false;
  bool confirm = false;
  final Map<String, bool> _isPasswordVisible = {
    'current': false,
    'new': false,
    'confirm': false,
  };

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>(); // Add a GlobalKey for the Form

// Form Validator Functions
  String? currentPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your current password';
    }
    return null;
  }

  String? newPasswordValidator(String? value) {
    String pattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d!@#$%^&*(),.?":{}|<>]{8,}$';
    RegExp regExp = RegExp(pattern);

    if (value == null || value.isEmpty) {
      return 'Please enter the new password';
    } else if (value.length < 8) {
      return 'Password must be at least 8 characters';
    } else if (!regExp.hasMatch(value)) {
      return 'Password must contain at least:\none uppercase letter\none lowercase letter\none number';
    } else if (value == _currentPasswordController.text) {
      return 'New password cannot be same as current password';
    }
    return null;
  }

  String? confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    } else if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

// Change Password Method
  Future<void> _changePassword() async {
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      await authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      // Show a success message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
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
                  'Password is updated successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22),
                ),
                SizedBox(height: 30),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xff023b96),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(100, 44),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      );
      Future.delayed(Duration(seconds: 3), () {
        Navigator.of(context).pop();
      });
    } catch (e) {
      // Show an error message if the update fails
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cancel_outlined,
                  color: Color.fromARGB(255, 194, 43, 98),
                  size: 80,
                ),
                SizedBox(height: 25),
                Text(
                  'Failed saving changes!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22),
                ),
                SizedBox(height: 15),
                Text(
                  'Something went wrong, please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                )
              ],
            ),
            actions: [
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xff023b96),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(100, 44),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  // Your existing content (circle icon, title, form, etc.)
                  Container(
                    width: 100.0,
                    height: 100.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFF023B96),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 80.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Change Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.0,
                    ),
                  ),
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
                                  _buildPasswordField(
                                    label: 'Current Password',
                                    controller: _currentPasswordController,
                                    focusNode: _currentPasswordFocusNode,
                                    fieldKey: 'current',
                                    validator: currentPasswordValidator,
                                  ),
                                  _buildPasswordField(
                                    label: 'New Password',
                                    controller: _newPasswordController,
                                    focusNode: _newPasswordFocusNode,
                                    fieldKey: 'new',
                                    validator: newPasswordValidator,
                                  ),
                                  _buildPasswordField(
                                    label: 'Confirm New Password',
                                    controller: _confirmPasswordController,
                                    focusNode: _confirmPasswordFocusNode,
                                    fieldKey: 'confirm',
                                    validator: confirmPasswordValidator,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () async {
                                              if (!_formKey.currentState!
                                                  .validate()) return;
                                              await _changePassword();
                                            },
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size(double.infinity, 44),
                                        backgroundColor: Color(0xFF023B96),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                      ),
                                      child: const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 25,
                                          color: Colors.white,
                                        ),
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

        // Loading overlay (now covers AppBar too)
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String fieldKey, // Unique key for each field
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 18.0)),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: !_isPasswordVisible[fieldKey]!,
            validator: validator,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
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
                  _isPasswordVisible[fieldKey]!
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible[fieldKey] =
                        !_isPasswordVisible[fieldKey]!;
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
}
