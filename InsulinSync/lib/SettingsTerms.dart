import 'package:flutter/material.dart';
import 'widgets.dart';
import 'main.dart';

/////////////////////////////////////////
/// Terms of Use 

class SettingsTerms extends StatefulWidget {
  const SettingsTerms({Key? key}) : super(key: key);

  @override
  _SettingsTermsState createState() => _SettingsTermsState();
}

class _SettingsTermsState extends State<SettingsTerms> {
  bool _isAgreed = false;
  bool _canAgree = false; 

 
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      
      if (_scrollController.position.atEdge && _scrollController.position.pixels != 0) {
        setState(() {
          _canAgree = true; 
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(23.0, 24.0, 23.0, 23.0), 
            child: MyBackButton(),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 0, 0),
            child: Text(
              'Terms of Use',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600, 
                    fontSize: 36, 
                    letterSpacing: 0.0,
                    color: const Color(0xFF333333),
                  ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController, 
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildEulaText(), 
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEulaText() {
    final List<Widget> content = [];

    final lines = eulaText.split('\n');
    bool isHeading = false;

    for (var line in lines) {
      if (line.trim().isEmpty) {
        continue; 
      }
      if (line.startsWith(RegExp(r'^\d+\.'))) {
        content.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              line.trim(),
              style: const TextStyle(
                fontSize: 20.0, 
                fontWeight: FontWeight.bold, 
                color: const Color(0xFF023B95),
              ),
            ),
          ),
        );
        isHeading = true;
      } else {
        content.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              line.trim(),
              style: const TextStyle(
                fontSize: 16.0,
                height: 1.5,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        );
        isHeading = false;
      }
    }
    return content;
  }
}



