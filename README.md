# 2024-25_GP_28

## InsulinSync

### Managing Insulin Dosages for Individuals with Type 1 Diabetes

Managing insulin dosages for individuals with Type 1 diabetes is a complex and high-stakes task due to the constant need to adjust for daily fluctuations in diet, exercise, and blood glucose levels. With the pancreas unable to produce insulin, external insulin administration becomes essential for survival. However, maintaining healthy blood sugar levels is challenging, as they are influenced by dynamic factors such as:

- Carbohydrate intake
- Physical activity
- Stress
- Illness
- Sleep

This variability makes precise insulin dosing difficult.

### Real-Life Example

For example, consuming a high-carbohydrate meal can cause blood glucose levels to spike, requiring a larger insulin dose, while exercise typically lowers blood glucose, necessitating a reduction in insulin or additional carbohydrate intake to prevent hypoglycemia. A person with Type 1 diabetes must balance these opposing effects daily.

**Consequences of Misjudging Insulin Needs:**

- **Too much insulin** may cause hypoglycemia during or after exercise.
- **Too little insulin** can result in hyperglycemia, leading to serious health risks such as:
  - Cardiovascular disease
  - Kidney failure
  - Nerve damage

Acute hypoglycemia can trigger symptoms like dizziness, confusion, seizures, unconsciousness, or even death if not treated promptly. This constant balancing act requires vigilance, flexibility, and real-time decision-making, often relying on personal intuition, which is not always reliable.

---

## Introducing: “InsulinSync”

To address these challenges, **InsulinSync** provides real-time insulin dosage recommendations by integrating data inputs from food intake, exercise, and current glucose readings. By offering tailored guidance based on real-time data, **InsulinSync** aims to minimize the risks associated with improper insulin management and empower users with safer, more effective diabetes control, ultimately enhancing their quality of life.

---

## The Solution

We propose developing an application, **“InsulinSync”**, to help people with Type 1 diabetes manage their insulin dosage and maintain normal blood glucose levels.

### Key Features of **InsulinSync**:

1. **Insulin Dosage Recommendations**  
   After entering a meal, the app calculates a recommended insulin dosage by considering the user’s glucose level, carbohydrate intake, and physical activity. The user verifies all data before processing.

2. **Continuous Glucose Monitoring Integration**  
   The app connects to a continuous glucose monitor to provide real-time glucose data and allow continuous tracking of glucose levels.

3. **Exercise Tracking Integration**  
   By synchronizing with health-related applications, **InsulinSync** tracks the user’s physical activity and adjusts insulin recommendations accordingly.

4. **Image-Based meal Analysis**  
   A built-in model estimates the carbohydrate content in meals based on images taken by the user. Simply upload or take a picture, and the app does the rest!

5. **Barcode Scanning for Nutritional Information**  
   Users can scan food product barcodes to retrieve nutritional information, particularly the carbohydrate content.

6. **Comprehensive Health Data Visualization**  
   The app visualizes glucose levels, insulin dosages, physical activity, and meal data, making it easy to track and manage health information.

---

## Benefits of **InsulinSync**

**InsulinSync** simplifies the process of calculating the correct insulin dosage and reduces the risk of human error. This leads to improved diabetes management, better health outcomes, and enhanced quality of life for individuals with Type 1 diabetes.

---

## Technology  
- ![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white) **Flutter**: An open-source framework to build an application’s user interface (UI) for cross-platform applications.
- ![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white) **Dart**: An object-oriented programming language for cross-platform applications.


- ![Node.js](https://img.shields.io/badge/Node.js-339933?logo=nodedotjs&logoColor=white) **Node.js**: JavaScript runtime environment that handles server-side operations.
- ![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white) **Python**: Employed for deep learning models and data processing tasks.


- ![Java](https://img.shields.io/badge/Java-ED8B00?logo=java&logoColor=white) **Java**: Used for native Android integrations and platform-specific functionalities.


- ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black) **Firebase**: A set of cloud-based development tools that helps developers build and manage their apps easily.
  - ![Firestore](https://img.shields.io/badge/Firestore-FF6F00?logo=firebase&logoColor=white) **Cloud Firestore**: A cloud-based NoSQL document database that is part of the Firebase platform.
  - ![Firebase Authentication](https://img.shields.io/badge/Firebase_Auth-FF6F00?logo=firebase&logoColor=white) **Firebase Authentication**: A service that simplifies the process of authenticating users with multiple authentication methods and is part of the Firebase platform.


## 🚀 Launching InsulinSync App

### Prerequisites

Before launching the Android version of this Flutter app, ensure you have the following set up on your system:

- Flutter SDK (Latest stable version)
- Android Studio
- Android device/emulator
- A device with Developer Mode enabled or an Android emulator running

You can verify Flutter installation with the following command:

```bash
flutter doctor
```

Ensure there are no issues with Android toolchain, Flutter, or device connection.

---

### Steps to Launch the App
#### 1. Clone the Repository
First, clone the repository to your local machine:
```bash
git clone https://github.com/wareefAlyousef/2024-25_GP_3.git
cd wareefAlyousef/2024-25_GP_3
```

#### 2. Install Dependencies
Run the following command to install all the required dependencies for the project:
```bash
flutter pub get
```
#### 3. Set Up an Android Emulator (Optional)
If you want to test on an emulator, follow these steps:
-Open Android Studio
-Go to AVD Manager (Click the device icon in the top toolbar)
-Create a new virtual device (if none exists)
-Choose a device (e.g., Pixel) and the desired API level (min API should match your `minSdkVersion` in `android/app/build.gradle`)
-Start the emulator

#### 4. Connect Your Android Device
If you are testing on a physical device:

- Enable Developer Mode and USB Debugging on your Android device.
- Connect the device via USB.
- Ensure the device is listed by running:
```bash
flutter devices
```

#### 5. Configure Build Settings (Optional)
If you need to adjust build settings like minSdkVersion or app permissions:

- Navigate to `android/app/build.gradle` for SDK configurations.
- Adjust `minSdkVersion` or `targetSdkVersion` if necessary.

#### 6. Build the APK (Optional)
To build the APK file, which you can manually install on a device or distribute, use the following command:
```bash
flutter build apk
```

This command will generate an APK file in the `build/app/outputs/flutter-apk/` directory. You can install it manually on your device or share it with others for testing.

Alternatively, to generate a release version of the APK (optimized for distribution):
```bash
flutter build apk --release
```

#### 7. Run the App
To run the app on your connected Android device or emulator, use the following command:
```bash
flutter run
```
Flutter will detect connected devices and deploy the app to the selected one. If multiple devices are connected, it will prompt you to choose one.

---
### Troubleshooting
- Device not detected: Make sure USB Debugging is enabled and the correct drivers for your device are installed. You can verify device connection by running:
  ```bash
  flutter doctor
  ```
- Build errors: Check the terminal output for any error messages. Common issues involve missing dependencies or SDK mismatches. Try running:
  ```bash
  flutter clean
  ```
  Then rebuild the app.

With these steps, you should be able to successfully launch and test the Android version of your Flutter app.

---

### Additional Resources:
- [Flutter Documentation](https://flutter.dev/docs)
- [Android Studio Setup Guide](https://developer.android.com/studio/install)
- [Troubleshooting Guide for Flutter](https://docs.flutter.dev/get-started/troubleshoot)

Feel free to reach out for help or report issues through the [issues page](https://github.com/wareefAlyousef/2024-25_GP_3/issues).
