import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insulin_sync/services/user_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';
import 'addByImage.dart';
import 'models/meal_model.dart';
import 'AddFoodItem.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'models/foodItem_model.dart';
import 'addnNutrition.dart';
import 'Cart.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_plus/tflite_flutter_plus.dart' as tflite_plus;

class AddBySearch extends StatefulWidget {
  String id;
  String? title;
  DateTime? time;
  final List<foodItem>?
      mealItems; // Optional meal items array, now a list of foodItem objects

  bool isFavorite;
  String? favoriteId;

  AddBySearch(
      {this.title,
      this.time,
      required this.id,
      super.key,
      this.mealItems,
      this.isFavorite = false,
      this.favoriteId = null}); // Accept mealItems as an optional parameter

  @override
  State<AddBySearch> createState() => _AddBySearch();
}

class _AddBySearch extends State<AddBySearch> with TickerProviderStateMixin {
  late TensorImage _inputImage;
  late Interpreter _interpreter;
  late Interpreter _interpreter2;
  bool _isModelLoaded = false;

  late Tensor inputTensor;
  late Tensor outputTensor;
  final ImagePicker _picker = ImagePicker();
  final _textController = TextEditingController();
  final _textFieldFocusNode = FocusNode();
  List<foodItem> _foodDetails = [];
  bool _isLoading = false;
  bool _isFocused = false;
  String _scanResult = "";
  UserService user_services = UserService();

  // To keep track of the selected item
  int? _selectedFoodIndex;

  // Optional meal items array, inherited from previous class if provided
  late final List<foodItem> mealItems;
  late final bool isFavorite;
  late final String? favoriteId;

  late TabController _tabController, _tabController2;

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    _tabController2.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadModel();
    // Initialize mealItems with the passed array if available, or an empty array
    mealItems = widget.mealItems ?? [];
    isFavorite = widget.isFavorite;
    favoriteId = widget.favoriteId;
    searchAndDisplayFood(''); // Optionally perform a default search

