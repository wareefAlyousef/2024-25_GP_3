import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/foodItem_model.dart';
import '../services/user_service.dart';
import 'Cart.dart';

class EditNutritions extends StatefulWidget {
  @override
  final int index;
  String? title;
  final List<foodItem>? mealItems;
  // final bool isItemFavorite;
  final bool isFavorite;
  final String? favoriteId;
  final String? favoriteItemId;
  final DateTime time;
  final String title2;
  final String id;

  EditNutritions({
    this.title,
    required this.index,
    this.mealItems,
    this.isFavorite = false,
    this.favoriteId = null,
    this.favoriteItemId = null,
    DateTime? time,
    String? title2,
    String? id,
  })  : this.time = time ?? DateTime(1990, 1, 1, 12),
        this.title2 = title ?? "Title is not defined",
        this.id = id ?? "-1";

  _EditNutritions createState() => _EditNutritions();
}

class _EditNutritions extends State<EditNutritions> {
  late List<foodItem> mealItems;
  late int index;
  late DateTime initialTime1;
  late String initialTitle;
  late String initialId;
  String _carb = "";
  String _fat = "";
  String _protein = "";
  String _calorie = "";
  String? _name = "";
  late foodItem item;
  final _formKey = GlobalKey<FormState>();
  double protein = 0.0;
  double carb = 0.0;
  double fat = 0.0;
  double calorie = 0.0;
  String title = "";

  late bool isFavorite;
  late String? favoriteId;

  late bool isItemFavorite;
  late String? favoriteItemId;

  late FocusNode titleFocusNode;

  UserService user_service = UserService();

  var titleController = TextEditingController();
  var carbController = TextEditingController();
  var proteinController = TextEditingController();
  var fatController = TextEditingController();
  var calorieController = TextEditingController();

