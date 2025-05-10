import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/foodItem_model.dart';
import 'AddBySearch.dart';
import 'Cart.dart';
import 'services/user_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddByImage extends StatefulWidget {
  String id;
  final File? image;
  final String? imageUrl;
  final double calorie;
  final double protein;
  final double carb;
  final double fat;
  final String name;
  final List<foodItem>? mealItems;
  String? title;
  DateTime? time;
  final double portion;
  final String source;

  final bool isFavorite;
  final String? favoriteId;
  int? index;

  // final bool isItemFavorite;
  final String? favoriteItemId;

  AddByImage(
      {this.image,
      this.imageUrl,
      required this.id,
      required this.calorie,
      required this.protein,
      required this.carb,
      required this.fat,
      required this.name,
      this.index,
      this.mealItems,
      this.title,
      this.time,
      required this.portion,
      required this.source,
      this.isFavorite = false,
      this.favoriteId = null,
      // this.isItemFavorite = false,
      this.favoriteItemId = null});

  _AddByImage createState() => _AddByImage();
}

class _AddByImage extends State<AddByImage> {
  bool hasEditedTitle = false;
  bool hasEditedNutrutions = false;
  final _formKey = GlobalKey<FormState>();
  late File? image = widget.image;
  late String? imageUrl = widget.imageUrl;
  late double calorie = widget.calorie;
  late double protein = widget.protein;
  late double carb = widget.carb;
  late double fat = widget.fat;
  late String name = widget.name;
  late List<foodItem> mealItems;
  late String source = widget.source;
  double portion = 0.0;
  double totalProtein = 0.0;
  double totalCarb = 0.0;
  double totalFat = 0.0;
  double totalCalorie = 0.0;

  bool _isEditingName = false;
  TextEditingController _nameController = TextEditingController();
  List<TextEditingController> _ingredientControllers = [];

  late bool isFavorite;
  late String? favoriteId;

  late bool isItemFavorite;
  String? favoriteItemId;

  late bool edit;

  UserService user_service = UserService();

  void initState() {
    super.initState();
    // Initialize mealItems with the passed array or an empty list
    mealItems = widget.mealItems ?? [];

    // issign true to isFavorite if favoriteid isnt null
    isFavorite = widget.favoriteId != null ? true : false;
    favoriteId = widget.favoriteId;

    favoriteItemId = widget.favoriteItemId;
    // Set isItemFavorite to true if favoriteItemId is not null
    isItemFavorite = favoriteItemId != null;

    portion = widget.portion;

    totalProtein = protein;
    totalCarb = carb;
    totalFat = fat;
    totalCalorie = calorie;

    edit = widget.index == null ? false : true;

    updatenutritions(portion.toString());
    _nameController.text = name;
  }

  @override
  void dispose() {
    _nameController.dispose(); // Dispose controller when done
    super.dispose();
  }

  void updatenutritions(String value) {
    setState(() {
      portion = double.tryParse(value) ?? 0.0;

      totalCalorie = twoDecimal(calorie);
      totalProtein = twoDecimal(protein);
      totalCarb = twoDecimal(carb);
      totalFat = twoDecimal(fat);
    });
  }

