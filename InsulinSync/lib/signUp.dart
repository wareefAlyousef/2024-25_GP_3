import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'main.dart';
import 'package:intl/intl.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import'termsOfUse.dart';
import 'dart:async';
import 'home_screen.dart';
import 'package:flutter/gestures.dart';
import 'logIn.dart';
import 'package:insulin_sync/MainNavigation.dart';

class MainForm extends StatefulWidget {
  MainForm({super.key});

  @override
  _MainFormState createState() => _MainFormState();
}

class _MainFormState extends State<MainForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _emailErrorMessage; 

  final AuthService authService = AuthService(); 


  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

    @override
      void initState() {
        super.initState();
        
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
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(23.0, 0.0, 23.0, 23.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 19.0), 
                      MyBackButton(),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 0),
                        child: Text(
                          'Create an account',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 36,
                                letterSpacing: 0.0,
                                color: Color(0xFF333333),
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 40),
                        child: Text(
                          'Let\'s set up your account! Please fill out the details in the form below.',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w400,
                                fontSize: 19,
                                color: Color(0xFF666666),
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                      Form(
                        key: _formKey, 
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            buildTextField(
                              label: 'First Name *',
                              controller: _firstNameController,
                              validator: firstNameValidator,
                              icon: Icons.person,
                            ),
                            buildTextField(
                              label: 'Last Name *',
                              controller: _lastNameController,
                              validator: lastNameValidator,
                              icon: Icons.person_outline,
                            ),
                            buildTextField(
                              label: 'Email *',
                              controller: _emailController,
                              validator: emailValidator,
                              icon: Icons.email,
                            ),
                            buildTextField(
                              label: 'Password *',
                              isObscured: true,
                              controller: _passwordController,
                              validator: passwordValidator,
                              icon: Icons.lock,
                            ),
                            SizedBox(height: 30.0), 
        // Next Button
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: CustomButton(
                  text: 'Next',
                  onPressed: () async {
                    // Run synchronous form validation first
                    bool formIsValid = _formKey.currentState?.validate() == true;

                    if (formIsValid) {
                      // Now check if the email is already registered using the async validator
                      bool isRegistered = await authService.isEmailRegistered(_emailController.text.trim().toLowerCase());

                      if (isRegistered) {
                        // Set error message for email if already registered and trigger UI update
                        setState(() {
                          _emailErrorMessage = 'Email is already registered';
                        });
                        // Re-validate form to show the email error under the input field
                        _formKey.currentState?.validate();
                      } else {
                        // Clear any previous error message
                        setState(() {
                          _emailErrorMessage = null;
                        });

                        // Proceed to the next page only if the email is NOT registered
                        print('Email is not registered, proceeding...');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PersonalInfoPage(
                              firstName: _firstNameController.text,
                              lastName: _lastNameController.text,
                              email: _emailController.text.trim().toLowerCase(),
                              password: _passwordController.text,
                            ),
                          ),
                        );
                      }
                    }
                  },
                )
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                    children: [
                      const TextSpan(
                          text: 'Already have an account? ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                          ),
                        ),
                      TextSpan(
                        text: 'Log in',
                        style: const TextStyle(
                          color: Color(0xFF023B96),
                          fontWeight: FontWeight.w500,
                          fontSize: 16.0,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navigate to the logIn page
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => logIn()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),

                          ],
                        ),
                      ),
                    ],
                  ),
                  
                ),
              ),

              
              

             
            ],
          ),
        ),
      );
  }
  
  // Build text field widget
  buildTextField({
    required String label,
    bool isObscured = false,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    final FocusNode focusNode = FocusNode();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 18, 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16, 
              ),
            ),
          ),
          CustomTextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            obscureText: isObscured,
            autofillHint: AutofillHints.name,
            textInputAction: TextInputAction.next,
            prefixIcon: icon,
          ),
        ],
      ),
    );
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
  // Synchronous email format validator
  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    } else if (_emailErrorMessage != null) {
      return _emailErrorMessage; 
    }
    return null;
  }
  // Async Email Validator
  Future<String?> asyncEmailValidator(String? value) async {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    // Check if the email is already registered using the AuthService
    bool isRegistered = await authService.isEmailRegistered(value.trim().toLowerCase());
    if (isRegistered) {
      return 'Email is already registered';
    }

    return null; 
  }

  // Password Validator
  String? passwordValidator(String? value) {
    String pattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d!@#$%^&*(),.?":{}|<>]{8,}$';
    RegExp regExp = RegExp(pattern);

    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    } else if (value.length < 8) {
      return 'Password must be at least 8 characters';
    } else if (!regExp.hasMatch(value)) {
      return 'Password must contain at least:\n  one uppercase letter\n  one lowercase letter\n  one number';
    }

    return null;
  }

  // Confirm Password Validator
  String? confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    } else if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }
}

