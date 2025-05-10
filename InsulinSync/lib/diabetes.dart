import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'MainNavigation.dart';

class Diabetes extends StatefulWidget {
  const Diabetes({Key? key}) : super(key: key);

  @override
  State<Diabetes> createState() => _DiabetesWidgetState();
}

class _DiabetesWidgetState extends State<Diabetes> {
  // Controllers for editable fields
  late TextEditingController _longController;
  late TextEditingController _shortController;
  late TextEditingController _ratioController;
  late TextEditingController _correctionController;
  // Variable to store any error messages
  String? _error;
  bool _isLoading = false;

  late FocusNode _longFocusNode;
  late FocusNode _shortFocusNode;
  late FocusNode _ratioFocusNode;
  late FocusNode _correctionFocusNode;

  @override
  void initState() {
    super.initState();
    _longController = TextEditingController();
    _shortController = TextEditingController();
    _ratioController = TextEditingController();
    _correctionController = TextEditingController();
    _fetchUserData();

    _longFocusNode = FocusNode();
    _shortFocusNode = FocusNode();
    _ratioFocusNode = FocusNode();
    _correctionFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _longController.dispose();
    _shortController.dispose();
    _ratioController.dispose();
    _correctionController.dispose();
    _longFocusNode.dispose();
    _shortFocusNode.dispose();
    _ratioFocusNode.dispose();
    _correctionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true; // Show loading overlay
    });

    try {
      final UserService userService = UserService();

      final long = await userService.getUserAttribute('dailyBasal');
      final short = await userService.getUserAttribute('dailyBolus');
      final ratio = await userService.getUserAttribute('carbRatio');
      final correction = await userService.getUserAttribute('correctionRatio');

      // Update the UI state with the retrieved user data
      setState(() {
        _longController.text = long?.toString() ?? '';
        _shortController.text = short?.toString() ?? '';
        _ratioController.text = ratio?.toString() ?? '';
        _correctionController.text = correction?.toString() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString(); // Store the error message
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserInfo() async {
    try {
      final UserService userService = UserService();

      await userService.updateUserAttributes(
        dailyBasal: double.tryParse(_longController.text),
        dailyBolus: double.tryParse(_shortController.text),
        carbRatio: double.tryParse(_ratioController.text),
        correctionRatio: double.tryParse(_correctionController.text),
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
                  'Diabetes information are updated successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22),
                ),
                SizedBox(height: 30),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => MainNavigation(index: 3)),
                      (Route<dynamic> route) =>
                          false, // This removes all previous routes
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
    if (_error != null) {}

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
                      Icons.bloodtype_rounded,
                      color: Colors.white,
                      size: 80.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Diabetes Information',
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  child: const Text(
                                    'Daily long-acting units',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 12.0),
                                  child: TextFormField(
                                    controller: _longController,
                                    focusNode: _longFocusNode,
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
                                    'Daily short-acting units',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 12.0),
                                  child: TextFormField(
                                    controller: _shortController,
                                    focusNode: _shortFocusNode,
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
                                    'Insulin-to-Carbohydrate ratio',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 12.0),
                                  child: TextFormField(
                                    controller: _ratioController,
                                    focusNode: _ratioFocusNode,
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
                                    'Correction factor',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 12.0),
                                  child: TextFormField(
                                    controller: _correctionController,
                                    focusNode: _correctionFocusNode,
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
  }
}