    _tabController = TabController(length: 2, vsync: this);
    _tabController2 = TabController(length: 2, vsync: this);
    print(
        'debugging editing meal id: ${widget.id} in addsearch line 101 initstaet');
  }

  void searchAndDisplayFood(String query) async {
    setState(() {
      _isLoading = true;
      _foodDetails.clear(); // Clear the list before fetching new results
    });

    try {
      final List<foodItem> results = await searchFood1(query);
      setState(() {
        _foodDetails = results; // Assign results to _foodDetails
        _isLoading = false; // Stop the loading spinner
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Ensure loading stops in case of an error
      });
      print('Error: $e'); // Log the error
    }
  }

  // barcode Scan method
  Future<void> _scanBarcode() async {
    String scanRes;
    try {
      scanRes = await FlutterBarcodeScanner.scanBarcode(
        "#023B96",
        "Cancel",
        true,
        ScanMode.DEFAULT,
      );
    } catch (error) {
      print('Error scanning barcode: $error');
      scanRes = 'Failed to scan:';
    }

    if (!mounted) return;

    setState(() {
      // scan is  done
      if (scanRes != '-1' && scanRes != 'Failed to scan:') {
        //succefull scan
        _scanResult = scanRes; // item code
        NutritionalData(_scanResult);
      } else {
        //scan canceled
      }
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Image Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.camera_alt,
                    color: Theme.of(context).primaryColor),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library,
                    color: Theme.of(context).primaryColor),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    File imageFile = File(image!.path);

    if (image != null) {
      _predict(imageFile);
    }
  }

  Future<void> _loadModel() async {
    print('Loading model...');
    try {
      final options = InterpreterOptions();

      if (Platform.isAndroid) {
        options.addDelegate(XNNPackDelegate());
      }

      _interpreter = await Interpreter.fromAsset(
          'images/models/nutrition_model_float32.tflite',
          options: options);

      inputTensor = _interpreter.getInputTensors().first;
      outputTensor = _interpreter.getOutputTensors().first;

      print('Model loaded successfully!');
    } catch (e) {
      print('Error loading model: $e');
      return;
    }

    try {
      final options = InterpreterOptions();

      if (Platform.isAndroid) {
        options.addDelegate(XNNPackDelegate());
      }

      _interpreter2 = await Interpreter.fromAsset(
          'images/models/classification_float32.tflite',
          options: options);

      inputTensor = _interpreter.getInputTensors().first;
      outputTensor = _interpreter.getOutputTensors().first;

      print('Model loaded successfully!');
      setState(() {
        _isModelLoaded = true;
      });
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  TensorImage _preProcess() {
    // Resize and normalize image
    return ImageProcessorBuilder()
        .add(ResizeOp(224, 224, ResizeMethod.nearestneighbour))
        .add(NormalizeOp(0.0, 255.0)) // Add normalization to [0, 1] if needed
        .build()
        .process(_inputImage);
  }

  Future<Float32List> preprocessImage(File imageFile) async {
    // Load the image
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image.');
    }

    // Resize the image to 224x224
    final resizedImage = img.copyResize(image, width: 224, height: 224);

    // Convert the resized image to a list of bytes (raw pixel values in NHWC format)
    final imageBytesList = resizedImage.getBytes();

    // Create a Float32List to hold the transposed and normalized image data
    final inputBuffer = Float32List(1 * 3 * 224 * 224);

    // Transpose the image data from NHWC to NCHW format and normalize pixel values
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        for (int c = 0; c < 3; c++) {
          // Normalize pixel values to the range [0, 1]
          final pixelValue = imageBytesList[(y * 224 + x) * 3 + c] / 255.0;
          inputBuffer[c * 224 * 224 + y * 224 + x] = pixelValue;
        }
      }
    }

    return inputBuffer;
  }

  bool _isCancelled = false; // Global flag to track cancellation

  Future<void> _predict(File imageFile) async {
    _isCancelled = false; // Reset cancellation flag before starting

    // Show loading dialog with cancel option
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Processing image..."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _isCancelled = true; // Set cancel flag
                Navigator.pop(dialogContext); // Close loading dialog
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );

    try {
      await loadAndRunModel(imageFile);
    } catch (e) {
      print('Error during prediction: $e');
    } finally {}
  }

  Future<void> loadAndRunModel(File imageFile) async {
    var scaledPredictions = [];
    if (_isCancelled) return; // Stop immediately if canceled

    if (!_isModelLoaded) {
      print('Model not loaded.');
      return;
    }

    try {
      print('Starting prediction...');

      final imageBytes = await imageFile.readAsBytes();
      if (_isCancelled) return;
      final decodedImage = img.decodeImage(imageBytes);
      if (_isCancelled) return;
      _inputImage = TensorImage(tflite_plus.TfLiteType.float32);
      if (_isCancelled) return;
      _inputImage.loadImage(decodedImage!);
      _inputImage = _preProcess();
      if (_isCancelled) return;

      // Define output buffer as a Map with key as the output index and value as a List
      Map<int, Object> _outputBuffer = {
        0: List.filled(4, 0.0), // Shape: [4]
      };
      if (_isCancelled) return;

      var zeroList = [0.0, 0.0, 0.0, 0.0];

      var map = <int, Object>{};
      map[0] = [zeroList]; // Now it's a 2D list, so shape is [1, 4]

      // Run inference
      _interpreter.runForMultipleInputs([_inputImage.buffer], map);
      if (_isCancelled) return;

      // Loop through the map to print the content
      map.forEach((key, value) {
        print('Key: $key');
        if (value is List) {
          // If value is a List, print each element in the list
          value.forEach((element) {
            if (_isCancelled) return;
            print(element); // Print each element in the list
          });
        }
      });

      if (_isCancelled) return;

      // Process results
      print('Prediction Values: ${map[0]}');

      // Hard-coded scaler parameters
      final minValues = [3.0, 0.0, 0.0, 0.0];
      final scaleValues = [655.0, 50.940563, 70.84694137, 60.203995];

      if (_isCancelled) return;

      // Extract raw predictions
      final rawPredictions = (map[0] as List<List<double>>)[0];

      // Apply scaling to raw predictions
      scaledPredictions = List<double>.generate(
        rawPredictions.length,
        (index) =>
            (rawPredictions[index] * scaleValues[index]) + minValues[index],
      );

      if (_isCancelled) return;

      var output0 = List<double>.filled(238, 0);

// output: Map<int, Object>
      var outputs = {
        0: [output0]
      };

      _interpreter2.runForMultipleInputs([_inputImage.buffer], outputs);

      print('Map: ${outputs[0]}');

      var classificationPred = await _processPredictions(outputs);

      if (classificationPred.isEmpty) {
        setState(() {
          _isCancelled = true;
        });
        Navigator.pop(context);

        _showInfo(
          context,
          "Food Item Not Identified",
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(
                        text:
                            "● The food item could not be identified. Please try again with a clearer image.\n\n"),
                    TextSpan(
                        text:
                            "● For better accuracy, ensure the food is well-lit, centered in the frame, and not obstructed by other objects.\n\n"),
                    TextSpan(
                        text:
                            "● If the issue persists, please try different angles or lighting conditions.\n\n"),
                  ],
                ),
              ),
            ],
          ),
        );

        return;
      }

      final double portion = scaledPredictions[0].isNegative
          ? 0
          : double.parse(scaledPredictions[0].toStringAsFixed(2));
      final double fat = scaledPredictions[1].isNegative
          ? 0
          : double.parse(scaledPredictions[1].toStringAsFixed(2));
      final double carb = scaledPredictions[2].isNegative
          ? 0
          : double.parse(scaledPredictions[2].toStringAsFixed(2));
      final double protein = scaledPredictions[3].isNegative
          ? 0
          : double.parse(scaledPredictions[3].toStringAsFixed(2));

      final double calorie = double.parse(
          ((fat * 9) + (carb * 4) + (protein * 4)).toStringAsFixed(2));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddByImage(
            id: widget.id,
            name: classificationPred,
            source: "Image",
            image: imageFile,
            portion: portion,
            fat: fat,
            carb: carb,
            protein: protein,
            calorie: calorie,
            title: widget.title,
            time: widget.time,
            mealItems: mealItems,
            isFavorite: isFavorite,
            favoriteId: favoriteId,
          ),
        ),
      );
    } catch (e) {
      print('Error during inference: $e');
    } finally {}
  }

  Future<String> _processPredictions(
      Map<int, List<List<double>>> outputs) async {
    // Define the threshold
    double threshold = 0.2;

    // Flatten the nested list (List<List<double>> -> List<double>)
    List<double> predictions = outputs[0]!.expand((e) => e).toList();

    // Load ingredients JSON from assets
    String jsonString =
        await rootBundle.loadString('images/models/ingredients.json');

    // Decode the JSON
    var decodedJson = jsonDecode(jsonString);

    // Access the list of ingredients from the decoded JSON
    List<dynamic> ingredients = decodedJson['ingredients'];

    // Filter the predictions to keep those above the threshold
    List<String> matchedIngredients = [];
    for (int i = 0; i < predictions.length; i++) {
      if (predictions[i] > threshold) {
        // Add corresponding ingredient to the list if prediction is above threshold
        matchedIngredients.add(ingredients[i]);
      }
    }

    // Concatenate ingredients into a single string if there are multiple
    String result = matchedIngredients.join(', ');

    return result;
  }

  // Method to show info dialog
  void _showInfo(BuildContext context, String title, Widget body) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          content: body,
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

  Future<Float32List> _preprocessImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) throw Exception("Failed to decode image");

    // Resize the image to the required input size (224x224)
    final resizedImage = img.copyResize(image, width: 224, height: 224);

    // Normalize image pixels and convert to Float32List in H × W × C format
    final normalizedPixels = Float32List(224 * 224 * 3);
    int index = 0;

    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        final pixel = resizedImage.getPixel(x, y);
        normalizedPixels[index++] = img.getRed(pixel) / 255.0; // Red
        normalizedPixels[index++] = img.getGreen(pixel) / 255.0; // Green
        normalizedPixels[index++] = img.getBlue(pixel) / 255.0; // Blue
      }
    }

    return normalizedPixels;
  }

  // call nutrions API method
  Future<void> NutritionalData(String barcode) async {
    final String apiUrl =
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['product'] != null && data['product']['nutriments'] != null) {
          var product = data['product'];
          var nutrients = product['nutriments'];
          if (nutrients['carbohydrates_100g'] == null ||
              nutrients['energy-kcal_100g'] == null ||
              nutrients['fat_100g'] == null ||
              nutrients['proteins_100g'] == null) {
            showErrorDialog(
                "Nutritional data for this product is not available.");
          } else {
            // nutritional data

            var Name = product['product_name'] ?? 'Name is unavailable';
            var nutrients = product['nutriments'];
            var carbohydrates =
                (nutrients['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0;
            var calorie =
                (nutrients['energy-kcal_100g'] as num?)?.toDouble() ?? 0.0;
            var fat = (nutrients['fat_100g'] as num?)?.toDouble() ?? 0.0;
            var protein =
                (nutrients['proteins_100g'] as num?)?.toDouble() ?? 0.0;

            foodItem food = foodItem(
              name: Name, // Name of the food item
              portion: 100.0, // Portion size (100g)
              protein: protein, // Protein content
              fat: fat, // Fat content
              carb: carbohydrates, // Carbohydrate content
              calorie: calorie, // Calorie content
              source: 'barcode', // Source of the data
            );

            navigateToAddFoodItem(food, isFavorite, favoriteId);
          }
        } else {
          showErrorDialog(
              "Nutritional data for this product is not available.");
        }
      } else {
        showErrorDialog("No product found for this barode.");
      }
    } catch (e) {
      showErrorDialog("Error in retrieving the nutritional data.");
    }
  }