  double twoDecimal(double value) {
    return (value * 100).round() / 100;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // If the form is valid

// TODO check if works
      checkEdit();

      final newItem = foodItem(
        predictedPortion:
            !edit ? widget.portion : mealItems[widget.index!].portion,
        predictedCalorie:
            !edit ? widget.calorie : mealItems[widget.index!].calorie,
        predictedProtein:
            !edit ? widget.protein : mealItems[widget.index!].protein,
        predictedCarb: !edit ? widget.carb : mealItems[widget.index!].carb,
        predictedFat: !edit ? widget.fat : mealItems[widget.index!].fat,
        predictedName: !edit ? widget.name : mealItems[widget.index!].name,
        name: name,
        calorie: (totalCalorie),
        protein: totalProtein,
        carb: totalCarb,
        fat: totalFat,
        portion: portion,
        source: "image",
        image: image,
        favoriteId: favoriteItemId,
      );

      setState(() {
        if (edit) {
          mealItems.removeAt(widget.index!);
        }
        mealItems.add(newItem);
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Cart(
            id: widget.id,
            title: widget.title,
            time: widget.time,
            foodItems: mealItems,
            isFavorite: isFavorite,
            favoriteId: favoriteId,
          ),
        ),
      );
    }
  }

  void _startEditing() {
    List<String> ingredients = name.split(',').map((e) => e.trim()).toList();
    _ingredientControllers = ingredients
        .map((ingredient) => TextEditingController(text: ingredient))
        .toList();
  }

  void _saveEditing() {
    setState(() {
      // Keep only non-empty ingredient texts
      List<String> updatedIngredients = _ingredientControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      // Update the 'name' by joining with commas
      name = updatedIngredients.join(', ');

      // Also refresh the controllers list (remove empty ones)
      _ingredientControllers = updatedIngredients
          .map((ingredient) => TextEditingController(text: ingredient))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF1F4F8),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 30.0,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => edit
                      ? Cart(
                          id: widget.id,
                          title: widget.title,
                          time: widget.time,
                          foodItems: mealItems,
                          isFavorite: isFavorite,
                          favoriteId: favoriteId,
                        )
                      : AddBySearch(
                          id: widget.id,
                          title: widget.title,
                          time: widget.time,
                          mealItems: mealItems,
                          isFavorite: isFavorite,
                          favoriteId: favoriteId,
                        )),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          imageUrl!,
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child; // Show the image once loaded
                            } else {
                              return Center(
                                  child:
                                      CircularProgressIndicator()); // Show a loading spinner while loading
                            }
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // In case of error (invalid URL or network issues), return an empty SizedBox
                            return SizedBox();
                          },
                        ),
                      )
                    : image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              image!,
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          )
                        : SizedBox(), // Return an empty box if no image or url
              ),

              Container(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 5),
                child: Center(
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // important for alignment!
                    children: [
                      Expanded(
                        child: _isEditingName
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ..._ingredientControllers.asMap().entries.map(
                                    (entry) {
                                      int index = entry.key;
                                      TextEditingController controller =
                                          entry.value;
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: controller,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // TODO change color to error?
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _ingredientControllers
                                                    .removeAt(index);
                                              });
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ).toList(),
                                  SizedBox(height: 10),
                                  Center(
                                    child: IconButton(
                                      icon: Icon(Icons.add_circle,
                                          size: 30,
                                          color:
                                              Theme.of(context).primaryColor),
                                      onPressed: () {
                                        setState(() {
                                          _ingredientControllers
                                              .add(TextEditingController());
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                name,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isEditingName ? Icons.check : Icons.edit,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isEditingName) {
                              _saveEditing();
                            } else {
                              _startEditing();
                            }
                            _isEditingName = !_isEditingName;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // white container
              Padding(
                padding: EdgeInsets.all(0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(25, 25, 25, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              _showInfo(
                                context,
                                'AI Nutrition Prediction Notice',
                                Text(
                                  'The nutrition values below are generated by an AI model and might not always be accurate.\n\n'
                                  'Please take a moment to review and correct them if necessary — it helps us improve our predictions!',
                                  style: TextStyle(fontSize: 16),
                                ),
                              );
                            },
                            child: Icon(
                              Icons.info_outline,
                              color: Color.fromRGBO(96, 106, 133, 1),
                              size: 25.0,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                  child: Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFE6F2FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          'images/lipid.png',
                                          width: 10,
                                          height: 10,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                                  child: Text(
                                    'Portion Size',
                                    style: TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isItemFavorite = !isItemFavorite;
                                });

                                if (isItemFavorite) {
                                  saveFavorite();
                                } else {
                                  removeFromFavorite();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                    4, 4, 10, 4), // Give room for icon
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isItemFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isItemFavorite
                                      ? Theme.of(context).colorScheme.error
                                      : const Color(0xFF023B96),
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: widget.portion.toString(),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              decoration: InputDecoration(
                                hintText: 'portion size in grams',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the portion size';
                                }
                                // parse the value to a double for validation
                                final currentPortion = double.tryParse(value);
                                if (currentPortion == null ||
                                    currentPortion <= 0) {
                                  return 'Please enter a number greater than 0';
                                }
                                if (RegExp(r'^\d+\.?\d{0,2}$')
                                        .hasMatch(value) ==
                                    false) {
                                  return 'Please enter to 2 decimal places only';
                                }

                                portion = double.tryParse(value ?? '0') ?? 0.0;
                                return null; // If all validations pass
                              },
                            ),
                          ),
                          // Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                            child: Text(
                              " g     ",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ]),
                        SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'images/wheat.png',
                                      width: 10,
                                      height: 10,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                'Carb',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: totalCarb.toString(),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              decoration: InputDecoration(
                                hintText: 'carb size in grams',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the portion size';
                                }
                                // parse the value to a double for validation
                                final portion = double.tryParse(value);
                                if (portion == null) {
                                  return 'Please enter a number greater than 0';
                                }
                                if (RegExp(r'^\d+\.?\d{0,2}$')
                                        .hasMatch(value) ==
                                    false) {
                                  return 'Please enter to 2 decimal places only';
                                }
                                totalCarb =
                                    double.tryParse(value ?? '0') ?? 0.0;
                                return null; // If all validations pass
                              },
                            ),
                          ),
                          // Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                            child: Text(
                              " g     ",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ]),

                        SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'images/leg.png',
                                      width: 10,
                                      height: 10,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                'Protein',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: totalProtein.toString(),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              decoration: InputDecoration(
                                hintText: 'protein size in grams',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                              validator: (value) {
                                if (value != null) {
                                  // parse the value to a double for validation
                                  final portion = double.tryParse(value);

                                  if (RegExp(r'^\d+\.?\d{0,2}$')
                                          .hasMatch(value) ==
                                      false) {
                                    return 'Please enter to 2 decimal places only';
                                  }
                                }
                                totalProtein =
                                    double.tryParse(value ?? '0') ?? 0.0;
                                return null; // If all validations pass
                              },
                            ),
                          ),
                          // Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                            child: Text(
                              " g     ",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ]),

                        SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'images/lipid.png',
                                      width: 10,
                                      height: 10,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                'Fat',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: totalFat.toString(),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              decoration: InputDecoration(
                                hintText: 'fat size in grams',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                              validator: (value) {
                                if (value != null) {
                                  // parse the value to a double for validation
                                  final portion = double.tryParse(value);

                                  if (RegExp(r'^\d+\.?\d{0,2}$')
                                          .hasMatch(value) ==
                                      false) {
                                    return 'Please enter to 2 decimal places only';
                                  }
                                }
                                totalFat = double.tryParse(value ?? '0') ?? 0.0;
                                return null; // If all validations pass
                              },
                            ),
                          ),
                          // Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                            child: Text(
                              " g     ",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ]),
                        SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FaIcon(
                                      FontAwesomeIcons.fire,
                                      color: Color(0xFF99C2FF),
                                      size: 23,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                'Calories',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: totalCalorie.toString(),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              decoration: InputDecoration(
                                hintText: 'calorie size in kcal',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                              validator: (value) {
                                if (value != null) {
                                  // parse the value to a double for validation
                                  final portion = double.tryParse(value);

                                  if (RegExp(r'^\d+\.?\d{0,2}$')
                                          .hasMatch(value) ==
                                      false) {
                                    return 'Please enter to 2 decimal places only';
                                  }
                                }
                                totalCalorie =
                                    double.tryParse(value ?? '0') ?? 0.0;
                                return null; // If all validations pass
                              },
                            ),
                          ),
                          // Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                            child: Text(
                              " kcal ",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ]),

