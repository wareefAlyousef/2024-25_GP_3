import 'package:flutter/material.dart';
import 'package:insulin_sync/Account.dart';
import 'package:insulin_sync/EmergencyContacts.dart';
import 'package:insulin_sync/ContactUs.dart';
import 'SettingsTerms.dart';
import 'package:insulin_sync/Personal.dart';
import 'package:insulin_sync/diabetes.dart';
import 'package:insulin_sync/notifications.dart';
import 'package:provider/provider.dart';
import 'deleteAccount.dart';
import 'splash.dart';
import 'widgets.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'services/cgm_auth_service.dart';
import 'package:insulin_sync/MainNavigation.dart';

class Setting extends StatefulWidget {
  @override
  _Setting createState() => _Setting();
}

class _Setting extends State<Setting> {
  late Future<bool> isCgmConnected;
  UserService userService = new UserService();
  CGMAuthService cgmAuthService = CGMAuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  String? _emailErrorMessage;
  String? _passwordErrorMessage;

  void initState() {
    isCgmConnected = userService.isCgmConnected();
  }

  Future<void> _showConfirmationDialogLogout(AuthService authService) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            contentPadding: EdgeInsets.all(16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Color(0xFFFFDCDC),
                    child: Icon(
                      Icons.logout,
                      size: 100,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Are You Sure You Want To Sign Out?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size(120, 44),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop(true);

                            await authService.signOut();

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OnboardingWidget()),
                              (Route<dynamic> route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size(120, 44),
                          ),
                          child: Text(
                            'Sign out',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ));
      },
    );
  }

  _showConfirmationDialogDeleteAccount(AuthService authService) {}

  Future<bool> _showConfirmationDialogLibre(String text) async {
    // Show the dialog and await its result
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(16),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Close dialog and return false (Cancel)
                          Navigator.of(context).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(120, 44),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Close dialog and return true (Confirm)
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(120, 44),
                        ),
                        child: Text(
                          'Confirm',
                          style: TextStyle(color: Colors.white),
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

    // Return the result, default to false if null (in case the dialog is dismissed without selection)
    return result ?? false;
  }

  Future<void> _showDialogLibreLoginStatus(bool isSuccess, bool isLogin) async {
    // Show the dialog
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel_outlined,
                color: isSuccess
                    ? Color(0xff023b96)
                    : Color.fromARGB(255, 194, 43, 98),
                size: 80,
              ),
              SizedBox(height: 25),
              Text(
                isLogin
                    ? (isSuccess
                        ? 'Connected to the CGM successfully'
                        : 'Failed to connect to the CGM. Please try again.')
                    : (isSuccess
                        ? 'Disconnected from the CGM successfully'
                        : 'Failed to disconnect from the CGM. Please try again.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22),
              ),
              SizedBox(height: 30),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => MainNavigation()),
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
              )
            ],
          ),
          actions: isSuccess
              ? []
              : [
                  Center(
                    // Center the button
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
    if (isSuccess) {
      // Wait for 3 seconds before closing the dialog and navigating
      await Future.delayed(Duration(seconds: 3));

      // Close the dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Navigate to MainNavigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainNavigation()),
      );
    }
  }

  Future<void> showResultDialog(
    bool isSuccess, {
    String? successMessage,
    String? errorMessage,
    String? detailedErrorMessage,
  }) async {
    // Show the dialog and await the result
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel_outlined,
                color: isSuccess
                    ? Color(0xff023b96)
                    : Color.fromARGB(255, 194, 43, 98),
                size: 80,
              ),
              SizedBox(height: 25),
              Text(
                isSuccess
                    ? successMessage ?? 'Operation was successful!'
                    : errorMessage ?? 'Operation failed!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22),
              ),
              if (!isSuccess && detailedErrorMessage != null) ...[
                SizedBox(height: 15),
                Text(
                  detailedErrorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ],
          ),
        );
      },
    );

    // If success, navigate after 3 seconds
    if (isSuccess) {
      // Wait for 3 seconds
      await Future.delayed(Duration(seconds: 3));

      // Dismiss the dialog manually
      Navigator.pop(context);

      // Now navigate to the next screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainNavigation()),
        (Route<dynamic> route) => false,
      );
    } else {
      print('Operation failed, no success action taken');
    }
  }

  void showSlideShowOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(4),
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (stfContext, stfSetState) {
              return Container(
                height: MediaQuery.of(stfContext).size.height * 0.6,
                width: MediaQuery.of(stfContext).size.width * 0.92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: PageController(viewportFraction: 0.85),
                            itemCount: 4,
                            onPageChanged: (int index) {
                              stfSetState(() {});
                            },
                            itemBuilder: (context, index) {
                              return AnimatedContainer(
                                duration: Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                padding: EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: _buildSlideContent(
                                    stfContext, index, stfSetState),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSlideContent(
      BuildContext context, int index, Function stfSetState) {
    List<Widget> slides = [
      // Slide 1
      Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Image.asset('images/FSicon.png', height: 100),
                ),
                SizedBox(height: 16),
                Container(
                  width: double
                      .infinity, // Ensures the text container takes the full width available
                  padding: EdgeInsets.symmetric(
                      horizontal: 0), // Add padding to prevent overflow
                  child: Text(
                    'Step 1: Set Up and Connecting LibreLink to Your CGM',
                    textAlign:
                        TextAlign.center, // Centers text within the container
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF023B96),
                    ),
                  ),
                ),
                SizedBox(height: 27),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-1.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Download ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: ' on your phone.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-2.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text:
                              'Log in or Sign up using your email and password.',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-3.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Connect your Libre 2 CGM sensor to ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      // Slide 2
      Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Image.asset('images/LLUicon.png', height: 100),
                ),
                SizedBox(height: 20),
                Container(
                  width: double
                      .infinity, // Ensures the text container takes the full width available
                  padding: EdgeInsets.symmetric(
                      horizontal: 0), // Add padding to prevent overflow
                  child: Text(
                    'Step 2: Set Up LibreLinkUp',
                    textAlign:
                        TextAlign.center, // Centers text within the container
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF023B96),
                    ),
                  ),
                ),
                SizedBox(height: 27),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-1.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Download ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLinkUp',
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 238, 80, 0)),
                            ),
                            TextSpan(text: ' on your phone.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-2.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Sign up with a different email than your ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: ' account.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      // Slide 3
      Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Container(
                  width: double
                      .infinity, // Ensures the text container takes the full width available
                  padding: EdgeInsets.symmetric(
                      horizontal: 0), // Add padding to prevent overflow
                  child: Text(
                    'Step 3: Linking LibreLinkUp to your LibreLink account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF023B96),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Image.asset('images/LLUicon.png', height: 40),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'In ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLinkUp',
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 238, 80, 0)),
                            ),
                            TextSpan(text: ' :'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-1.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text:
                              'Add yourself as a connection by searching your ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: ' email.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-2.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Send a follow request to your ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: ' account.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                Row(
                  children: [
                    Image.asset('images/FSicon.png', height: 40),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'In ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: ' :'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-1.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Approve the follow request notification to link both accounts.',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      // Slide 4 (Form Slide)
      Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Container(
                  width: double
                      .infinity, // Ensures the text container takes the full width available
                  padding: EdgeInsets.symmetric(
                      horizontal: 0), // Add padding to prevent overflow
                  child: Text(
                    'Step 4: Connect InsulinSync with your CGM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF023B96),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(height: 1),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Input your ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLinkUp',
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 238, 80, 0)),
                            ),
                            TextSpan(
                                text: ' account details to complete setup:'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      buildTextField(
                          label: 'Email',
                          controller: _emailController,
                          validator: emailValidator,
                          icon: Icons.email,
                          errorText: _emailErrorMessage,
                          readOnly: false),
                      buildTextField(
                          label: 'Password',
                          isObscured: true,
                          controller: _passwordController,
                          validator: passwordValidator,
                          icon: Icons.lock,
                          errorText: _passwordErrorMessage,
                          readOnly: false),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await _loginUser(stfSetState);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          child: Text(
                            'Connect',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontSize: 19.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ];
    return slides[index];
  }

  Future<void> showSlideShowOverlaySignedIn(BuildContext context) async {
    print('showSlideShowOverlaySignedIn');
    String libreEmail = await userService.getUserAttribute('libreEmail');
    String libreName = await userService.getUserAttribute('libreName');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(4),
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (stfContext, stfSetState) {
              return Container(
                height: MediaQuery.of(stfContext).size.height * 0.6,
                width: MediaQuery.of(stfContext).size.width * 0.92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            padding: EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: _buildSlideContentSignedIn(
                                stfContext, libreEmail, libreName, stfSetState),
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSlideContentSignedIn(BuildContext context, String libreEmail,
      String libreName, Function stfSetState) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Container(
                width: double
                    .infinity, // Ensures the text container takes the full width available
                padding: EdgeInsets.symmetric(
                    horizontal: 0), // Add padding to prevent overflow
                child: Text(
                  'Connection state',
                  textAlign:
                      TextAlign.center, // Centers text within the container
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF023B96),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Your current connection information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildTextField(
                        controller: TextEditingController(text: '$libreEmail'),
                        icon: Icons.email,
                        label: 'Email',
                        readOnly: true),
                    buildTextField(
                        controller: TextEditingController(text: '$libreName'),
                        icon: Icons.person,
                        label: 'Full name',
                        readOnly: true),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await _logoutUser(stfSetState);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).colorScheme.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        child: Text(
                          'Disconnect',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: 19.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      {required String label,
      bool isObscured = false,
      required TextEditingController controller,
      required IconData icon,
      String? Function(String?)? validator,
      String? errorText,
      required bool readOnly}) {
    final FocusNode focusNode = FocusNode();

    Color borderColor = errorText != null && errorText.isNotEmpty
        ? Theme.of(context).colorScheme.error
        : Colors.transparent;

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
                fontSize: 16.0,
              ),
            ),
          ),
          Stack(
            children: [
              CustomTextFormField(
                controller: controller,
                focusNode: focusNode,
                validator: validator,
                obscureText: isObscured,
                autofillHint: AutofillHints.name,
                textInputAction: TextInputAction.next,
                prefixIcon: icon,
                readOnly: readOnly,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (errorText != null && errorText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Text(
                errorText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _logoutUser(Function stfSetState) async {
    bool logout = await _showConfirmationDialogLibre(
        'Are You Sure you want to disconnet from your Libre freestyle account?\nAll of your data will be removed');
    if (logout) {
      bool loggedout = await cgmAuthService.logout();
      await _showDialogLibreLoginStatus(loggedout, false);
    }
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    // Regular expression for validating email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    return null;
  }

  Future<void> _loginUser(Function stfSetState) async {
    stfSetState(() {
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      try {
        var isSignedIn = await cgmAuthService.signIn(
            _emailController.text.trim(), _passwordController.text.trim());

        print("cgmAuthService.errorMessage ${cgmAuthService.errorMessage}");

        stfSetState(() {
          _emailErrorMessage = cgmAuthService.errorMessage;
          _passwordErrorMessage = cgmAuthService.errorMessage;
        });

        if (!isSignedIn) {
          return;
        }

        var emailAccounts = await cgmAuthService.fetchPatients();

        _showEmailDialog(context, emailAccounts);
      } catch (e) {
        print('Login Error: $e');
      }
    }
  }

  void _showEmailChoiceDialog(BuildContext context, List<dynamic> emailAccounts,
      Function(String) onEmailSelected) {
    Map<String, dynamic>? selectedPatient;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          title: Text(
            'Select LibreLink account you want to follow:',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF023B96)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: emailAccounts.map((email) {
                return RadioListTile<Map<String, dynamic>>(
                  title: Text(
                    "${email['firstName']} ${email['lastName']}",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  value: email,
                  groupValue: selectedPatient,
                  activeColor:
                      Color(0xFF023B96), // Accent color for selected radio
                  onChanged: (Map<String, dynamic>? value) {
                    selectedPatient = value;
                    (context as Element).markNeedsBuild();
                  },
                );
              }).toList(),
            ),
          ),
          actionsPadding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 20),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop(true);
                      if (selectedPatient != null) {
                        bool? confirmationResult =
                            await _showConfirmationDialogLibre(
                                'Are You Sure Want to Follow ${selectedPatient!["firstName"]} ${selectedPatient!["lastName"]}');
                        if (confirmationResult == true) {
                          bool setAttributesResult = await cgmAuthService
                              .setAttributes(selectedPatient!);

                          await _showDialogLibreLoginStatus(
                              setAttributesResult, true);
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      backgroundColor: Color(0xFF023B96),
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
        );
      },
    );
  }

  void _handleEmailSelection(String selectedPatient) {
    print("Selected email: $selectedPatient");
  }

  void _showEmailDialog(BuildContext context, List<dynamic> emailAccounts) {
    _showEmailChoiceDialog(context, emailAccounts, _handleEmailSelection);
  }

  void _showLoginSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(Duration(seconds: 4), () {
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
            padding:
                const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
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
                    'You have successfully Connected to your CGM.',
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
                    'Let’s continue optimizing your care and keeping your glucose levels in check',
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
                    'Continue',
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

  // List of images and destinations
  final List<Map<String, dynamic>> gridItems = [
    {"image": "images/Account.png", "page": Account()},
    {"image": "images/Personal_Information.png", "page": Personal()},
    {"image": "images/Diabetes_Info.png", "page": Diabetes()},
    {"image": "images/Notifications.png", "page": notifications()},
    {"image": "images/Emergency.png", "page": EmergencyContacts()},
    {"image": "images/CGM_Connection.png", "isButton": true},
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      backgroundColor: Color(0xFFf1f4f8),
      body: SingleChildScrollView(
        child: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(7.0, 7.0, 7.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        width: 357.0,
                        height: 50.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Settings',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    letterSpacing: 0,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                            NeverScrollableScrollPhysics(), // Prevent scrolling inside grid
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio:
                              0.75, // Adjust for image proportions
                        ),
                        itemCount: gridItems.length,
                        itemBuilder: (context, index) {
                          // Special handling for the CGM connection button
                          if (gridItems[index]["isButton"] == true) {
                            return GestureDetector(
                              onTap: () async {
                                bool isConnected =
                                    await userService.isCgmConnected();
                                if (isConnected) {
                                  await showSlideShowOverlaySignedIn(context);
                                } else {
                                  showSlideShowOverlay(context);
                                }
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    gridItems[index]["image"],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          }

                          // Normal grid items that navigate to pages
                          return GestureDetector(
                            onTap: () {
                              // Navigate to the specific screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      gridItems[index]["page"],
                                ),
                              );
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  gridItems[index]["image"],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 45.0),
                      Align(
                        alignment:
                            Alignment.centerLeft, // This forces left alignment
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(
                              16.0, 0.0, 40.0, 5.0), // Added left padding
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              'Help',
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Color.fromARGB(255, 120, 120, 120),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactUsScreen(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              color: Color(0xFF023B96), // Icon color
                              size: 25.0,
                            ),
                            SizedBox(width: 10.0),
                            Text(
                              'Contact Us',
                              style: TextStyle(
                                fontSize: 20,
                                color: Color.fromRGBO(
                                    70, 70, 70, 1), // Darker grey
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize:
                              Size(double.infinity, 60), // Increased height
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsTerms(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.fileSignature,
                              color: Color(0xFF023B96), // Icon color
                              size: 25.0,
                            ),
                            SizedBox(width: 10.0),
                            Text(
                              'Terms and Conditions',
                              style: TextStyle(
                                fontSize: 20,
                                color: Color.fromRGBO(
                                    70, 70, 70, 1), // Darker grey
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize:
                              Size(double.infinity, 60), // Increased height
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 45.0),
                      ElevatedButton(
                        onPressed: () async {
                          await _showConfirmationDialogLogout(authService);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Theme.of(context).colorScheme.error,
                              size: 25.0,
                            ),
                            SizedBox(width: 10.0),
                            Text(
                              'Sign out',
                              style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize:
                              Size(double.infinity, 60), // Increased height
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DeleteAccount(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.userTimes,
                              color: Colors.white,
                              size: 22.0,
                            ),
                            SizedBox(width: 10.0),
                            Text(
                              'Delete Account',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          minimumSize: Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}
