import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:insulin_sync/Setting.dart';
import '../services/user_service.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:cloud_firestore/cloud_firestore.dart';

import 'MainNavigation.dart';

class Personal extends StatefulWidget {
  const Personal({Key? key}) : super(key: key);

  @override
  State<Personal> createState() => _PersonalWidgetState();
}

class _PersonalWidgetState extends State<Personal> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _dobController;
  // Gender
  final List<String> _genderOptions = ['Male', 'Female'];
  String? _selectedGender;
  // DOB
  DateTime? _dateOfBirth;
  // Variable to store any error messages
  String? _error;

  late FocusNode _weightFocusNode; //////////////////////////////////////
  late FocusNode _heightFocusNode;

  bool _isLoading = false; // Add this line with your other state variables
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _dobController = TextEditingController();
    _fetchUserData();

    _weightFocusNode = FocusNode();
    _heightFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _weightFocusNode.dispose();
    _heightFocusNode.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final UserService userService = UserService();

      final gender = await userService.getUserAttribute('gender');
      final weight = await userService.getUserAttribute('weight');
      final height = await userService.getUserAttribute('height');
      final dobTimestamp = await userService.getUserAttribute('dateOfBirth');

      DateTime? dateOfBirth;

      // Case 1: Firestore Timestamp
      if (dobTimestamp is Timestamp) {
        dateOfBirth = dobTimestamp.toDate();
      }
      // Case 2: ISO-8601 String (e.g., "2023-01-01T00:00:00.000Z")
      else if (dobTimestamp is String) {
        dateOfBirth = DateTime.tryParse(dobTimestamp);
      }
      // Case 3: Epoch timestamp (String or int)
      if (dateOfBirth == null && dobTimestamp != null) {
        final int? epochTime = dobTimestamp is int
            ? dobTimestamp
            : int.tryParse(dobTimestamp.toString());
        if (epochTime != null) {
          dateOfBirth = DateTime.fromMillisecondsSinceEpoch(epochTime);
        }
      }

      // Fallback: Set to 18 years ago if null
      dateOfBirth ??= DateTime.now().subtract(Duration(days: 365 * 18));

      setState(() {
        _selectedGender = gender == true ? 'Male' : 'Female';
        _weightController.text = weight?.toString() ?? '';
        _heightController.text = height?.toString() ?? '';
        _dateOfBirth = dateOfBirth;
        _dobController.text = DateFormat.yMMMMd().format(dateOfBirth!);
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
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
  String? ageValidator(BuildContext context, DateTime? dateOfBirth) {
    if (dateOfBirth == null) {
      return 'Please select your date of birth';
    }
    DateTime today = DateTime.now();
    int age = today.year - dateOfBirth.year;

    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    if (age < 18) {
      return 'You must be at least 18 years old to use this app';
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
        gender:
            _selectedGender == 'Male', // Map the selected gender to a boolean
        weight: double.tryParse(_weightController.text),
        height: double.tryParse(_heightController.text),
        dateOfBirth: _dateOfBirth, // Convert the date of birth to a timestamp
      );

      // Show a success message after updating the info
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
                  'Personal information is updated successfully!',
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainNavigation(index: 3)),
          (Route<dynamic> route) => false,
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
    } finally {
      setState(() => _isSaving = false); // End saving
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      /////////////////////////////////////////////////////////////////////////////
      // Show an error message if something went wrong
      return Scaffold(
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Stack(children: [
      GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).primaryColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 30.0),
              onPressed: () => Navigator.of(context).pop(),
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
                    color: Color(0xFF023B96),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FontAwesomeIcons.fileSignature,
                    color: Colors.white,
                    size: 80.0,
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Personal Information',
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
                                    'Gender',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 6.0),
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 12.0,
                                          children:
                                              _genderOptions.map((gender) {
                                            return ChoiceChip(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 255, 255, 255),
                                              label: Text(
                                                gender,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                              selected:
                                                  _selectedGender == gender,
                                              selectedColor:
                                                  const Color(0x4C095AEC),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                side: BorderSide(
                                                  color: _selectedGender ==
                                                          gender
                                                      ? const Color(0xFF023B95)
                                                      : const Color.fromARGB(
                                                          255, 174, 171, 171),
                                                  width: 1.0,
                                                ),
                                              ),
                                              onSelected:
                                                  (bool selected) async {
                                                if (selected) {
                                                  setState(() {
                                                    _selectedGender = gender;
                                                  });

                                                  //     // Update the gender in the database
                                                  //     final userService =
                                                  //         Provider.of<UserService>(context, listen: false);
                                                  //     final bool isUpdated = await userService.updateUserAttributes(
                                                  //       gender: gender == 'Male' ? true : false, // Assuming true = Male, false = Female
                                                  //     );

                                                  //     if (!isUpdated) {
                                                  //       // Revert the selection if the update fails
                                                  //       setState(() {
                                                  //         _selectedGender =
                                                  //             gender == 'Male' ? 'Female' : 'Male'; // Fallback logic
                                                  //       });
                                                  //       ScaffoldMessenger.of(context).showSnackBar(
                                                  //         const SnackBar(
                                                  //           content: Text('Failed to update gender.'),
                                                  //         ),
                                                  //       );
                                                  //     } else {
                                                  //       ScaffoldMessenger.of(context).showSnackBar(
                                                  //         const SnackBar(
                                                  //           content: Text('Gender updated successfully.'),
                                                  //         ),
                                                  //       );
                                                  //     }
                                                }
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(
                                    'Weight (kg)',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 12.0),
                                  child: TextFormField(
                                    controller: _weightController,
                                    validator: weightValidator,
                                    focusNode: _weightFocusNode,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        FontAwesomeIcons.weight,
                                      ),
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
                                      // focusedBorder: OutlineInputBorder(
                                      //   borderRadius: BorderRadius.circular(12.0),
                                      //   borderSide: const BorderSide(
                                      //     color: Color.fromARGB(255, 168, 167, 167),
                                      //     width: 1.5,
                                      //   ),
                                      // ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(
                                    'Height (cm)',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 12.0),
                                  child: TextFormField(
                                    controller: _heightController,
                                    validator: heightValidator,
                                    focusNode: _heightFocusNode,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.height,
                                      ),
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
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Date of Birth',
                                        style: TextStyle(fontSize: 18.0),
                                      ),
                                      const SizedBox(height: 8), // Adds spacing
                                      TextFormField(
                                        controller: _dobController,
                                        readOnly:
                                            true, // Prevents manual text input
                                        validator: (value) {
                                          return ageValidator(
                                              context, _dateOfBirth);
                                        },
                                        onTap: () async {
                                          final pickedDate =
                                              await showDatePicker(
                                            context: context,
                                            initialDate: _dateOfBirth,
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (pickedDate != null) {
                                            setState(() {
                                              _dateOfBirth = pickedDate;
                                              _dobController.text =
                                                  DateFormat.yMMMMd()
                                                      .format(pickedDate);
                                            });
                                          }
                                        },
                                        style: const TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        decoration: InputDecoration(
                                          prefixIcon:
                                              const Icon(Icons.calendar_today),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            borderSide: const BorderSide(
                                              color: Color.fromARGB(
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
                                    ],
                                  ),
                                ),
                                // Save Button
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSaving ? null : _updateUserInfo,
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
                                          fontSize: 25.0, color: Colors.white),
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
    ]);
  }
}