// Error Dialg
  void showErrorDialog(String message) {
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
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22),
              ),
              SizedBox(height: 15),
              Text(
                'Do you want to add the nutritions manually?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddBySearch(
                              id: widget.id,
                              title: widget.title,
                              time: widget.time,
                              mealItems: mealItems)),
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
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddNutrition(
                              id: widget.id,
                              title: widget.title,
                              mealItems: mealItems)),
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
                    'Ok',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void navigateToAddFoodItem(
      foodItem food, bool isFavorite, String? favoriteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Addfooditem(
          id: widget.id,
          title: widget.title,
          time: widget.time,
          calorie: food.calorie,
          protein: food.protein,
          carb: food.carb,
          fat: food.fat,
          name: food.name,
          portion: food.portion,
          source: food.source,
          mealItems: mealItems,
          isFavorite: isFavorite,
          favoriteId: favoriteId,
        ),
      ),
    );
  }

  String selectedOption = 'All'; // Default selected option
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Color(0xFFf1f4f8),
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Cart(
                              id: widget.id,
                              title: widget.title,
                              time: widget.time,
                              foodItems: mealItems,
                              isFavorite: isFavorite,
                              favoriteId: favoriteId,
                            )),
                  );
                },
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ],
          ),
          actions: [],
          centerTitle: false,
          elevation: 0,
        ),
        body: Stack(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 27.0, vertical: 6),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Container(
                    height: 48, // Increased height for better touch area
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 0, vertical: 1), // Better spacing
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        return TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent, // Remove divider
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorPadding: EdgeInsets.all(4),
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Colors.grey[600],
                          labelStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600, // Bolder selected tab
                            letterSpacing: 0.5,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: [
                            Tab(
                              child: AnimatedSwitcher(
                                duration: Duration(milliseconds: 200),
                                child: _tabController.index == 0
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.favorite, size: 18),
                                          SizedBox(width: 6),
                                          Text('Favorites'),
                                        ],
                                      )
                                    : Text('Favorites'),
                              ),
                            ),
                            Tab(
                              child: AnimatedSwitcher(
                                duration: Duration(milliseconds: 200),
                                child: _tabController.index == 1
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.history, size: 18),
                                          SizedBox(width: 6),
                                          Text('Recent'),
                                        ],
                                      )
                                    : Text('Recent'),
                              ),
                            ),
                          ],
                          onTap: (index) {
                            // Add haptic feedback
                            HapticFeedback.lightImpact();
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Container(
                            height: 40.0,
                            width: 130,
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedOption,
                                icon: Icon(Icons.arrow_drop_down),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      selectedOption = newValue;
                                    });
                                  }
                                },
                                items: <String>[
                                  'All',
                                  'Food Item',
                                  'Meal'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    ),
                                  );
                                }).toList(),
                              ),
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Positioned(
              top: 160,
              left: 0,
              right: 0,
              bottom: 0,
              child: TabBarView(
                controller: _tabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 0.0),
                    child: FutureBuilder<List<dynamic>>(
                      future: Future.wait([
                        user_services.getFavoriteFoodItems(),
                        user_services.getFavoriteMeals(),
                      ]).then((results) {
                        // Combine the two lists into one
                        List<dynamic> combinedList = [];
                        if (selectedOption != 'Meal')
                          combinedList.addAll(results[0]); // Add food items
                        if (selectedOption != 'Food Item')
                          combinedList.addAll(results[1]); // Add meals
                        combinedList = combinedList.reversed.toList();
                        return combinedList;
                      }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}"));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                              child: Text("No favorite items available."));
                        }

                        // Pass the combined list to GeneralList
                        return GeneralList(
                          id: widget.id,
                          title: widget.title,
                          food: snapshot.data!,
                          mealItems: mealItems,
                          recent: false,
                          isFavorite: isFavorite,
                          favoriteId: favoriteId,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 0.0),
                    child: FutureBuilder<List<dynamic>>(
                      future: Future.wait([
                        user_services.getMeal(),
                      ]).then((results) {
                        // Extract and process meals
                        List<meal> allMeals = results[0];

                        // Filter and sort the newest meals
                        List<meal> sortedMeals = allMeals
                            .where((meal) => meal.time != DateTime(1900))
                            .toList()
                          ..sort((a, b) => b.time.compareTo(a.time));

                        List<meal> newestMeals = sortedMeals.take(6).toList();

                        List<dynamic> combinedList = [];

                        for (var oneMeal in newestMeals) {
                          if (selectedOption != 'Food Item') {
                            combinedList.add(oneMeal); // Add the meal itself
                          }
                          if (selectedOption != 'Meal') {
                            combinedList.addAll(oneMeal
                                .foodItems); // Add its food items immediately after
                          }
                        }

                        return combinedList;
                      }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}"));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                              child: Text(
                                  "No recent meals or ingredients available."));
                        }

                        // Pass the combined list to GeneralList
                        return GeneralList(
                          id: widget.id,
                          title: widget.title,
                          food: snapshot.data!,
                          recent: true,
                          mealItems: mealItems,
                          isFavorite: isFavorite,
                          favoriteId: favoriteId,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Other content (Search bar and additional widgets)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(27, 12, 27, 0),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: _isFocused && _foodDetails.isNotEmpty
                          ? BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            )
                          : BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFieldFocusNode,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          searchAndDisplayFood(value);
                        } else {
                          setState(() {
                            _foodDetails.clear();
                          });
                        }
                      },
                      onTap: () {
                        setState(() {
                          _isFocused = true;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for food...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 24,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: Padding(
                          padding: EdgeInsets.zero,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                icon: Image.asset(
                                  'images/barcode_scanner.png',
                                  height: 27,
                                  color: Color(0xFF555555),
                                ),
                                onPressed: () {
                                  _scanBarcode();
                                },
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF555555),
                                  size: 24,
                                ),
                                onPressed: () {
                                  _showImageSourceSheet();
                                  print('Camera icon pressed...');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF101213),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
            if (_foodDetails.isNotEmpty && _isFocused)
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _isFocused = false;
                  });
                },
                child: Container(
                  color: Colors.grey.withOpacity(0.5),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            if (_foodDetails.isEmpty &&
                _isFocused &&
                _textController.text.isNotEmpty &&
                !_isLoading)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(27, 100, 27, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Results Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try different keywords or add nutrition details manually',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddNutrition(
                                  id: widget.id,
                                  title: widget.title,
                                  mealItems: mealItems),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Add Manually',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(27, 12, 27, 0),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: _isFocused && _foodDetails.isNotEmpty
                          ? BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            )
                          : BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFieldFocusNode,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          searchAndDisplayFood(value);
                        } else {
                          setState(() {
                            _foodDetails.clear();
                          });
                        }
                      },
                      onTap: () {
                        setState(() {
                          _isFocused = true;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for food...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 24,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: Padding(
                          padding: EdgeInsets.zero,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                icon: Image.asset(
                                  'images/barcode_scanner.png',
                                  height: 27,
                                  color: Color(0xFF555555),
                                ),
                                onPressed: () {
                                  _scanBarcode();
                                },
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF555555),
                                  size: 24,
                                ),
                                onPressed: () {
                                  _showImageSourceSheet();
                                  print('Camera icon pressed...');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF101213),
                      ),
                    ),
                  ),
                ),
                if (_foodDetails.isNotEmpty && _isFocused)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(27, 0, 27, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3), // Shadow offset
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(_foodDetails.length, (index) {
                            final food = _foodDetails[
                                index]; // Get the food item by index
                            return GestureDetector(
                              onTap: () {
                                // Update the selected food index
                                setState(() {
                                  _selectedFoodIndex =
                                      index; // Highlight the tapped item
                                });

                                navigateToAddFoodItem(food, isFavorite,
                                    favoriteId); // Pass the foodItem object directly
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10.0,
                                  horizontal: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedFoodIndex == index
                                      ? const Color(0xFFD8E6FD).withOpacity(0.4)
                                      : Colors.transparent,
                                ),
                                child: Text(
                                  food.name, // Accessing the name directly from the foodItem object
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xFF101213),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildIcon(IconData icon,
    {required bool isSelected, required BuildContext context}) {
  return Container(
    padding: const EdgeInsets.all(8.0),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Colors.transparent,
    ),
    child: Icon(
      icon,
      size: 20,
      color: isSelected
          ? Theme.of(context)
              .scaffoldBackgroundColor // Icon color matches background
          : Colors.grey, // Gray for unselected
    ),
  );
}

// Future<void> searchFood(String searchExpression) async {
//   final String consumerKey = "e8d5986b473d4d5f9403c45089673295";
//   final String consumerSecret = "f6f68754b37947149440701c6f4a18a5";

//   // Step 1: Generate timestamp and nonce
//   // final oauthTimestamp =
//   //     (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
//   DateTime now = DateTime.now();
//   print("response: Current Time: $now");

//   DateTime adjustedTime = now.add(Duration(days: 1, hours: 12, minutes: 2));
//   print("response: Adjusted Time: $adjustedTime");

//   final oauthTimestamp =
//       (adjustedTime.millisecondsSinceEpoch ~/ 1000).toString();
//   print("response: oauthTimestamp: $oauthTimestamp");

//   final oauthNonce =
//       base64UrlEncode(List<int>.generate(32, (i) => Random().nextInt(256)))
//           .replaceAll('=', '');

//   print('response food');

//   // Step 2: Prepare the parameters
//   final parameters = {
//     'oauth_consumer_key': consumerKey,
//     'oauth_signature_method': 'HMAC-SHA1',
//     'oauth_timestamp': oauthTimestamp,
//     'oauth_nonce': oauthNonce,
//     'oauth_version': '1.0',
//     'method': 'foods.search',
//     'search_expression': searchExpression,
//     'format': 'json',
//   };

//   // Step 3: Normalize the parameters and create the signature base string
//   final normalizedParams = parameters.entries
//       .map((e) =>
//           '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
//       .toList()
//     ..sort();
//   final paramString = normalizedParams.join('&');

//   final httpMethod = 'GET';
//   final baseUrl = 'https://platform.fatsecret.com/rest/server.api';
//   final signatureBaseString =
//       '$httpMethod&${Uri.encodeQueryComponent(baseUrl)}&${Uri.encodeQueryComponent(paramString)}';

//   // Step 4: Create the signing key
//   final signingKey = '${Uri.encodeQueryComponent(consumerSecret)}&';

//   // Step 5: Generate the HMAC-SHA1 signature
//   final hmacSha1 = Hmac(sha1, utf8.encode(signingKey));
//   final digest = hmacSha1.convert(utf8.encode(signatureBaseString));
//   final signature = base64Encode(digest.bytes);
//   final encodedSignature = Uri.encodeQueryComponent(signature);

//   // Step 6: Construct the full URL with parameters
//   final requestUrl = '$baseUrl?$paramString&oauth_signature=$encodedSignature';

//   // Step 7: Make the GET request
//   final response = await http.get(Uri.parse(requestUrl));

//   if (response.statusCode == 200) {
//     print('Response: ${response.body}');
//   } else {
//     print('Error: ${response.statusCode} ${response.reasonPhrase}');
//   }
// }

Future<List<foodItem>> searchFood1(String query) async {
  final String consumerKey = "aea061ecb6004d61903e1387e7743e86";
  final String consumerSecret = "41e586bd5c4b415c918f240f126b0c0e";
  query = query.trim();

  final oauthTimestamp = (DateTime.now()
              .add(Duration(hours: 0, minutes: 2)) // Add 3 hours
              .millisecondsSinceEpoch ~/
          1000)
      .toString();

  final oauthNonce =
      base64UrlEncode(List<int>.generate(32, (i) => Random().nextInt(256)))
          .replaceAll('=', '');

  final parameters = {
    'oauth_consumer_key': consumerKey,
    'oauth_signature_method': 'HMAC-SHA1',
    'oauth_timestamp': oauthTimestamp,
    'oauth_nonce': oauthNonce,
    'oauth_version': '1.0',
    'method': 'foods.search',
    'search_expression': query,
    'format': 'json',
  };

  final normalizedParams = parameters.entries
      .map((e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .toList()
    ..sort();
  final paramString = normalizedParams.join('&');

  final httpMethod = 'GET';
  final baseUrl = 'https://platform.fatsecret.com/rest/server.api';
  final signatureBaseString =
      '$httpMethod&${Uri.encodeQueryComponent(baseUrl)}&${Uri.encodeQueryComponent(paramString)}';

  final signingKey = '${Uri.encodeQueryComponent(consumerSecret)}&';

  final hmacSha1 = Hmac(sha1, utf8.encode(signingKey));
  final digest = hmacSha1.convert(utf8.encode(signatureBaseString));
  final signature = base64Encode(digest.bytes);
  final encodedSignature = Uri.encodeQueryComponent(signature);

  final requestUrl = '$baseUrl?$paramString&oauth_signature=$encodedSignature';

  double _parsePortionToGrams(String portionString) {
    if (portionString.contains('g')) {
      // Extract numeric value for gram-based portions
      return double.tryParse(
              RegExp(r'[\d.]+').stringMatch(portionString) ?? '0') ??
          0.0;
    } else if (portionString.contains('1/2')) {
      return 50.0; // Approximate value for "1/2 cup"
    } else if (portionString.contains('1/4')) {
      return 25.0; // Approximate value for "1/4 cup"
    }
    // Add more cases as needed for other units like "1 cup"
    return 100.0; // Default fallback value
  }

  try {
    final response = await http.get(Uri.parse(requestUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print('Response: ${response.body}');

      if (data != null &&
          data['foods'] != null &&
          data['foods']['food'] != null) {
        final List<dynamic> foods = data['foods']['food'];

        // Use a set to filter unique items by name
        final Set<String> seenNames = {};
        final List<foodItem> uniqueFoods = [];

        for (var food in foods) {
          final String name = food['food_name'];
          if (!seenNames.contains(name)) {
            seenNames.add(name);

            // Extract nutritional values from food_description
            final description = food['food_description'] ?? '';

            // Extract the portion using a regular expression
            final RegExp portionRegex = RegExp(r'Per\s([\d./\s]+[a-zA-Z]*)');
            final portionMatch = portionRegex.firstMatch(description);

            // Extract the numeric portion value and the unit
            final String portionString =
                portionMatch != null ? portionMatch.group(1) ?? '' : '';
            final double portion =
                _parsePortionToGrams(portionString); // Convert to grams

            // Extract nutritional values
            final RegExp nutritionRegex = RegExp(
                r'Calories:\s?([\d.]+)kcal\s?\|\s?Fat:\s?([\d.]+)g\s?\|\s?Carbs:\s?([\d.]+)g\s?\|\s?Protein:\s?([\d.]+)g');
            final match = nutritionRegex.firstMatch(description);

            final double calories = match != null
                ? double.tryParse(match.group(1) ?? '0') ?? 0.0
                : 0.0;
            final double fat = match != null
                ? double.tryParse(match.group(2) ?? '0') ?? 0.0
                : 0.0;
            final double carb = match != null
                ? double.tryParse(match.group(3) ?? '0') ?? 0.0
                : 0.0;
            final double protein = match != null
                ? double.tryParse(match.group(4) ?? '0') ?? 0.0
                : 0.0;

            // Add the food item to the list
            uniqueFoods.add(foodItem(
              name: name,
              portion: portion, // Use the extracted portion size
              protein: protein,
              fat: fat,
              carb: carb,
              calorie: calories,
              source: 'FatSecret API',
            ));
          }
        }

        return uniqueFoods;
      } else {
        print('No food data found in the response.');
        return [];
      }
    } else {
      throw Exception(
          'Failed to load food data, status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred while fetching food data: $e');
    return [];
  }
}

class FavoriteMealsList extends StatefulWidget {
  String id;
  String? title;
  DateTime? time;
  final List<meal> meals;
  final List<foodItem> mealItems;
  bool isFavorite;
  String? favoriteId;

  FavoriteMealsList(
      {this.title,
      this.time,
      required this.meals,
      required this.id,
      Key? key,
      required this.mealItems,
      this.isFavorite = false,
      this.favoriteId})
      : super(key: key);

  @override
  _FavoriteMealsListState createState() => _FavoriteMealsListState();
}

class _FavoriteMealsListState extends State<FavoriteMealsList> {
  Map<int, bool> _expandedMeals = {};

  UserService user_service = UserService();

  void _showRemoveDialog(BuildContext context, String? id, int index) {
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
                  backgroundColor: Color.fromARGB(41, 248, 77, 117),
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 80,
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Are You Sure?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Clicking "Remove" Will Remove the meal from the favorite list',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Cancel Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(120, 44),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    // Clear All Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          bool success =
                              await user_service.removeFromFavorite(id);

                          if (success) {
                            setState(() {
                              widget.meals.removeAt(index);
                            });
                          }
                          Navigator.of(context)
                              .pop(); // Close dialog after async operation
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(120, 44),
                        ),
                        child: Text(
                          'remove',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
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
  }

  void addFavoriteToCart(meal meal) {
    for (var item in meal.foodItems) {
      // Loop through all food items in the meal
      final newItem = foodItem(
        name: item.name,
        calorie: item.calorie,
        protein: item.protein,
        carb: item.carb,
        fat: item.fat,
        portion: item.portion,
        source: item.source,
      );
      widget.mealItems.add(newItem); // Add each item to the cart
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cart(
          id: widget.id,
          title: widget.title,
          time: widget.time,
          foodItems: widget.mealItems,
          isFavorite: widget.isFavorite,
          favoriteId: widget.favoriteId,
        ),
      ),
    );
  }

  IconData _getIconForMeal() {
    return Icons.fastfood; // You can adjust this based on your design
  }

  @override
  Widget build(BuildContext context) {
    UserService user_service = UserService();
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Header Section
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 0.0, 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 50,
              ),
            ],
          ),
        ),

        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 200.0),
            shrinkWrap: true,
            physics: BouncingScrollPhysics(), // Adds a smooth scrolling effect
            itemCount: widget.meals.length,
            itemBuilder: (context, index) {
              final meal = widget.meals[index];
              bool isExpanded = _expandedMeals[index] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 5.0,
                        color: Color(0x230E151B),
                        offset: Offset(0.0, 2.0),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(4.0, 4.0, 4.0, 13.0),
                    child: Column(
                      children: [
                        Card(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Aligns content to the left
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getIconForMeal(),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 24, // Adjust size
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          meal.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          onPressed: () {
                                            addFavoriteToCart(meal);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                          onPressed: () async {
                                            _showRemoveDialog(
                                                context, meal.id, index);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _expandedMeals[index] =
                                                  !isExpanded;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (!isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      getFoodItemsTextOneLine(meal.foodItems),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black54),
                                    ),
                                  ),
                                if (isExpanded) _buildMealView(meal),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMealView(meal meal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Added Ingredients"),
                Expanded(
                  child: Text(
                    getFoodItemsText(meal.foodItems),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          Divider(), // Separate meal details visually

          _buildNutrientRow('Total Carbs', meal.totalCarb, 'g'),
          _buildNutrientRow('Total Protein', meal.totalProtein, 'g'),
          _buildNutrientRow('Total Fat', meal.totalFat, 'g'),
          _buildNutrientRow('Total Calories', meal.totalCalorie, 'kcal'),

          // Favorite heart icon
        ],
      ),
    );
  }

  // Helper method for consistent row formatting
  Widget _buildNutrientRow(String label, double value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13)),
        Text('${value.toStringAsFixed(1)} $unit',
            style: TextStyle(fontSize: 13)),
      ],
    );
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String getFoodItemsText(List<foodItem> foodItems) {
    if (foodItems.isEmpty) {
      return '-';
    }

    // If there's only one item with portion -1, return '-'
    if (foodItems.length == 1 && foodItems[0].portion == -1) {
      return '-';
    }

    // Filter out items with portion -1 and create the formatted string
    var validItems = foodItems
        .where((item) => item.portion != -1)
        .map((item) => '${item.name} (${item.portion}g)')
        .join('\n');

    return validItems.isEmpty ? '-' : validItems;
  }

  String getFoodItemsTextOneLine(List<foodItem> foodItems) {
    if (foodItems.isEmpty) {
      return '-';
    }

    // If there's only one item with portion -1, return '-'
    if (foodItems.length == 1 && foodItems[0].portion == -1) {
      return '-';
    }

    var validItems = foodItems
        .where((item) => item.portion != -1)
        .map((item) => '${item.name}')
        .join(', ');

    return validItems.isEmpty ? '-' : validItems;
  }
}

/////////////////////////

class IngredientList extends StatefulWidget {
  String? title;
  final DateTime? time;

  final List<foodItem> items;

  final List<foodItem> mealItems;

  bool isFavorite;
  String? favoriteId;

  String id;

  IngredientList(
      {this.title,
      this.time,
      required this.items,
      required this.id,
      Key? key,
      this.isFavorite = false,
      this.favoriteId,
      required this.mealItems})
      : super(key: key);

  @override
  _IngredientListState createState() => _IngredientListState();
}

class _IngredientListState extends State<IngredientList> {
  Map<int, bool> _expandedMeals = {};

  UserService user_service = UserService();

  void _showRemoveDialog(BuildContext context, String? id, int index) {
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
                  backgroundColor: Color.fromARGB(41, 248, 77, 117),
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 80,
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Are You Sure?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Clicking "Remove" Will Remove the meal from the favorite list',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Cancel Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(120, 44),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    // Clear All Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          bool success =
                              await user_service.removeFromFavorite(id);

                          if (success) {
                            setState(() {
                              widget.items.removeAt(index);
                            });
                          }
                          Navigator.of(context)
                              .pop(); // Close dialog after async operation
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(120, 44),
                        ),
                        child: Text(
                          'remove',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
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
  }

  void addFavoriteToCart(foodItem item) {
    widget.mealItems.add(item); // Add each item to the cart

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cart(
          id: widget.id,
          title: widget.title,
          time: widget.time,
          foodItems: widget.mealItems,
          isFavorite: widget.isFavorite,
          favoriteId: widget.favoriteId,
        ),
      ),
    );
  }

  IconData _getIconForMeal() {
    return Icons.fastfood; // You can adjust this based on your design
  }

  @override
  Widget build(BuildContext context) {
    UserService user_service = UserService();
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Header Section
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 0.0, 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 50,
              ),
            ],
          ),
        ),

        // List of Favorite Meals (inside a ListView for proper scrolling)
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 200.0),
            shrinkWrap: true, // Makes it fit the available space
            physics: BouncingScrollPhysics(), // Adds a smooth scrolling effect
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];

              bool isExpanded = _expandedMeals[index] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 5.0,
                        color: Color(0x230E151B),
                        offset: Offset(0.0, 2.0),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(4.0, 4.0, 4.0, 13.0),
                    child: Column(
                      children: [
                        Card(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Aligns content to the left
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_pizza,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.name.length <= 20
                                              ? item.name
                                              : '${item.name.substring(0, 20)}...', // Truncate and add ellipsis
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          onPressed: () {
                                            addFavoriteToCart(item);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                          onPressed: () async {
                                            _showRemoveDialog(
                                                context, item.id, index);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _expandedMeals[index] =
                                                  !isExpanded;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (isExpanded) _buildMealView(item),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMealView(foodItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    (item.name),
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Divider(), // Separate meal details visually

          _buildNutrientRow('Carbs', item.carb, 'g'),
          _buildNutrientRow('Protein', item.protein, 'g'),
          _buildNutrientRow('Fat', item.fat, 'g'),
          _buildNutrientRow('Calories', item.calorie, 'kcal'),

          // Favorite heart icon
        ],
      ),
    );
  }

  // Helper method for consistent row formatting
  Widget _buildNutrientRow(String label, double value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13)),
        Text('${value.toStringAsFixed(1)} $unit',
            style: TextStyle(fontSize: 13)),
      ],
    );
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String getFoodItemsText(List<foodItem> foodItems) {
    if (foodItems.isEmpty) {
      return '-';
    }

    // If there's only one item with portion -1, return '-'
    if (foodItems.length == 1 && foodItems[0].portion == -1) {
      return '-';
    }

    // Filter out items with portion -1 and create the formatted string
    var validItems = foodItems
        .where((item) => item.portion != -1)
        .map((item) => '${item.name} (${item.portion}g)')
        .join('\n');

    return validItems.isEmpty ? '-' : validItems;
  }

  String getFoodItemsTextOneLine(List<foodItem> foodItems) {
    if (foodItems.isEmpty) {
      return '-';
    }

    // If there's only one item with portion -1, return '-'
    if (foodItems.length == 1 && foodItems[0].portion == -1) {
      return '-';
    }

    var validItems = foodItems
        .where((item) => item.portion != -1)
        .map((item) => '${item.name}')
        .join(', ');

    return validItems.isEmpty ? '-' : validItems;
  }
}