  void initState() {
    super.initState();
    // Initialize mealItems with the passed array or an empty list
    mealItems = widget.mealItems ?? [];
    isFavorite = widget.isFavorite;
    favoriteId = widget.favoriteId;

    favoriteItemId = widget.favoriteItemId;

// Set isItemFavorite to true if favoriteItemId is not null
    isItemFavorite = favoriteItemId != null;

    titleFocusNode = FocusNode();

    // Add the listener to detect when focus changes
    titleFocusNode.addListener(() {
      if (!titleFocusNode.hasFocus) {
        print("#@#@#@#@#@ lost focus");
        // Call saveFavorite when the field loses focus
        saveFavorite();
      }
    });

    index = widget.index;
    if (index >= 0 && index < mealItems.length) {
      item = mealItems[index];
    }
    protein = item.protein;
    carb = item.carb;
    fat = item.fat;
    calorie = item.calorie;
    title = item.name;
    titleController.text = title;
    carbController.text = carb.toString();
    proteinController.text = protein.toString();
    fatController.text = fat.toString();
    calorieController.text = calorie.toString();

    initialTitle = widget.title2;
    initialId = widget.id;
    initialTime1 = widget.time;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // If the form is valid
      double _carbdouble = double.parse(_carb);
      double _proteindouble = double.parse(_protein);
      double _fatdouble = double.parse(_fat);
      double _caloriedouble = double.parse(_calorie);
      String name = _name ?? "food item";

      if (name == null || name == "") {
        name = "food item";
      }

      print('debug edit nut: in submit form favoriteItemId $favoriteItemId');

      final newItem = foodItem(
        name: name,
        calorie: _caloriedouble,
        protein: _proteindouble,
        carb: _carbdouble,
        fat: _fatdouble,
        portion: -1,
        source: "nutritions",
        favoriteId: favoriteItemId,
      );

      setState(() {
        mealItems[index] = newItem;
        print("edit  item: $newItem"); // Debugging print
      });

      print('Meal items after edit:');
      for (var item in mealItems) {
        print(item);
      }

      print('Meal items done');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Cart(
              title: widget.title,
              foodItems: mealItems,
              isFavorite: isFavorite,
              favoriteId: favoriteId,
              id: initialId,
              time: initialTime1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf1f4f8),
      appBar: AppBar(
        backgroundColor: Color(0xFFf1f4f8),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 30.0,
          ),
          onPressed: () {
            final newItem = foodItem(
              name: titleController.text.isEmpty
                  ? "food item"
                  : titleController.text,
              calorie: calorie,
              protein: protein,
              carb: carb,
              fat: fat,
              portion: -1,
              source: "nutritions",
              favoriteId: favoriteItemId,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Cart(
                        id: initialId,
                        title: widget.title,
                        foodItems: mealItems,
                        isFavorite: isFavorite,
                        favoriteId: favoriteId,
                      )),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
//page title
              Padding(
                padding: EdgeInsets.fromLTRB(5, 20, 15, 10),
                child: Text(
                  'Add Nutritions',
                  style: TextStyle(
                    fontSize: 30, //check with raneem
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
//form
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
// white square
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                            color: Color(0x33000000),
                            offset: Offset(0, 2),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(8),
                      ),
//inside the container
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(0, 10, 20, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isItemFavorite =
                                          !isItemFavorite; // Toggle favorite state
                                    });

                                    // Call the appropriate function based on the state
                                    if (isItemFavorite) {
                                      saveFavorite(); // Call function when favorited
                                    } else {
                                      removeFromFavorite(); // Call function when removed from favorites
                                    }
                                  },
                                  child: Container(
                                    width: 21,
                                    padding: const EdgeInsets.all(0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      // border:
                                      //     Border.all(color: const Color(0xFF023B96)),
                                    ),
                                    child: Icon(
                                      isItemFavorite
                                          ? Icons.favorite
                                          : Icons
                                              .favorite_border, // Dynamic icon
                                      color: isItemFavorite
                                          ? Theme.of(context).colorScheme.error
                                          : const Color(
                                              0xFF023B96), // Dynamic color
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
//user input 1
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 30, 25, 0),
                            child: TextFormField(
                              controller: titleController,
                              focusNode: titleFocusNode,
                              // initialValue: title,
                              decoration: InputDecoration(
                                hintText: 'Item Name (Optional)',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                    EdgeInsets.fromLTRB(0, 16, 16, 8),
                              ),
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                              validator: (value) {
                                if (value != null && value.length > 20) {
                                  return 'Name cannot exceed 20 characters';
                                }
                                _name = value;
                                return null; // validation passed
                              },
                              onFieldSubmitted: (_) {
                                // Manually unfocus the title field when submit is pressed
                                titleFocusNode
                                    .unfocus(); // This will trigger the focus listener in initState
                              },
                            ),
                          ),

                          // SizedBox(height: 20),
// user input 1
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 15, 0, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Carb * ',
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: Color.fromRGBO(96, 106, 133, 1),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(0, 0, 25, 0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: carbController,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d*\.?\d*')),
                                            ],
                                            decoration: InputDecoration(
                                              hintText: 'Amount in grams',
                                              filled: true,
                                              fillColor: Colors.grey[100],
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter the carb';
                                              }

                                              final carbValue =
                                                  double.tryParse(value);
                                              if (carbValue == null ||
                                                  carbValue <= 0) {
                                                return 'greater than 0';
                                              }
                                              if (!RegExp(r'^\d+\.?\d{0,2}$')
                                                  .hasMatch(value)) {
                                                return '2 decimal places only';
                                              }
                                              _carb = value;
                                              return null; // If all validations pass
                                            },
                                            onFieldSubmitted: (_) {
                                              saveFavorite(); // This will trigger the focus listener in initState
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 10, 0, 0),
                                          child: Text(
                                            '     g',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
// user input 2
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 25, 0, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Protein',
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: Color.fromRGBO(96, 106, 133, 1),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(0, 0, 25, 0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: proteinController,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d*\.?\d*')),
                                            ],
                                            decoration: InputDecoration(
                                              hintText: 'Amount in grams',
                                              filled: true,
                                              fillColor: Colors.grey[100],
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                value = "0";
                                              }

                                              final proteinValue =
                                                  double.tryParse(value);

                                              if (!RegExp(r'^\d+\.?\d{0,2}$')
                                                  .hasMatch(value)) {
                                                return '2 decimal places only';
                                              }
                                              _protein = value;
                                              return null; // If all validations pass
                                            },
                                            onFieldSubmitted: (_) {
                                              saveFavorite(); // This will trigger the focus listener in initState
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 10, 0, 0),
                                          child: Text(
                                            '     g',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // user input 1
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 25, 0, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Fat       ',
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: Color.fromRGBO(96, 106, 133, 1),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(0, 0, 25, 0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: fatController,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d*\.?\d*')),
                                            ],
                                            decoration: InputDecoration(
                                              hintText: 'Amount in grams',
                                              filled: true,
                                              fillColor: Colors.grey[100],
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                value = "0";
                                              }

                                              final fatValue =
                                                  double.tryParse(value);

                                              if (!RegExp(r'^\d+\.?\d{0,2}$')
                                                  .hasMatch(value)) {
                                                return '2 decimal places only';
                                              }
                                              _fat = value;
                                              return null; // If all validations pass
                                            },
                                            onFieldSubmitted: (_) {
                                              saveFavorite(); // This will trigger the focus listener in initState
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 10, 0, 0),
                                          child: Text(
                                            '     g',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // user input 4
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 25, 0, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Calorie',
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: Color.fromRGBO(96, 106, 133, 1),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(0, 0, 25, 0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: calorieController,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d*\.?\d*')),
                                            ],
                                            decoration: InputDecoration(
                                              hintText: 'Amount in grams',
                                              filled: true,
                                              fillColor: Colors.grey[100],
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                value = "0";
                                              }

                                              final calorieValue =
                                                  double.tryParse(value);

                                              if (!RegExp(r'^\d+\.?\d{0,2}$')
                                                  .hasMatch(value)) {
                                                return '2 decimal places only';
                                              }
                                              _calorie = value;
                                              return null; // If all validations pass
                                            },
                                            onFieldSubmitted: (_) {
                                              saveFavorite(); // This will trigger the focus listener in initState
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 10, 0, 0),
                                          child: Text(
                                            'kcal',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 35),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Validate the form and then open the dialog
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  _submitForm();
                                }
                              },
                              child: Text(
                                'Edit Food Item',
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TODO deal with the case where there is 0 after deleting from the fooditems
  void saveFavorite() async {
    if (!isItemFavorite) return;

    if (carbController.text.isEmpty) {
      removeFromFavorite();
      return;
    }
    // Create the foodItem object with safe parsing
    print(
        '#@#@#@#@#@ savefavorite in addNutrition has the name ${titleController.text}');

    print('debug edit nut: in line 750 favoriteItemId $favoriteItemId');
    foodItem item = foodItem(
      name: titleController.text.isEmpty ? "food item" : titleController.text,

      calorie: calorieController.text.isEmpty
          ? 0.0
          : double.tryParse(calorieController.text) ??
              0.0, // Check if empty, then parse
      protein: proteinController.text.isEmpty
          ? 0.0
          : double.tryParse(proteinController.text) ??
              0.0, // Check if empty, then parse
      carb: carbController.text.isEmpty
          ? 0.0
          : double.tryParse(carbController.text) ??
              0.0, // Check if empty, then parse
      fat: fatController.text.isEmpty
          ? 0.0
          : double.tryParse(fatController.text) ??
              0.0, // Check if empty, then parse
      portion: -1,
      source: "nutritions",
      favoriteId: favoriteItemId,
    );

    // If favoriteId is null, it's a new favorite, so add it
    if (favoriteItemId == null) {
      print('debug edit nut: in line 777 favoriteItemId $favoriteItemId');
      favoriteItemId = await user_service.addItemToFavorite(item);
      print('#@#@#@#@#@ favoriteId is null now adding ${favoriteItemId}');

      if (widget.index != null) {
        mealItems[widget.index!].favoriteId = favoriteItemId;
      }

      print('debug edit nut: in line 785 favoriteItemId $favoriteItemId');
    } else {
      print('#@#@#@#@#@ favoriteId not null');
      print('#@#@#@#@#@ now updating ${favoriteItemId}');

      print('debug edit nut: in line 784 favoriteItemId $favoriteItemId');

      // Otherwise, update the existing favorite
      user_service.updateFavoriteItem(
        itemId: favoriteItemId!,
        newName: item.name,
        newCalorie: item.calorie, // Use tryParse and default to 0.0
        newProtein: item.protein, // Use tryParse and default to 0.0
        newCarb: item.carb, // Use tryParse and default to 0.0
        newFat: item.fat, // Use tryParse and default to 0.0
        newPortion: -1,
        newSource: "nutritions",
      );
    }
  }

  void removeFromFavorite() {
    if (favoriteItemId != null) {
      user_service.removeItemFromFavorite(favoriteItemId!);
      favoriteItemId = null;
      print(
          '#@#@#@#@#@ favoriteId is $favoriteItemId now after removing removing');
    }
  }
}