// /////////////////////////////////////////////////////////////////////////
// personal information

class PersonalInfoPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String password; 

  PersonalInfoPage({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password, 
  });

  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for the form fields
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  DateTime? _selectedDate; 
  bool? _isMale; 
  String? _errorMessage; 

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // Function to handle the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), 
      firstDate: DateTime(1900), 
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true, 
        body: Padding(
          padding: const EdgeInsets.fromLTRB(23.0, 0.0, 23.0, 23.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Expanded(
                child: SingleChildScrollView( 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 19.0), 
                      MyBackButton(),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 0),
                        child: Text(
                          'Welcome, ${widget.firstName}!',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 36,
                                letterSpacing: 0.0,
                                color: Color(0xFF333333),
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 40),
                        child: Text(
                          'Please fill out the form below with your personal information.',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w400,
                                fontSize: 19,
                                color: Color(0xFF666666),
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 4), 
                              child: Row(
                                children: [
                                  Text(
                                    'Gender *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Gender selection field
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              child: Container(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8.0,
                                      children: [
                                        ChoiceChip(
                                          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                                          label: Text(
                                            'Male',
                                            style: TextStyle(
                                              fontSize: 18, 
                                            ),
                                          ),
                                          selected: _isMale == true,
                                          selectedColor: Color(0x4C095AEC),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8.0),
                                            side: BorderSide(
                                              color: (_isMale == null && _errorMessage != null) 
                                                  ? Theme.of(context).colorScheme.error 
                                                  : Color(0xFF023B95), 
                                              width: 1.0,
                                            ),
                                          ),
                                          onSelected: (bool selected) {
                                            setState(() {
                                              _isMale = true;
                                              _validateGender(); 
                                            });
                                          },
                                        ),
                                        ChoiceChip(
                                          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                                          label: Text(
                                            'Female',
                                            style: TextStyle(
                                              fontSize: 18, 
                                            ),
                                          ),
                                          selected: _isMale == false,
                                          selectedColor: Color(0x4C095AEC),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8.0),
                                            side: BorderSide(
                                              color: (_isMale == null && _errorMessage != null) 
                                                  ? Theme.of(context).colorScheme.error 
                                                  : Color(0xFF023B95),  
                                              width: 1.0,
                                            ),
                                          ),
                                          onSelected: (bool selected) {
                                            setState(() {
                                              _isMale = false;
                                              _validateGender(); 
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    // Conditional rendering of the error message for gender
                                    if (_errorMessage != null)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(7, 0, 0, 0),
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.error,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            buildTextField(
                              label: 'Weight (kg) *',
                              controller: _weightController,
                              validator: weightValidator,
                              icon: FontAwesomeIcons.weight, 
                            ),
                            buildTextField(
                              label: 'Height (cm) *',
                              controller: _heightController,
                              validator: heightValidator,
                              icon: Icons.height,
                            ),
                            buildDateField(),
                            SizedBox(height: 50.0), 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: CustomButton(
                                text: 'Next',
                                onPressed: () {
                                  _validateGender(); 
                                  if (_formKey.currentState?.validate() == true && _errorMessage == null) {
                                    // If form validation is successful and gender is selected, proceed
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DiabetesManagementPage(
                                          firstName: widget.firstName,
                                          lastName: widget.lastName,
                                          email: widget.email.trim().toLowerCase(),
                                          weight: _weightController.text,
                                          height: _heightController.text,
                                          selectedDate: _selectedDate,
                                          isMale: _isMale ?? false, 
                                          password: widget.password,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                        color: Color(0xFF666666),
                                      ),
                                  children: [
                                    const TextSpan(
                                      text: 'Already have an account? ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Log in',
                                      style: const TextStyle(
                                        color: Color(0xFF023B96),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16.0,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          // Navigate to the logIn page
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => logIn()),
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                }

  // Gender Validator
  void _validateGender() {
    setState(() {
      if (_isMale == null) {
        _errorMessage = "Please select a gender";
      } else {
        _errorMessage = null;
      }
    });
  }

  // Date of Birth Field Builder
  Widget buildDateField() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 18, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
            child: Text(
              'Date of Birth *',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _selectDate(context), // Show date picker
            child: AbsorbPointer(
              child: CustomTextFormField(
                controller: TextEditingController(
                  text: _selectedDate != null
                      ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                      : '',
                ),
                autofillHint: AutofillHints.birthday,
                prefixIcon: Icons.calendar_today,
                validator: (value) {
                  return ageValidator(context, _selectedDate); // Pass the context and selected date
                },
                obscureText: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Text Field Builder
 Widget buildTextField({
  required String label,
  required TextEditingController controller,
  required IconData icon,
  String? Function(String?)? validator,
}) {
  bool isNumericField = label.contains('Weight') || label.contains('Height');

  return Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(0, 18, 0, 0),
    child: Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16, 
            ),
          ),
        ),
        Builder(
          builder: (context) {
            return TextFormField(
              controller: controller,
              validator: validator,
              obscureText: false,
              textInputAction: TextInputAction.next,
              keyboardType: isNumericField ? TextInputType.number : TextInputType.text,
              inputFormatters: isNumericField
                  ? [FilteringTextInputFormatter.digitsOnly] 
                  : [],
              decoration: InputDecoration(
                prefixIcon: Icon(icon),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFF023B95),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFF023B95),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 13),
                filled: true,
                fillColor: Color(0xFFFFFFFF),
              ),
              style: TextStyle(
                fontSize: 18, 
              ),
            );
          },
        ),
      ],
    ),
  );
}

// Weight Validator
String? weightValidator(String? value) {
  // Check if the input is null or empty
  if (value == null || value.isEmpty) {
    return 'Please enter your weight';
  }
  final double? weight = double.tryParse(value);
  // Check if the input is a valid number
  if (weight == null) {
    return 'Please enter a valid number';
  }
  // Check if the weight is within the valid range for adults (30kg to 500kg)
  if (weight < 30 || weight > 500) {
    return 'Please enter a weight between 30 and 500 kg';
  }
  // If all checks pass, the weight is valid
  return null;
}

// Height Validator 
String? heightValidator(String? value) {
  // Check if the input is null or empty
  if (value == null || value.isEmpty) {
    return 'Please enter your height';
  }
  // Try to parse the input to a double (for height in cm)
  final double? height = double.tryParse(value);
  // Check if the input is a valid number
  if (height == null) {
    return 'Please enter a valid number';
  }
  // Check if the height is within the valid range for adults (50cm to 250cm)
  if (height < 50 || height > 250) {
    return 'Please enter a height between 50 and 250 cm';
  }
  return null;
}


  // Validator for Age 
  String? ageValidator(BuildContext context, DateTime? selectedDate) {
    if (selectedDate == null) {
      return 'Please select your date of birth';
    }
    DateTime today = DateTime.now();
    int age = today.year - selectedDate.year;

    if (today.month < selectedDate.month || (today.month == selectedDate.month && today.day < selectedDate.day)) {
      age--;
    }
    if (age < 18) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:  BorderRadius.circular(28.0), 
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Icon(
                  Icons.warning_amber_rounded, 
                  color: Theme.of(context).colorScheme.error, 
                  size: 30,
                ),
                SizedBox(width: 10), 
                Text(
                  'Age Restriction',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary, 
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min, 
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Text(
                  'This app is only for adults 18 years old and above. Please come back when you\'re old enough!',
                  style: TextStyle(fontSize: 16, color: Colors.black), 
                  textAlign: TextAlign.center, 
                ),
              ],
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 10), 
            actions: [
              Center( 
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); 
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    backgroundColor: Theme.of(context).colorScheme.primary, 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), 
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(fontSize: 16), 
                  ),
                ),
              ),
              SizedBox(height: 13), 
            ],
          );
        },
      );
      return 'You must be at least 18 years old to use this app';
    }
    return null;
  }
}

