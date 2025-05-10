import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/user_service.dart';
import '../models/contact_model.dart';
import 'EmergencyContacts.dart';

class EmergencyEdit extends StatefulWidget {
  final Contact contact;

  EmergencyEdit({required this.contact});

  @override
  State<EmergencyEdit> createState() => _EmergencyEditState();
}

class _EmergencyEditState extends State<EmergencyEdit> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _minThresholdController;
  late TextEditingController _maxThresholdController;
  late FocusNode _nameFocusNode;
  late FocusNode _phoneFocusNode;
  late FocusNode _minThresholdFocusNode;
  late FocusNode _maxThresholdFocusNode;
  bool _notificationsEnabled = true;

  final _nameErrorNotifier = ValueNotifier<String?>(null);
  final _phoneErrorNotifier = ValueNotifier<String?>(null);
  final _minErrorNotifier = ValueNotifier<String?>(null);
  final _maxErrorNotifier = ValueNotifier<String?>(null);

  // Keep track of submission attempt
  bool _submitted = false;

  Future<void> _validateForm() async {
    setState(() => _submitted = true);

    // Validate all fields
    final nameError = await NameValidator(_nameController.text);
    final phoneError = await validatePhoneNumber(_phoneController.text);
    final minError = await MinValidator(_minThresholdController.text);
    final maxError = await MaxValidator(_maxThresholdController.text);

    // Update error states
    _nameErrorNotifier.value = nameError;
    _phoneErrorNotifier.value = phoneError;
    _minErrorNotifier.value = minError;
    _maxErrorNotifier.value = maxError;

    // Only proceed if all validations pass
    if (nameError == null &&
        phoneError == null &&
        minError == null &&
        maxError == null) {
      _updateContactInfo();
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing contact data
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneController = TextEditingController(text: widget.contact.phoneNumber);
    _minThresholdController =
        TextEditingController(text: widget.contact.minThreshold.toString());
    _maxThresholdController =
        TextEditingController(text: widget.contact.maxThreshold.toString());

    _nameFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _minThresholdFocusNode = FocusNode();
    _maxThresholdFocusNode = FocusNode();
    _notificationsEnabled = widget.contact.sendNotifications;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _minThresholdController.dispose();
    _maxThresholdController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _minThresholdFocusNode.dispose();
    _maxThresholdFocusNode.dispose();
    super.dispose();
  }

  Future<void> _updateContactInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final UserService userService = UserService();
      final bool phoneNumberChanged =
          _phoneController.text != widget.contact.phoneNumber;

      Contact updatedContact = Contact(
        id: widget.contact.id, // Keep the same Firestore document ID
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        status: widget.contact.status,
        lastNotified: widget.contact.lastNotified,
        sendNotifications: _notificationsEnabled,
        minThreshold: int.parse(_minThresholdController.text),
        maxThreshold: int.parse(_maxThresholdController.text),
      );

      // if the phone number is changed
      if (phoneNumberChanged) {
        // Show a explaintory message
        showDialog(
          context: context,
          builder: (BuildContext context) {
            String num = _phoneController.text;

            return AlertDialog(
              contentPadding: EdgeInsets.all(16),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Color.fromARGB(200, 210, 227, 255),
                      child: Icon(
                        FontAwesomeIcons.hourglassHalf,
                        size: 80,
                        color: Color(0xFF023B96),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'This contact is added but not yet activaited!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      "We will send a WhatsApp message to $num asking for their approval. This contact will appear in your list, but will not be active until they confirm.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    //buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF023B96),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(120, 44),
                            ),
                            child: Text(
                              'Cancel',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              Navigator.of(context)
                                  .pop(); // Close the current dialog

                              UserService service = UserService();
                              Contact updatedContact2 = Contact(
                                id: widget.contact.id,
                                name: _nameController.text,
                                phoneNumber: _phoneController.text,
                                status: "pending",
                                lastNotified: widget.contact.lastNotified,
                                sendNotifications: _notificationsEnabled,
                                minThreshold:
                                    int.parse(_minThresholdController.text),
                                maxThreshold:
                                    int.parse(_maxThresholdController.text),
                              );

                              if (await service
                                  .updateContact(updatedContact2)) {
                                service.requestFollow(updatedContact2);

                                ///////////////////////////////////////////////////////////////////////////get out of the page
                              } else {
                                // Show error dialog if update fails
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
                                            color: Color.fromARGB(
                                                255, 194, 43, 98),
                                            size: 80,
                                          ),
                                          SizedBox(height: 25),
                                          Text(
                                            'Failed updating the contact!',
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
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  Color(0xff023b96),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              minimumSize: Size(100, 44),
                                            ),
                                            child: Text(
                                              'Close',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Color(0xFF023B96)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(120, 44),
                            ),
                            child: Text(
                              'Ok',
                              style: TextStyle(
                                  color: Color(0xFF023B96), fontSize: 16),
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
      } // if the changed info is anything but phone number
      else {
        bool success = await userService.updateContact(updatedContact);
        if (success) {
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
                      'Contact is updated successfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22),
                    ),
                    SizedBox(height: 30),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EmergencyContacts()),
                          (Route<dynamic> route) => false,
                        );
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
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => EmergencyContacts()),
              (Route<dynamic> route) => false,
            );
          });
        } else {
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
                      'Failed updating the contact!',
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
                    // Center the button
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Color(0xff023b96),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize:
                            Size(100, 44), // Make buttons the same size
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
    } catch (e) {
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
                  'Failed updating the contact!',
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
                // Center the button
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xff023b96),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(100, 44), // Make buttons the same size
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

  Future<String?> NameValidator(String? value) async {
    if (value == null || value.isEmpty) {
      return 'Please enter a name';
    }
    return null;
  }

  Future<String?> validatePhoneNumber(String? value) async {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a phone number';
    }

    String sanitizedValue = value.replaceAll(RegExp(r'[^\d+]'), '');

    if (!sanitizedValue.startsWith('+')) {
      return 'Please include country code (e.g., +966 for KSA)';
    }

    if (sanitizedValue.length < 10 || sanitizedValue.length > 15) {
      return 'Phone number must be 10-15 digits including country code';
    }

    UserService service = UserService();
    bool isDuplicate = await service.isPhoneNumberExists(sanitizedValue,
        excludeContactId: widget.contact.id);

    if (isDuplicate) {
      return 'This phone number is already registered as a contact';
    }

    return null;
  }

  Future<String?> MinValidator(String? value) async {
    if (value == null || value.isEmpty)
      return 'Please enter a Mix Blood Glucos';
    if (int.tryParse(value) == null) return 'Please enter a valid number';

    return null;
  }

  Future<String?> MaxValidator(String? value) async {
    if (value == null || value.isEmpty)
      return 'Please enter a Max Blood Glucos';
    if (int.tryParse(value) == null) return 'Please enter a valid number';
    if (int.parse(value) <= int.parse(_minThresholdController.text)) {
      return 'Max must be greater than Min';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 30.0),
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
                  color: Color(0xFF023B96),
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
                'Edit Emergency Contact',
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
                                  'Name',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                              _buildTextField("Name", _nameController,
                                  errorNotifier: _nameErrorNotifier,
                                  validator: NameValidator),
                              const Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: const Text(
                                  'Phone Number',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                              _buildTextField("Phone Number", _phoneController,
                                  isPhone: true,
                                  hintText: "+966123456789",
                                  errorNotifier: _phoneErrorNotifier,
                                  validator: validatePhoneNumber),
                              const Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: const Text(
                                  'Min Blood Glucose',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                              _buildTextField(
                                  "Min Blood Glucose", _minThresholdController,
                                  isNumeric: true,
                                  errorNotifier: _minErrorNotifier,
                                  validator: MinValidator),
                              const Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: const Text(
                                  'Max Blood Glucose',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                              _buildTextField(
                                  "Max Blood Glucose", _maxThresholdController,
                                  isNumeric: true,
                                  errorNotifier: _maxErrorNotifier,
                                  validator: MaxValidator),
                              const Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: const Text(
                                  'Reaching any of these limits will notify the emergency contact.',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Color(0xFF8B97A2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20.0),
                              SwitchListTile(
                                value: _notificationsEnabled,
                                onChanged: (newValue) {
                                  setState(() {
                                    _notificationsEnabled = newValue;
                                  });
                                },
                                title: const Text(
                                  'Alerts',
                                  style: TextStyle(
                                    fontSize: 19.0,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Send alerts to this emergency contact.',
                                  style: TextStyle(color: Color(0xFF8B97A2)),
                                ),
                                activeTrackColor: Colors.green,
                                dense: false,
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                                child: ElevatedButton(
                                  onPressed: _validateForm,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(double.infinity, 44),
                                    backgroundColor: Color(0xFF023B96),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
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
                              const SizedBox(height: 40.0),
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
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumeric = false,
    bool isPhone = false,
    String? hintText,
    ValueNotifier<String?>? errorNotifier,
    Future<String?> Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: ValueListenableBuilder<String?>(
        valueListenable: errorNotifier!,
        builder: (context, error, _) {
          return TextFormField(
            controller: controller,
            keyboardType: isNumeric
                ? TextInputType.number
                : (isPhone ? TextInputType.phone : TextInputType.text),
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              filled: true,
              fillColor: Colors.grey[100],
              errorText:
                  _submitted ? error : null, // Only show error if submitted
              hintText: hintText,
            ),
          );
        },
      ),
    );
  }
}