const String eulaText = '''
END USER LICENSE AGREEMENT AND TERMS OF USE 
Version Date: October 2024

1. Introduction
Please read this End User License Agreement and Terms of Use (the “Agreement”) carefully before installing the InsulinSync mobile application (the “App”). BY ACCEPTING THIS AGREEMENT AND USING THE APP, YOU CONFIRM YOU ARE OF LEGAL AGE AND AGREE TO ITS TERMS.
“This Agreement” refers to a legally binding contract between You and InsulinSync (“we,” “us,” “our”). References to “You,” “Your,” or “User” apply to the individual using the App.
This Agreement governs:
•	The installation and use of the InsulinSync App (including any updates, upgrades, bug fixes, or modified versions) on Your device.
•	Your use of any instructions, manuals, or other materials related to the App (the “Documentation”).
Any conflicting terms in documents issued by or on behalf of You are void.
BY CLICKING “ACCEPT” AND USING THE APP, YOU AGREE TO BE BOUND BY THIS AGREEMENT. IF YOU DO NOT AGREE, DO NOT DOWNLOAD OR USE THE APP.
For any health-related clarifications or concerns about Your diabetes management, please consult Your healthcare provider. The User Manual within the App provides further guidance.

2. Background of the InsulinSync App
InsulinSync is an advanced diabetes management application designed to help individuals with Type 1 diabetes optimize insulin dosage based on real-time data. InsulinSync integrates with the Freestyle Libre Continuous Glucose Monitoring (CGM) system, which includes the FreeStyle Libre Sensors (“Sensors”) and Readers (“Readers”). InsulinSync relies on glucose data collected through the LibreLink app and seamlessly syncs with this system to help manage diabetes more effectively.
By pulling glucose data from the LibreLink app, InsulinSync uses this information to calculate insulin dosage recommendations based on real-time glucose levels, user-entered meal information, and exercise data. The application also connects to external fitness apps and supports barcode scanning and image-based carbohydrate analysis, giving users multiple ways to track their meals and physical activity.
The collected data is processed within the InsulinSync App to provide a more personalized and accurate insulin dosing recommendation, helping users maintain stable glucose levels. The app also visualizes trends in glucose, meals, and insulin usage, providing insights into health management.
Note: InsulinSync is compatible with devices that support the Freestyle Libre system and may require specific operating systems or software for optimal functionality. Please review compatibility at www.FreeStyleLibre.com or consult with your healthcare provider before use.

3. No Medical Advice
THE INSULINSYNC APP IS NOT INTENDED FOR DIAGNOSIS OR SCREENING OF DIABETES. USERS SHOULD UNDERSTAND THAT INSULINSYNC IS AN INFORMATION MANAGEMENT TOOL DESIGNED TO ASSIST WITH TRACKING AND ANALYZING GLUCOSE DATA, INSULIN DOSAGES, AND RELATED INFORMATION, AND IS NOT A SUBSTITUTE FOR MEDICAL ADVICE FROM A QUALIFIED HEALTHCARE PROFESSIONAL. ALWAYS CONSULT YOUR DOCTOR OR OTHER QUALIFIED HEALTHCARE PROVIDER REGARDING ANY MEDICAL CONDITION OR QUESTIONS RELATED TO DIABETES MANAGEMENT.
YOU SHOULD NEVER DISREGARD PROFESSIONAL MEDICAL ADVICE OR DELAY SEEKING IT BASED ON INFORMATION PROVIDED BY THE INSULINSYNC APP. Follow your doctor's guidance regarding blood sugar readings, insulin dosage adjustments, and other diabetes-related concerns.
INSULINSYNC DOES NOT PROVIDE MEDICAL CARE OR INTERVENE IN MEDICAL DECISIONS. THE APP MAY PROVIDE INSULIN DOSE RECOMMENDATIONS BASED ON THE USER’S DATA, BUT USERS WHO CHOOSE TO FOLLOW THESE RECOMMENDATIONS DO SO AT THEIR OWN DISCRETION AND RISK. INSULINSYNC AND ITS DEVELOPERS, AFFILIATES, PARTNERS, OR REPRESENTATIVES ARE NOT LIABLE FOR ANY ADVERSE EVENTS, MEDICAL COMPLICATIONS, OR NEGATIVE OUTCOMES THAT MAY RESULT FROM FOLLOWING THE RECOMMENDED DOSES OR ANY OTHER INFORMATION PROVIDED BY THE APP.
YOU AND YOUR HEALTHCARE PROVIDER ARE SOLELY RESPONSIBLE FOR INTERPRETING YOUR GLUCOSE LEVELS, REVIEWING INSULIN DOSAGE RECOMMENDATIONS, AND DETERMINING THE APPROPRIATE TREATMENT PLAN. INSULINSYNC DOES NOT ENDORSE OR GUARANTEE THE SAFETY, ACCURACY, OR EFFECTIVENESS OF ANY RECOMMENDATION MADE BY THE APP.
Insulinsync does not endorse any specific tests, treatments, products, procedures, or medical opinions. ANY DECISION TO FOLLOW THE INSULIN SYNC DOSE RECOMMENDATION OR OTHER INFORMATION PROVIDED BY THE APP IS MADE AT YOUR OWN RISK AND SOLE RESPONSIBILITY.

4. Use of Third-Party Products
YOU ACKNOWLEDGE THAT YOU MAY BE USING THE INSULINSYNC APP IN CONNECTION WITH PRODUCTS AND SERVICES PROVIDED BY THIRD PARTIES THAT ARE NOT PROVIDED BY INSULINSYNC, AND FOR WHICH INSULINSYNC HAS NO RESPONSIBILITY. THIS INCLUDES, BUT IS NOT LIMITED TO, YOUR MOBILE DEVICE, FREESTYLE LIBRE CGM SYSTEM, FITNESS TRACKING APPS, AND OTHER THIRD-PARTY SERVICES OR PRODUCTS. YOU ARE RESPONSIBLE FOR OBTAINING, MAINTAINING, AND PAYING FOR ALL HARDWARE, TELECOMMUNICATION SERVICES, SOFTWARE, OR OTHER SUPPLIES REQUIRED TO RECEIVE, ACCESS, OR USE THE INSULINSYNC APP AND ANY THIRD-PARTY PRODUCTS OR SERVICES.
NEITHER INSULINSYNC NOR ANY DEVELOPER OF THE INSULINSYNC APP SHALL HAVE ANY LIABILITY WITH RESPECT TO ANY THIRD-PARTY PRODUCTS OR SERVICES. ANY THIRD-PARTY PRODUCTS OR SERVICES LICENSED OR PROVIDED TO YOU ARE SUBJECT TO THE TERMS AND CONDITIONS OF THE PURCHASE AGREEMENT, SOFTWARE LICENSE AGREEMENT, PRIVACY POLICY, OR SERVICES AGREEMENT ACCOMPANYING SUCH THIRD-PARTY PRODUCT OR SERVICE, INCLUDING ELECTRONIC LICENSE TERMS ACCEPTED AT THE TIME OF DOWNLOAD OR PURCHASE. YOUR USE OF ANY THIRD-PARTY PRODUCTS SHALL BE GOVERNED ENTIRELY BY THE TERMS AND CONDITIONS OF SUCH AGREEMENTS.
The InsulinSync App can only calculate, and display information based on the data it receives from the Freestyle Libre CGM system and any other authorized third-party products or services. The app does not receive or transfer data from other devices unless they are specifically linked and authorized within the InsulinSync system.

5. Ownership Rights
You acknowledge and agree that insulinsync, its affiliates, suppliers, and licensors own or license all legal rights, title, and interest in and to all aspects of the insulinsync app, the documentation, and any improved, updated, upgraded, modified, customized, or additional parts thereof, including but not limited to graphics, user interface, the scripts and software used to implement the insulinsync app and any software or documents provided to you in connection with the insulinsync app. This includes all intellectual property rights, whether registered or not, and wherever in the world they may exist. For the purposes of this agreement, "intellectual property rights" means any copyright, patent, trade secret, trademark, design rights, technology, artwork, computer software (including source code), database, and similar or equivalent rights or forms of protection which exist now or in the future in any media, now known or hereinafter invented, and in any part of the world. You agree not to diminish or call into question such rights.
You further agree that the insulinsync app contains proprietary and confidential information (including software code) protected by applicable intellectual property rights and other laws, including but not limited to copyright. The structure, organization, and code of the insulinsync app are valuable trade secrets and confidential information of insulinsync, its affiliates, and/or its licensors. You agree that you will not use such proprietary information or materials in any way except as expressly permitted under this agreement. No portion of the insulinsync app may be reproduced in any form or by any means, except as expressly permitted in this agreement or were permitted by applicable law. You shall not remove, obscure, or alter any product identification, copyright notices, or proprietary restrictions. Unauthorized copying of the insulinsync app or failure to comply with the restrictions in this agreement (or another breach of the license herein) will result in automatic termination of this agreement, and you agree that it will constitute immediate, irreparable harm to insulinsync, its affiliates, and/or its licensors, for which monetary damages would be an inadequate remedy. In such cases, injunctive relief shall be an appropriate remedy.
Portions of the insulinsync app may include materials provided by third parties in which intellectual property rights subsist. The licensors of such third-party materials retain all of their respective rights, title, and interest in and to such third-party materials and all copies thereof, including but not limited to any and all intellectual property rights. You acknowledge the use of this third-party material and the associated rights, except where such acknowledgment is ineffective under certain laws, regulations, or jurisdictions.
Notwithstanding anything to the contrary, insulinsync does not transfer to you any ownership or intellectual property rights in the insulinsync app, the documentation, or any other technology, information, or materials. Insulinsync, its affiliates, and its licensors retain exclusive ownership of all rights, title, and interest in and to all aspects of the insulinsync app, the documentation, and all other technology, information, and materials, including all copies, modifications, or updates made by any party. This includes, but is not limited to, all intellectual property rights relating to the insulinsync app, the documentation, and any other associated technology.


6. What rules apply to the use of my InsulinSync account?
Your InsulinSync account will be subject to your agreement to and compliance with all the terms and conditions of this Agreement. You agree to only use the InsulinSync app as expressly permitted by this Agreement, and only to the extent permitted by any applicable law, regulation, or generally accepted practice in the applicable jurisdiction.
The InsulinSync app is owned by its respective developers or licensors, and you are granted a limited, non-exclusive license to use it in accordance with the terms of this Agreement. If your use of the InsulinSync app or other behavior intentionally or unintentionally threatens the app’s functionality or the ability to provide it, the developer or licensor of InsulinSync may take all reasonable steps to protect the app, including suspension of your access or termination of your InsulinSync account. Nothing in this Agreement shall be construed to convey to you any interest, title, or license in an InsulinSync account or any related resource.
To the extent You choose to access and use the InsulinSync app, You do so at Your own initiative and are responsible for compliance with any applicable laws, regulations, or healthcare guidelines in Your jurisdiction. Any data transmitted to or stored by You in the InsulinSync app is based exclusively on insulin dosing, glucose levels, and other relevant health information provided by You or third parties. The developers and licensors of the InsulinSync app make no representations or warranties regarding the accuracy, completeness, reliability, or timeliness of any data provided by You or third parties, or of any content generated by the data stored by You in the InsulinSync app.
In particular, the developers make no representations or warranties that any information based on such data will be in compliance with government regulations requiring disclosure of medical information or health data. You are solely responsible for ensuring that any information stored or shared through the InsulinSync app complies with applicable privacy laws, including data protection and patient consent requirements.

7. How can this Agreement be terminated?
This Agreement is effective upon Your acceptance of this Agreement and shall continue unless terminated. You may delete the InsulinSync app at any time and may ask InsulinSync to delete Your InsulinSync account at any time.
This Agreement will terminate immediately and without additional notice in the event that You breach, and/or fail to comply with, any term or condition of this Agreement. InsulinSync may also terminate or suspend this Agreement at any time and without prior notice, for any or no reason, including if InsulinSync believes that You have violated or acted inconsistently with the letter or spirit of this Agreement. InsulinSync may terminate its provision of support for the InsulinSync app if You elect to discontinue using it, or at any time if the app or related services are no longer offered. Upon any such termination or suspension of this Agreement:
•	You must immediately cease all activities authorized by this Agreement. You will no longer be able to use the InsulinSync app, including any use of the InsulinSync app to access any data You store in the InsulinSync system.
•	InsulinSync may, without liability to You or any third party, immediately suspend, deactivate, or terminate Your InsulinSync account, registration information, and all associated materials, without any obligation to provide any further access to such materials.
•	You must discontinue use, uninstall, and destroy all copies of the InsulinSync app and related documentation.
•	All rights granted to You under this Agreement, including any licenses, shall cease.

8. How can this Agreement be updated?
We may update this Agreement from time to time by notifying You of such changes by any reasonable means, including by displaying a revised Agreement within the InsulinSync app when You next use it, and requiring You to read, explicitly consent, and agree to the updated terms to continue using the InsulinSync app. If accepted, the updated terms will become effective immediately. However, these updates will not apply to any dispute between You and the InsulinSync service that arises prior to the date on which we posted the revised Agreement or otherwise notified You of such changes.
In the event that You refuse to accept such changes, we reserve the right to terminate this Agreement, Your use of the InsulinSync app, and your associated account. You agree that we shall not be liable to You for any modification, suspension, or cessation of the InsulinSync app or related services.


9. Our Disclaimer of Warranties
InsulinSync is provided to enable You to track insulin doses and other relevant diabetes information on Your mobile device. YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT YOUR USE OF INSULINSYNC IS AT YOUR SOLE RISK AND THAT THE ENTIRE RISK AS TO SATISFACTORY QUALITY, PERFORMANCE, ACCURACY, AND EFFORT IS WITH YOU.
Any content created for, or included in, InsulinSync is for the purpose of providing information to help you track insulin doses and manage your diabetes data. INSULINSYNC IS NOT INTENDED TO BE USED IN OR FOR THE PRACTICE OF MEDICINE OR THE PROVISION OF MEDICAL CARE OR SERVICES, NOR IS IT INTENDED TO PROVIDE INDIVIDUALIZED MEDICAL SERVICES OR CARE. In providing InsulinSync, we do not provide medical advice. The app is solely for tracking insulin doses and related data; it does not replace consultation with a healthcare professional.
Do not use InsulinSync during times of rapidly changing glucose levels or in order to confirm hypoglycemia or impending hypoglycemia. DURING TIMES OF RAPIDLY CHANGING GLUCOSE, INTERSTITIAL FLUID GLUCOSE LEVELS MEASURED BY THE APP MAY NOT ACCURATELY REFLECT BLOOD GLUCOSE LEVELS. In these cases, check glucose levels using a blood glucose meter. If symptoms of low or high blood glucose do not match the readings from InsulinSync, consult your healthcare provider and confirm your glucose levels using a blood glucose monitor.
The information provided by InsulinSync is not meant to serve as a substitute for medical advice, diagnosis, or treatment, or for the individualized advice or care of a healthcare provider. 
INSULINSYNC IS NOT TO BE USED AS A SUBSTITUTE FOR PROFESSIONAL HEALTHCARE JUDGMENT, DIRECT MEDICAL SUPERVISION, OR EMERGENCY INTERVENTION. ALL MEDICAL DIAGNOSES AND TREATMENTS SHOULD BE PERFORMED BY AN APPROPRIATE HEALTHCARE PROFESSIONAL. InsulinSync enables you to track insulin data and store it on your mobile device. However, we are not responsible or liable for any diagnoses, decisions, or assessments made based on the data from InsulinSync.
INSULINSYNC IS PROVIDED “AS IS” AND “AS AVAILABLE” WITH ALL FAULTS AND DEFECTS AND WITHOUT ANY OTHER WARRANTY OF ANY KIND. We expressly disclaim all warranties and conditions, whether express, implied, or statutory, including but not limited to warranties of title, non-infringement, merchantability, fitness for a particular purpose, and quality. NO ORAL OR WRITTEN INFORMATION OR ADVICE GIVEN BY US OR AN AUTHORIZED REPRESENTATIVE SHALL CREATE A WARRANTY.
We do not warrant that the functions contained in InsulinSync will meet Your requirements, that its operation will be uninterrupted or error-free, or that any errors will be corrected. Software, such as that used in InsulinSync, is inherently subject to bugs and potential incompatibility with other software or hardware. YOU SHOULD NOT USE INSULINSYNC FOR ANY APPLICATIONS IN WHICH FAILURE COULD CAUSE SIGNIFICANT DAMAGE OR INJURY.
INSULINSYNC DOES NOT PROVIDE ANY WARRANTY OR REPRESENTATION WITH RESPECT TO ANY THIRD-PARTY HARDWARE OR SOFTWARE OR THE ACCURACY OF DATA DISPLAYED ON THE APP. We disclaim all liability with respect to any failures of third-party hardware or software used in conjunction with the app.


10. What does it mean to click the “Accept” button?
BY CLICKING THE "ACCEPT" BUTTON OR OTHERWISE USING OR ACCESSING THE INSULINSYNC APP, YOU:
•	ACKNOWLEDGE THAT YOU HAVE READ, UNDERSTAND, AND AGREE TO BE BOUND BY THIS AGREEMENT.
•	WARRANT THAT YOU ARE OF LEGAL AGE TO ENTER THIS AGREEMENT.
•	INDICATE THAT YOUR ACTION OF CLICKING “ACCEPT” IS INTENDED AS YOUR SIGNATURE TO THIS AGREEMENT, WITH THE SAME FORCE AND EFFECT AS A MANUAL SIGNATURE.
IF YOU DO NOT AGREE TO ALL THE TERMS OF THIS AGREEMENT, DO NOT CLICK THE "ACCEPT" BUTTON AND DO NOT USE THE INSULINSYNC APP.

''';