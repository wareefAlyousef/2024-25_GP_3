import 'package:flutter/material.dart';
import 'package:insulin_sync/addByBarcode.dart';
import 'widgets.dart';
import 'AddFoodItem.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'models/foodItem_model.dart';
import 'addnNutrition.dart';
import 'Cart.dart'; 
import 'MainNavigation.dart';

class AddBySearch extends StatefulWidget {
  final List<foodItem>? mealItems; // Optional meal items array, now a list of foodItem objects

  const AddBySearch({super.key, this.mealItems}); // Accept mealItems as an optional parameter

  @override
  State<AddBySearch> createState() => _AddBySearch();
}

class _AddBySearch extends State<AddBySearch> {
  final _textController = TextEditingController();
  final _textFieldFocusNode = FocusNode();
  List<foodItem> _foodDetails = [];
  bool _isLoading = false;
  bool _isFocused = false;
  String _scanResult = "";

  // To keep track of the selected item
  int? _selectedFoodIndex;

  // Optional meal items array, inherited from previous class if provided
  late final List<foodItem> mealItems;

  @override
  void initState() {
    super.initState();
    // Initialize mealItems with the passed array if available, or an empty array
    mealItems = widget.mealItems ?? [];
    searchAndDisplayFood(''); // Optionally perform a default search
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
  // Barcode Scan method
   Future<void> _scanBarcode() async {
    String scanRes;
    try {
      scanRes = await FlutterBarcodeScanner.scanBarcode( "#023B96", "Cancel",  true, ScanMode.DEFAULT, );
    } catch (error) {
      scanRes = 'Failed to scan:';
    }

    if (!mounted) return;

    setState(() {
      // scan is  done
       if (scanRes != '-1' && scanRes != 'Failed to scan:' ) {
        //succefull scan 
         _scanResult = scanRes; // item code
        NutritionalData(_scanResult);

      }else {
      //scan canceled 
      }
      
    });
  }

  // call nutrions API method
  Future<void> NutritionalData(String barcode) async {
  final String apiUrl = 'https://world.openfoodfacts.org/api/v0/product/$barcode.json';

  try {
    
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {

      final Map<String, dynamic> data = json.decode(response.body);
   

      if (data['product'] != null && data['product']['nutriments'] != null) {
         var product = data['product'];
         var nutrients = product['nutriments'];
        if (  nutrients['carbohydrates_100g'] == null || nutrients['energy-kcal']== null  || nutrients['fat']== null  || nutrients['proteins'] == null  ){

         showErrorDialog("Nutritional data for this product is not available.");
        }else{
        // nutritional data
       
        var Name = product['product_name'] ?? 'Name is unavailable';
        var nutrients = product['nutriments']; 
        var carbohydrates = (nutrients['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0;
        var calorie = (nutrients['energy-kcal'] as num?)?.toDouble() ?? 0.0;
        var fat = (nutrients['fat'] as num?)?.toDouble() ?? 0.0;
        var protein = (nutrients['proteins'] as num?)?.toDouble() ?? 0.0;
        // go to grams page and send name,cal,carb, pro,fat
        Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>   addByBarcode(
      calorie, protein, carbohydrates, fat, Name, mealItems)
      ),); 

        } 
      } else {
        
       showErrorDialog("Nutritional data for this product is not available.");
      }
    } else {
     
          showErrorDialog("No product found for this barcode.");
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
                    MaterialPageRoute(builder: (context) => AddBySearch(mealItems: mealItems)),
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
                    MaterialPageRoute(builder: (context) => AddNutrition(mealItems: mealItems)),
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



void navigateToAddFoodItem(foodItem food) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Addfooditem(
        calorie: food.calorie,
        protein: food.protein,
        carb: food.carb,
        fat: food.fat,
        name: food.name,
        portion: food.portion,
        source: food.source,
        mealItems: mealItems, 
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                Icons.arrow_back_ios,
                color: Color.fromARGB(255, 0, 0, 0),
                  size: 30,
                    ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Cart(foodItems: mealItems)),
                  );
                },
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
              const SizedBox(width: 0),
              const Text(
                'Add Ingredients',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.0,
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
              padding: const EdgeInsets.symmetric(horizontal: 27.0, vertical: 6),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    const SizedBox(height: 170),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                        child: Text(
                          'Add Meal Ingredients From The Search Bar Or By Scanning The Ingredient\'s Barcode!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            letterSpacing: 0.0,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                     ),
                  ],
                ),
              ),
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
            if (_foodDetails.isEmpty && _isFocused && _textController.text.isNotEmpty && !_isLoading)
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
                              builder: (context) => AddNutrition(mealItems: mealItems),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            )
                          : BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
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
            final food = _foodDetails[index]; // Get the food item by index
            return GestureDetector(
              onTap: () {
                // Update the selected food index
                setState(() {
                  _selectedFoodIndex = index; // Highlight the tapped item
                });
                print('Preparing to send the following data:');
                print('Name: ${food.name}');
                print('Calories: ${food.calorie}');
                print('Protein: ${food.protein}');
                print('Carbs: ${food.carb}');
                print('Fat: ${food.fat}');
                print('Portion: ${food.portion}');

                navigateToAddFoodItem(food); // Pass the foodItem object directly
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



Future<void> searchFood(String searchExpression) async {

  final String consumerKey = "e8d5986b473d4d5f9403c45089673295";
  final String consumerSecret = "f6f68754b37947149440701c6f4a18a5";

  // Step 1: Generate timestamp and nonce
  final oauthTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  final oauthNonce = base64UrlEncode(List<int>.generate(32, (i) => Random().nextInt(256))).replaceAll('=', '');

  // Step 2: Prepare the parameters
  final parameters = {
    'oauth_consumer_key': consumerKey,
    'oauth_signature_method': 'HMAC-SHA1',
    'oauth_timestamp': oauthTimestamp,
    'oauth_nonce': oauthNonce,
    'oauth_version': '1.0',
    'method': 'foods.search',
    'search_expression': searchExpression,
    'format': 'json',
  };

  // Step 3: Normalize the parameters and create the signature base string
  final normalizedParams = parameters.entries
      .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .toList()
    ..sort();
  final paramString = normalizedParams.join('&');

  final httpMethod = 'GET';
  final baseUrl = 'https://platform.fatsecret.com/rest/server.api';
  final signatureBaseString = '$httpMethod&${Uri.encodeQueryComponent(baseUrl)}&${Uri.encodeQueryComponent(paramString)}';

  // Step 4: Create the signing key
  final signingKey = '${Uri.encodeQueryComponent(consumerSecret)}&';

  // Step 5: Generate the HMAC-SHA1 signature
  final hmacSha1 = Hmac(sha1, utf8.encode(signingKey));
  final digest = hmacSha1.convert(utf8.encode(signatureBaseString));
  final signature = base64Encode(digest.bytes);
  final encodedSignature = Uri.encodeQueryComponent(signature);

  // Step 6: Construct the full URL with parameters
  final requestUrl = '$baseUrl?$paramString&oauth_signature=$encodedSignature';

  // Step 7: Make the GET request
  final response = await http.get(Uri.parse(requestUrl));

  if (response.statusCode == 200) {
    print('Response: ${response.body}');
  } else {
    print('Error: ${response.statusCode} ${response.reasonPhrase}');
  }
}


Future<List<foodItem>> searchFood1(String query) async {
  final String consumerKey = "e8d5986b473d4d5f9403c45089673295";
  final String consumerSecret = "f6f68754b37947149440701c6f4a18a5";
  query = query.trim();

  final oauthTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  final oauthNonce = base64UrlEncode(List<int>.generate(32, (i) => Random().nextInt(256))).replaceAll('=', '');

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
      .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .toList()
    ..sort();
  final paramString = normalizedParams.join('&');

  final httpMethod = 'GET';
  final baseUrl = 'https://platform.fatsecret.com/rest/server.api';
  final signatureBaseString = '$httpMethod&${Uri.encodeQueryComponent(baseUrl)}&${Uri.encodeQueryComponent(paramString)}';

  final signingKey = '${Uri.encodeQueryComponent(consumerSecret)}&';

  final hmacSha1 = Hmac(sha1, utf8.encode(signingKey));
  final digest = hmacSha1.convert(utf8.encode(signatureBaseString));
  final signature = base64Encode(digest.bytes);
  final encodedSignature = Uri.encodeQueryComponent(signature);

  final requestUrl = '$baseUrl?$paramString&oauth_signature=$encodedSignature';

  double _parsePortionToGrams(String portionString) {
    if (portionString.contains('g')) {
      // Extract numeric value for gram-based portions
      return double.tryParse(RegExp(r'[\d.]+').stringMatch(portionString) ?? '0') ?? 0.0;
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

      if (data != null && data['foods'] != null && data['foods']['food'] != null) {
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
            final String portionString = portionMatch != null ? portionMatch.group(1) ?? '' : '';
            final double portion = _parsePortionToGrams(portionString); // Convert to grams

            // Extract nutritional values
            final RegExp nutritionRegex = RegExp(r'Calories:\s?([\d.]+)kcal\s?\|\s?Fat:\s?([\d.]+)g\s?\|\s?Carbs:\s?([\d.]+)g\s?\|\s?Protein:\s?([\d.]+)g');
            final match = nutritionRegex.firstMatch(description);

            final double calories = match != null ? double.tryParse(match.group(1) ?? '0') ?? 0.0 : 0.0;
            final double fat = match != null ? double.tryParse(match.group(2) ?? '0') ?? 0.0 : 0.0;
            final double carb = match != null ? double.tryParse(match.group(3) ?? '0') ?? 0.0 : 0.0;
            final double protein = match != null ? double.tryParse(match.group(4) ?? '0') ?? 0.0 : 0.0;

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
      throw Exception('Failed to load food data, status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred while fetching food data: $e');
    return [];
  }

}
