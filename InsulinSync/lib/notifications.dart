import 'package:flutter/material.dart';
import 'package:insulin_sync/Setting.dart';
import '../services/user_service.dart';
import 'MainNavigation.dart';

class notifications extends StatefulWidget {
  const notifications({Key? key}) : super(key: key);

  @override
  State<notifications> createState() => _notificationsWidgetState();
}

class _notificationsWidgetState extends State<notifications> {
  // Controllers for editable fields
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late FocusNode _minFocusNode;
  late FocusNode _maxFocusNode;
  bool _notificationsEnabled = true;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController();
    _maxController = TextEditingController();
    _fetchUserData();

    _minFocusNode = FocusNode();
    _maxFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _minFocusNode.dispose();
    _maxFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true; // Show loading overlay
    });

    try {
      final UserService userService = UserService();

      // Get attributes with fallback to default values
      int min =
          await userService.getUserAttribute('minRange') ?? 70; // Default value
      int max =
          await userService.getUserAttribute('maxRange') ?? 180; // Default value

      // Handle notifications setting
      bool notifications =
          await userService.getUserAttribute('recieveNotifications') ?? true;

      setState(() {
        _minController.text = min.toString();
        _maxController.text = max.toString();
        _notificationsEnabled = notifications is bool ? notifications : true;
        _isLoading = false;
      });
    } catch (e) {
      // Use default values if any error occurs
      // setState(() {
      setState(() {
        _error = e.toString(); // Store the error message
        _isLoading = false;
      });
    }
  }

  String? MinValidator(String? value) {
    if (value == null || value.isEmpty)
      return 'Please enter a Mix Blood Glucos';
    if (int.tryParse(value) == null) return 'Please enter a valid number';

    return null;
  }

  String? MaxValidator(String? value) {
    if (value == null || value.isEmpty)
      return 'Please enter a Max Blood Glucos';
    if (int.tryParse(value) == null) return 'Please enter a valid number';
    if (int.parse(value) <= int.parse(_minController.text)) {
      return 'Max must be greater than Min';
    }
    return null;
  }

  Future<void> _updateUserInfo() async {
    try {
      final UserService userService = UserService();

      await userService.updateUserAttributes(
        minRange: int.tryParse(_minController.text),
        maxRange: int.tryParse(_maxController.text),
        recieveNotifications: _notificationsEnabled,
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
                  'Notifications\' settings are updated successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22),
                ),
                SizedBox(height: 30),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => MainNavigation(index: 3)),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
          child: Text(
              'Error: $_error')); /////////////////////////////////////////////
    }

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
                      color: Color(0xFF023B96),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 80.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Notifications',
                    textAlign: TextAlign.start,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Notifications',
                                              style: TextStyle(
                                                fontSize: 19.0,
                                                letterSpacing: 0.0,
                                              ),
                                            ),
                                            SizedBox(height: 4.0),
                                            Text(
                                              'You will receive a notification when the specified blood glucose levels below are reached.',
                                              style: TextStyle(
                                                color: Color(0xFF8B97A2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                          width:
                                              4), ////////////////////////////
                                      Switch(
                                        value: _notificationsEnabled,
                                        onChanged: (newValue) {
                                          setState(() {
                                            _notificationsEnabled = newValue;
                                          });
                                        },
                                        activeTrackColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(
                                    'Minimum Blood Glucose',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 12.0),
                                  child: TextFormField(
                                    controller: _minController,
                                    validator: MinValidator,
                                    focusNode: _minFocusNode,
                                    keyboardType: TextInputType.number,
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
                                    'Maximum Blood Glucose',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 12.0),
                                  child: TextFormField(
                                    controller: _maxController,
                                    validator: MaxValidator,
                                    focusNode: _maxFocusNode,
                                    keyboardType: TextInputType.number,
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
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  child: const Text(
                                    'The specified minimum and maximum blood glucose levels will define the boundaries of the green range on your Glucose Trend Graph.',
                                    style: TextStyle(color: Color(0xFF8B97A2)),
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
    ;
  }
}