// add button
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      _submitForm();
                                    }
                                  },
                                  child: Text(
                                    edit ? 'Edit' : 'Add Food Item',
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF023B96),
                                    minimumSize: Size(double.infinity, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 100),
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

  void saveFavorite() async {
    if (imageUrl == null) {
      if (image != null) {
        if (image != null) {
          imageUrl = await uploadImage(image!);
        }
      }
    }

    // If favoriteId is null, it's a new favorite, so add it
    if (favoriteItemId == null) {
      foodItem item = foodItem(
        name: name,
        calorie: totalCalorie,
        protein: totalProtein,
        carb: totalCarb,
        fat: totalFat,
        portion: portion,
        source: source,
        favoriteId: favoriteItemId,
        imageUrl: imageUrl,
      );
      favoriteItemId = await user_service.addItemToFavorite(item);

      if (widget.index != null) {
        mealItems[widget.index!].favoriteId = favoriteItemId;
      }
    } else {
      // Otherwise, update the existing favorite
      user_service.updateFavoriteItem(
        itemId: favoriteItemId!,
        newName: name,
        newCalorie: totalCalorie,
        newProtein: totalProtein,
        newCarb: totalCarb,
        newFat: totalFat,
        newPortion: portion,
        newSource: source,
      );
    }
  }

  void removeFromFavorite() {
    if (favoriteItemId != null) {
      user_service.removeItemFromFavorite(favoriteItemId!);
      favoriteItemId = null;
      if (widget.index != null) {
        mealItems[widget.index!].favoriteId = favoriteItemId;
      }
    }
  }

  String _generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<String?> uploadImage(File image) async {
    try {
      // Debug: Start of the uploadImage function

      // get the extenstion of the image
      String fileExtension = image.path.split('.').last;

      // Create a unique file name for the image
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String randomString =
          _generateRandomString(10); // Generate a random string
      String? userId = user_service
          .currentUserId; // Replace with actual user ID retrieval logic

      // Combining user ID, timestamp, and random string to form a unique file name
      String fileName =
          '${userId ?? 'defaultUserId'}_$timestamp$randomString.$fileExtension';

      final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://insulinsync.firebasestorage.app');

      // Reference to Firebase Storage
      Reference ref =
          storage.ref().child(userId ?? 'defaultUserId').child(fileName);

      // Upload the image file to Firebase Storage
      UploadTask uploadTask = ref.putFile(image);

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() => null);

      // Check if upload was successful
      if (snapshot.state == TaskState.success) {
        // Get the download URL of the uploaded image
        String downloadUrl = await snapshot.ref.getDownloadURL();

        return downloadUrl;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void checkEdit() {
    hasEditedNutrutions = (totalCalorie != widget.calorie ||
        totalProtein != widget.protein ||
        totalCarb != widget.carb ||
        totalFat != widget.fat ||
        portion != widget.portion);
    if (hasEditedNutrutions) {
      print('Nutritional values have been edited.');
    } else {
      print('Nutritional values have not been edited.');
    }
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
}