class GeneralList extends StatefulWidget {
  String? title;
  DateTime? time;
  final List<dynamic> food;

  final List<foodItem> mealItems;

  final bool recent;

  bool isFavorite;
  String? favoriteId;

  String id;

  GeneralList(
      {this.title,
      this.time,
      required this.food,
      required this.id,
      Key? key,
      this.isFavorite = false,
      this.favoriteId,
      required this.mealItems,
      required this.recent})
      : super(key: key);

  @override
  _GeneralListState createState() => _GeneralListState();
}

class _GeneralListState extends State<GeneralList> {
  Map<int, bool> _expandedMeals = {};

  UserService user_service = UserService();

  void _showRemoveDialog(BuildContext context, dynamic item, int index) {
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
                  backgroundColor: Color.fromARGB(41, 248, 77, 117),
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 80,
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Are You Sure?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Clicking "Remove" Will Remove the meal from the favorite list',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Cancel Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(120, 44),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    // Clear All Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          print('debug fav: inside the onpressed');
                          bool success = false;
                          if (item is meal) {
                            print('debug fav: is meal');
                            success =
                                await user_service.removeFromFavorite(item.id);
                          }

                          if (item is foodItem) {
                            print('debug fav: is item');
                            success = await user_service
                                .removeItemFromFavorite(item.id);
                          }

                          if (success) {
                            print('debug fav: success');
                            setState(() {
                              print('debug fav: setstate');
                              widget.food.removeAt(index);
                            });
                            print("Meal ${item.id} removed from favorites!");
                          }
                          Navigator.of(context)
                              .pop(); // Close dialog after async operation
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(120, 44),
                        ),
                        child: Text(
                          'remove',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
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
  }

