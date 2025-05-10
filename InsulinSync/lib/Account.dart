import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'ChangePassword.dart';
import 'MainNavigation.dart';

class Account extends StatefulWidget {
  const Account({Key? key}) : super(key: key);

  @override
  State<Account> createState() => _AccountWidgetState();
}

class _AccountWidgetState extends State<Account> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  late TextEditingController _FnameController;
  late TextEditingController _LnameController;
  late TextEditingController _emailController;
  // Variable to store any error messages
  String? _error;
  String? _emailErrorMessage;
  bool _isLoading = false;

  final AuthService authService = AuthService();

  late FocusNode _FnameFocusNode;
  late FocusNode _LnameFocusNode;
  late FocusNode _emailFocusNode;

  @override
  void initState() {
    super.initState();
    _FnameController = TextEditingController();
    _LnameController = TextEditingController();
    _emailController = TextEditingController();
    _fetchUserData();

    _FnameFocusNode = FocusNode();
    _LnameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();

// Clear email error when user edits the email field
    _emailController.addListener(() {
      if (_emailErrorMessage != null) {
        setState(() {
          _emailErrorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _FnameController.dispose();
    _LnameController.dispose();
    _emailController.dispose();
    _FnameFocusNode.dispose();
    _LnameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  String? _currentUserEmail; // Store the logged-in user's email
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true; // Show loading overlay
    });

    try {
      final UserService userService = UserService();

      final fname = await userService.getUserAttribute('firstName');
      final lname = await userService.getUserAttribute('lastName');
      final email = await userService.getUserAttribute('email');
      //final dobTimestamp = await userService.getUserAttribute('dateOfBirth');

      // Update the UI state with the retrieved user data
      setState(() {
        _FnameController.text = fname?.toString() ?? '';
        _LnameController.text = lname?.toString() ?? '';
        _emailController.text = email?.toString() ?? '';
        _currentUserEmail = email?.toString(); // Save current email
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString(); // Store the error message
        _isLoading = false;
      });
    }
  }

  // Validator for First Name
  String? firstNameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your first name';
    }
    return null;
  }

  // Validator for Last Name
  String? lastNameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your last name';
    }
    return null;
  }

  Future<String?> asyncEmailValidator(String? value) async {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    // Exclude the currently logged-in user's email from validation
    if (value.trim().toLowerCase() == _currentUserEmail?.trim().toLowerCase()) {
      return null; // Skip checking if it's the same as the current user's email
    }

    // Check if the email is already registered
    bool isRegistered = await authService
        .isEmailRegistered(_emailController.text.trim().toLowerCase());
    if (isRegistered) {
      return 'Email is already registered';
    }

    return null;
  }

  Future<void> _updateUserInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      final UserService userService = UserService();

      await userService.updateUserAttributes(
        firstName: _FnameController.text,
        lastName: _LnameController.text,
        email: _emailController.text,
      );

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
                  'Account information are updated successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22),
                ),
                SizedBox(height: 30),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainNavigation(index: 3)),
          (Route<dynamic> route) => false, // This removes all previous routes
        );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).primaryColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).primaryColor,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon:
                    Icon(Icons.arrow_back_ios, color: Colors.white, size: 30.0),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              elevation: 0.0,
            ),
            body: Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 100.0,
                    height: 100.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFF023B96), // Color(0xFFE1F5FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      color: Colors.white,
                      size: 80.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                                  const Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: const Text(
                                      'First Name',
                                      style: TextStyle(fontSize: 18.0),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 12.0),
                                    child: TextFormField(
                                      controller: _FnameController,
                                      focusNode: _FnameFocusNode,
                                      validator: firstNameValidator,
                                      style: const TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: BorderSide(
                                            color: const Color.fromARGB(
                                                255, 168, 167, 167),
                                            width: 1.0,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: const BorderSide(
                                            color: Color.fromARGB(
                                                255, 168, 167, 167),
                                            width: 1.0,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Text(
                                      'Last Name',
                                      style: TextStyle(fontSize: 18.0),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 12.0),
                                    child: TextFormField(
                                      controller: _LnameController,
                                      focusNode: _LnameFocusNode,
                                      validator: lastNameValidator,
                                      style: const TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: BorderSide(
                                            color: const Color.fromARGB(
                                                255, 168, 167, 167),
                                            width: 1.0,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: const BorderSide(
                                            color: Color.fromARGB(
                                                255, 168, 167, 167),
                                            width: 1.0,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Text(
                                      'Email',
                                      style: TextStyle(fontSize: 18.0),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 12.0),
                                    child: TextFormField(
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        } else if (!RegExp(
                                                r'^[^@]+@[^@]+\.[^@]+')
                                            .hasMatch(value)) {
                                          return 'Please enter a valid email address';
                                        }
                                        return _emailErrorMessage; // Show async validation error
                                      },
                                      onChanged: (value) async {
                                        final error =
                                            await asyncEmailValidator(value);
                                        setState(() {
                                          _emailErrorMessage = error;
                                        });
                                        _formKey.currentState
                                            ?.validate(); // Revalidate form
                                      },
                                      style: const TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: BorderSide(
                                            color: const Color.fromARGB(
                                                255, 168, 167, 167),
                                            width: 1.0,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          borderSide: const BorderSide(
                                            color: Color.fromARGB(
                                                255, 168, 167, 167),
                                            width: 1.0,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Text(
                                      'Change Password',
                                      style: TextStyle(fontSize: 18.0),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 12.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ChangePassword()),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          side: const BorderSide(
                                            color: Color.fromARGB(
                                                255, 168, 167, 167),
                                            width: 1.0,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            vertical: 14.0, horizontal: 16.0),
                                        backgroundColor: Colors.grey[100],
                                        elevation: 0,
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '****************',
                                            style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 24,
                                            color: Color(0xFF333333),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

// Save Button
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                                    child: ElevatedButton(
                                      onPressed: _updateUserInfo,
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
        if (_isLoading)
          ModalBarrier(
            color: Colors.black.withOpacity(0.5),
            dismissible: false,
          ),
        if (_isLoading)
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
      ],
    );
  }
}