//////////////////////////////////////////////////////////
/// diabites info

class DiabetesManagementPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String weight;
  final String height;
  final DateTime? selectedDate;
  final bool? isMale; 
  final String password;

  DiabetesManagementPage({
    Key? key, 
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.weight,
    required this.height,
    this.selectedDate,
    this.isMale, 
    required this.password,
  }) : super(key: key);

  @override
  _DiabetesManagementPageState createState() => _DiabetesManagementPageState();
}

class _DiabetesManagementPageState extends State<DiabetesManagementPage> {
  final TextEditingController _longActingController = TextEditingController(); 
  final TextEditingController _shortActingController = TextEditingController();
  final TextEditingController _insulinToCarbController = TextEditingController();
  final TextEditingController _correctionFactorController = TextEditingController();

  String? _longActingError;
  String? _shortActingError;
  String? _insulinToCarbError;
  String? _correctionFactorError;
  bool _isAgreedToTerms = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(23.0, 24.0, 23.0, 23.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyBackButton(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 0),
                child: Text(
                  'Welcome, ${widget.firstName}!',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 36,
                        letterSpacing: 0.0,
                        color: const Color(0xFF333333),
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 20),
                child: Text(
                  'Please fill out the form to help us support your diabetes management.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 19,
                        color: const Color(0xFF666666),
                        letterSpacing: 0.0,
                      ),
                ),
              ),
              _buildInputField(
                context,
                title: 'How many ',
                highlightedText: 'long-acting ',
                description: 'insulin units do you take daily? *',
                controller: _longActingController,
                errorText: _longActingError,
              ),
              _buildInputField(
                context,
                title: 'How many ',
                highlightedText: 'short-acting ',
                description: 'insulin units do you take daily? *',
                controller: _shortActingController,
                errorText: _shortActingError,
              ),
              _buildInputField(
                context,
                title: 'What is your ',
                highlightedText: 'Insulin-to-Carbohydrate ',
                description: 'ratio?',
                controller: _insulinToCarbController,
                errorText: _insulinToCarbError,
                hintText: 'Optional', // Add Optional as hint text
              ),
              _buildInputField(
                context,
                title: 'What is your ',
                highlightedText: 'Sensitivity ',
                description: 'factor?',
                controller: _correctionFactorController,
                errorText: _correctionFactorError,
                hintText: 'Optional', // Add Optional as hint text
              ),
              Row(
                children: [
                  Checkbox(
                    value: _isAgreedToTerms,
                    onChanged: null, 
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        // Navigate to Terms of Use page
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TermsOfUsePage(
                              onAgreement: (agreed) {
                                setState(() {
                                  _isAgreedToTerms = agreed;
                                });
                              },
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'I agree to the Terms of Use',
                        style: TextStyle(
                          color: const Color(0xFF023B95),
                          decoration: TextDecoration.underline,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              CustomButton(
                text: 'Create Account',
                onPressed: () async {
                  // Step 1: Validate the insulin input
                  _validateInsulinInput(context);

                  // Only proceed if there are no validation errors
                  if (_longActingError == null && _shortActingError == null && _insulinToCarbError == null && _correctionFactorError == null) {
                    // Step 2: Show the confirmation dialog and capture the result (true for Confirm, false for Cancel)
                    bool confirmed = await _showConfirmationDialog(context);

                    // If the user cancels the confirmation dialog, stop here
                    if (!confirmed) return;

                    // Step 3: Check if the user has agreed to the terms
                    if (!_isAgreedToTerms) {
                      _showTermsNotAgreedDialog(context);
                      return;
                    }

                    // Step 4: Proceed with signing up the user in Firebase Auth and Firestore
                    try {
                      await AuthService().signUpWithEmail(
                        email: widget.email.trim().toLowerCase(),
                        password: widget.password,
                        firstName: widget.firstName,
                        lastName: widget.lastName,
                        weight: double.parse(widget.weight),
                        height: double.parse(widget.height),
                        dateOfBirth: widget.selectedDate!,
                        dailyBasal: double.parse(_longActingController.text),
                        dailyBolus: double.parse(_shortActingController.text),
                        carbRatio: _insulinToCarbController.text.isNotEmpty 
                          ? double.parse(_insulinToCarbController.text) 
                          : double.parse((500/(double.parse(_longActingController.text)+double.parse(_shortActingController.text))).toStringAsFixed(2)),
                        correctionRatio: _correctionFactorController.text.isNotEmpty 
                          ? double.parse(_correctionFactorController.text) 
                          : double.parse((1800/(double.parse(_longActingController.text)+double.parse(_shortActingController.text))).toStringAsFixed(2)),
                        gender: widget.isMale ?? false,  
                      );

                      // Step 5: Show success dialog and navigate to the Home page
                      _showSuccessDialog(context);
                    } catch (e) {
                      // Step 4b: Show error dialog if sign-up fails
                      _showErrorDialog(context, 'Sign-up failed', e.toString());
                    }
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center( 
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                      children: [
                        const TextSpan(
                          text: 'Already have an account? ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                          ),
                        ),
                        TextSpan(
                          text: 'Log in',
                          style: const TextStyle(
                            color: Color(0xFF023B96),
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Navigate to the logIn page
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => logIn()),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _validateInsulinInput(BuildContext context) { 
    setState(() {
      // Reset error messages
      _longActingError = null;
      _shortActingError = null;
      _insulinToCarbError = null;
      _correctionFactorError = null;

      // Validate long-acting (basal) insulin range
      if (_longActingController.text.isNotEmpty) {
        double? longActing = double.tryParse(_longActingController.text);
        if (longActing == null || longActing <= 0) {
          _longActingError = 'Please enter a valid long-acting insulin unit.';
        } else {
          _longActingError = null;
        }
      } else {
        _longActingError = 'Please enter your long-acting insulin units.';
      }

      // Validate short-acting (bolus) insulin range
      if (_shortActingController.text.isNotEmpty) {
        double? shortActing = double.tryParse(_shortActingController.text);
        if (shortActing == null || shortActing <= 0) {
          _shortActingError = 'Please enter a valid short-acting insulin unit.';
        } else {
          _shortActingError = null; 
        }
      } else {
        _shortActingError = 'Please enter your short-acting insulin units.';
      }

      // Validate insulin-to-carb ratio (if provided)
      if (_insulinToCarbController.text.isNotEmpty) {
        double? insulinToCarb = double.tryParse(_insulinToCarbController.text);
        if (insulinToCarb == null || insulinToCarb <= 0) {
          _insulinToCarbError = 'Please enter a valid insulin-to-carbohydrate ratio.';
        }
      }

      // Validate correction factor (if provided)
      if (_correctionFactorController.text.isNotEmpty) {
        double? correctionFactor = double.tryParse(_correctionFactorController.text);
        if (correctionFactor == null || correctionFactor <= 0) {
          _correctionFactorError = 'Please enter a valid correction factor.';
        }
      }
    });
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    double longActing = double.tryParse(_longActingController.text) ?? 0;
    double shortActing = double.tryParse(_shortActingController.text) ?? 0;

    double? weightValue;
    try {
      weightValue = double.parse(widget.weight);
    } catch (e) {
      _showWarningDialog(context, 'Invalid Weight Input', 'Please enter a valid weight value.');
      return false; 
    }

    if (weightValue > 0) {
      double minTDD = 0.4 * weightValue;
      double maxTDD = 1.0 * weightValue;
      double minBasal = 0.4 * minTDD;
      double maxBasal = 0.5 * maxTDD;
      double minBolus = 0.5 * minTDD;
      double maxBolus = 0.6 * maxTDD;

      bool isHighDose = longActing > maxBasal * 1.5 || shortActing > maxBolus * 1.5;
      bool confirmed = false;

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.0), 
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Icon(
                  isHighDose ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: isHighDose
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
                SizedBox(width: 8), 
                Expanded( 
                  child: Text(
                    isHighDose ? 'Warning: Extremely High Insulin Dosage' : 'Confirm Insulin Dosage',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isHighDose
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  'You entered:\n'
                  'Long-acting insulin: $longActing units (Recommended: ${minBasal.toStringAsFixed(1)} - ${maxBasal.toStringAsFixed(1)} units)\n'
                  'Short-acting insulin: $shortActing units (Recommended: ${minBolus.toStringAsFixed(1)} - ${maxBolus.toStringAsFixed(1)} units)\n',
                  style: TextStyle(
                    fontSize: 16,
                    color: isHighDose ? Theme.of(context).colorScheme.error : Colors.black,
                  ),
                ),
                if (isHighDose)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'The entered insulin dose is extremely high and may cause hypoglycemia (low blood sugar). Please proceed with caution.\n',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded( 
                      child: Text(
                        'Calculations based on weight of ${weightValue?.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 16,
                          color: isHighDose
                              ? Theme.of(context).colorScheme.error
                              : Colors.black,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28.0), 
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.center, 
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Theme.of(context).colorScheme.primary, 
                                    size: 30,
                                  ),
                                  SizedBox(width: 10), 
                                  Text(
                                    'Formulas Used',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min, 
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'The following formulas are used to calculate the recommended insulin dosage:\n\n'
                                    'Total Daily Dosage (TDD): \n'
                                    'Min: 0.4 * weight (kg)\n'
                                    'Max: 1 * weight (kg)\n\n'
                                    'Basal (Long-acting) insulin: \n'
                                    'Min: 0.4 * Min TDD\n'
                                    'Max: 0.5 * Max TDD\n\n'
                                    'Bolus (Short-acting) insulin: \n'
                                    'Min: 0.5 * Min TDD\n'
                                    'Max: 0.6 * Max TDD',
                                    style: TextStyle(fontSize: 16, color: Colors.black), 
                                    textAlign: TextAlign.center, 
                                  ),
                                ],
                              ),
                              actionsPadding: EdgeInsets.symmetric(horizontal: 10), 
                              actions: [
                                Center( 
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                                      backgroundColor: Theme.of(context).colorScheme.primary, 
                                      foregroundColor: Colors.white, 
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Close',
                                      style: TextStyle(fontSize: 16), 
                                    ),
                                  ),
                                ),
                                SizedBox(height: 13),
                              ],
                            );
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: isHighDose
                              ? Theme.of(context).colorScheme.error
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "Are you sure you want to proceed with these dosages?",
                  style: TextStyle(
                    fontSize: 16,
                    color: isHighDose ? Theme.of(context).colorScheme.error : Colors.black,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); 
                        confirmed = false;
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                        backgroundColor: Colors.grey[200], 
                        foregroundColor:isHighDose
                              ? Theme.of(context).colorScheme.error
                              : Colors.black, 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); 
                        confirmed = true;
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                        backgroundColor: isHighDose
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary, 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Confirm'),
                    ),
                  ],
                ),
              ),
            ],
            backgroundColor: isHighDose
                ? Color.fromARGB(255, 235, 219, 224) 
                : Colors.white,
          );
        },
      );

      return confirmed;
    } else {
      _showWarningDialog(context, 'Invalid Weight', 'Please enter a valid weight greater than zero.');
      return false;
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        Future.delayed(Duration(seconds: 10), () {
          Navigator.of(context).pop(); 
          Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainNavigation()),
                      (Route<dynamic> route) => false, 
                    );
        });

        return Dialog(
          backgroundColor: const Color(0xFF023B95), 
          insetPadding: EdgeInsets.all(0), 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), 
          ),
          child: Container(
            width: MediaQuery.of(context).size.width, 
            height: MediaQuery.of(context).size.height, 
            padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF024BB1), Color(0xFF012A70)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 120, 
                  semanticLabel: 'Success Icon', 
                ),
                SizedBox(height: 30),
                Center(
                  child: Text(
                    'Welcome to InsulinSync!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30, 
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center, 
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Your account is all set up!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9), 
                      fontSize: 22, 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'We’re here to help you manage your diabetes with confidence. Let’s get started by tracking your blood glucose levels and optimizing your insulin dosage.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85), 
                      fontSize: 18,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainNavigation()),
                      (Route<dynamic> route) => false, 
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, 
                    elevation: 5, 
                    shadowColor: Colors.black.withOpacity(0.3), 
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), 
                    ),
                  ),
                  child: Text(
                    'Let’s Begin!',
                    style: TextStyle(
                      color: Color(0xFF023B95), 
                      fontSize: 18,
                      fontWeight: FontWeight.w700, 
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWarningDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0), 
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error, 
                size: 30,
              ),
              SizedBox(width: 10), 
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary, 
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.black), 
                textAlign: TextAlign.center, 
              ),
            ],
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 10), 
          actions: [
            Center( 
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  backgroundColor: Theme.of(context).colorScheme.primary, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16), 
                ),
              ),
            ),
            SizedBox(height: 13),
          ],
        );
      },
    );
  }

  void _showTermsNotAgreedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0), 
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary, 
                size: 30,
              ),
              SizedBox(width: 10), 
              Text(
                'Terms Not Agreed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'You must agree to the terms to proceed.',
                style: TextStyle(fontSize: 16, color: Colors.black), 
                textAlign: TextAlign.center, 
              ),
            ],
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 10), 
          actions: [
            Center( 
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); 
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  backgroundColor: Theme.of(context).colorScheme.primary, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 13),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0), 
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error, 
                size: 30,
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary, 
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.black), 
                textAlign: TextAlign.center, 
              ),
            ],
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 10), 
          actions: [
            Center( 
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); 
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  backgroundColor: Theme.of(context).colorScheme.primary, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16), 
                ),
              ),
            ),
            SizedBox(height: 13),
          ],
        );
      },
    );
  }



  Widget _buildInputField(
    BuildContext context, {
    required String title,
    required String highlightedText,
    required String description,
    required TextEditingController controller,
    String? errorText,
    String? hintText, // Add hintText parameter
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: const Color(0xFF333333),
                  ),
              children: [
                TextSpan(
                  text: highlightedText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF023B95),
                        fontSize: 16,
                      ),
                ),
                TextSpan(
                  text: description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF333333),
                        fontSize: 16,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary, 
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFF023B95),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 255, 255, 255),
              errorText: errorText,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              hintText: hintText, // Set hint text
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow decimal numbers
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Allow only numbers and a single decimal point
            ],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
} 