  void addFavoriteMealToCart(meal meal) {
    for (var item in meal.foodItems) {
      // Loop through all food items in the meal
      final newItem = foodItem(
        name: item.name,
        calorie: item.calorie,
        protein: item.protein,
        carb: item.carb,
        fat: item.fat,
        portion: item.portion,
        source: item.source,
      );
      widget.mealItems.add(newItem); // Add each item to the cart
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cart(
          id: widget.id,
          title: widget.title,
          time: widget.time,
          foodItems: widget.mealItems,
          isFavorite: widget.isFavorite,
          favoriteId: widget.favoriteId,
        ),
      ),
    );
  }

  void addFavoriteItemToCart(foodItem item) {
    widget.mealItems.add(item); // Add each item to the cart

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cart(
          id: widget.id,
          title: widget.title,
          time: widget.time,
          foodItems: widget.mealItems,
          isFavorite: widget.isFavorite,
          favoriteId: widget.favoriteId,
        ),
      ),
    );
  }

  IconData _getIconForItem(dynamic item) {
    if (item is meal) {
      return Icons.fastfood; // Meal icon
    } else if (item is foodItem) {
      return Icons.local_pizza; // FoodItem icon
    } else {
      return Icons.help; // Default icon for unknown types
    }
  }

  @override
  Widget build(BuildContext context) {
    UserService user_service = UserService();
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Header Section
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 0.0, 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 50,
              ),
            ],
          ),
        ),

        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 200.0),
            shrinkWrap: true, // Makes it fit the available space
            physics: BouncingScrollPhysics(), // Adds a smooth scrolling effect
            itemCount: widget.food.length,
            itemBuilder: (context, index) {
              final item = widget.food[index];

              bool isExpanded = _expandedMeals[index] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 45.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 5.0,
                        color: Color(0x230E151B),
                        offset: Offset(0.0, 2.0),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(4.0, 4.0, 4.0, 13.0),
                    child: Column(
                      children: [
                        Card(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Aligns content to the left
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getIconForItem(item),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 24, // Adjust size
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item is foodItem
                                              ? (item.name.length <= 8
                                                  ? item.name
                                                  : '${item.name.substring(0, 8)}...')
                                              : item is meal
                                                  ? (item.title.length <= 20
                                                      ? item.title
                                                      : '${item.title.substring(0, 20)}...')
                                                  : 'Unknown', // Default text if neither type matches
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          onPressed: () {
                                            if (item is meal) {
                                              addFavoriteMealToCart(item);
                                            } else if (item is foodItem) {
                                              addFavoriteItemToCart(item);
                                            }
                                          },
                                        ),
                                        if (!widget.recent)
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                            onPressed: () async {
                                              _showRemoveDialog(
                                                  context, item, index);
                                            },
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _expandedMeals[index] =
                                                  !isExpanded;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (!isExpanded)
                                  if (item is meal)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        getFoodItemsTextOneLine(item.foodItems),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54),
                                      ),
                                    ),
                                if (isExpanded) _buildMealView(item),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMealView(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item is meal)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Added Ingredients"),
                  Expanded(
                    child: Text(
                      getFoodItemsText(item.foodItems),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (item is foodItem)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      (item.name),
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Divider(),

          // Separate meal details visually

          Column(
            children: [
              if (item is meal) ...[
                _buildNutrientRow('Total Carbs', item.totalCarb, 'g'),
                _buildNutrientRow('Total Protein', item.totalProtein, 'g'),
                _buildNutrientRow('Total Fat', item.totalFat, 'g'),
                _buildNutrientRow('Total Calories', item.totalCalorie, 'kcal'),
              ] else if (item is foodItem) ...[
                _buildNutrientRow('Carbs', item.carb, 'g'),
                _buildNutrientRow('Protein', item.protein, 'g'),
                _buildNutrientRow('Fat', item.fat, 'g'),
                _buildNutrientRow('Calories', item.calorie, 'kcal'),
              ],
            ],
          )

          // Favorite heart icon
        ],
      ),
    );
  }

  // Helper method for consistent row formatting
  Widget _buildNutrientRow(String label, double value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13)),
        Text('${value.toStringAsFixed(1)} $unit',
            style: TextStyle(fontSize: 13)),
      ],
    );
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String getFoodItemsText(List<foodItem> foodItems) {
    if (foodItems.isEmpty) {
      return '-';
    }

    // If there's only one item with portion -1, return '-'
    if (foodItems.length == 1 && foodItems[0].portion == -1) {
      return '-';
    }

    // Filter out items with portion -1 and create the formatted string
    var validItems = foodItems
        .where((item) => item.portion != -1)
        .map((item) => '${item.name} (${item.portion}g)')
        .join('\n');

    return validItems.isEmpty ? '-' : validItems;
  }

  String getFoodItemsTextOneLine(List<foodItem> foodItems) {
    if (foodItems.isEmpty) {
      return '-';
    }

    // If there's only one item with portion -1, return '-'
    if (foodItems.length == 1 && foodItems[0].portion == -1) {
      return '-';
    }

    // Filter out items with portion -1 and create the formatted string
    var validItems = foodItems
        .where((item) => item.portion != -1)
        .map((item) => '${item.name}')
        .join(', ');

    return validItems.isEmpty ? '-' : validItems;
  }
}

class SquareTabIndicator extends Decoration {
  final Color color;
  final double size;

  SquareTabIndicator({required this.color, this.size = 50.0});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _SquarePainter(color: color, size: size);
  }
}

class _SquarePainter extends BoxPainter {
  final Color color;
  final double size;

  _SquarePainter({required this.color, this.size = 45.0});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double xCenter = offset.dx + (configuration.size!.width - size) / 2;
    final double yCenter = offset.dy + configuration.size!.height - size;

    final Rect rect = Rect.fromLTWH(xCenter, yCenter, size, size);
    canvas.drawRect(rect, paint);
  }
}
