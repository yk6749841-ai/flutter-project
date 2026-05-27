import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipe Master',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
          background: const Color(0xFFFAFAFA),
        ),
      ),
      home: const RecipeScreen(),
    );
  }
}

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  List<dynamic> recipesList = [];
  bool isLoading = false;

  Future<void> searchRecipes(String foodType) async {
    if (foodType.isEmpty) return;
    setState(() { isLoading = true; recipesList = []; });

    final url = 'https://www.themealdb.com/api/json/v1/1/search.php?s=$foodType';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() { recipesList = data['meals'] ?? []; });
      }
    } catch (e) {
      print("Error fetching data");
    }
    setState(() { isLoading = false; });
  }

  // --- פונקציה חדשה: איסוף רכיבים וכמויות ---
  List<String> getIngredients(dynamic recipe) {
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = recipe['strIngredient$i'];
      final measure = recipe['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add("${measure ?? ''} $ingredient");
      }
    }
    return ingredients;
  }

  // --- פונקציה חדשה: יצירת דירוג כוכבים חכם ---
  Widget buildRatingStars(String id) {
    // טריק: משתמשים בספרה האחרונה של ה-ID כדי לקבוע את הכוכבים (בין 3 ל-5)
    int stars = (int.parse(id.substring(id.length - 1)) % 3) + 3;
    int users = int.parse(id.substring(id.length - 2)) * 12; // מספר "משתמשים" מדומיין
    
    return Row(
      children: [
        ...List.generate(5, (index) => Icon(
          Icons.star, 
          size: 16, 
          color: index < stars ? Colors.amber : Colors.grey[300]
        )),
        const SizedBox(width: 5),
        Text("($users)", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void showRecipeDetails(BuildContext context, dynamic recipe) {
    final ingredients = getIngredients(recipe);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(recipe['strMeal'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(recipe['strMealThumb'])),
              const SizedBox(height: 15),
              // הצגת הרכיבים
              const Text('🥗 Ingredients:', textAlign: TextAlign.left, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...ingredients.map((item) => Text('• $item', textAlign: TextAlign.left, style: const TextStyle(fontSize: 15))),
              const SizedBox(height: 20),
              const Text('👨‍🍳 Instructions:', textAlign: TextAlign.left, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(recipe['strInstructions'], textAlign: TextAlign.left, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('סגור'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Recipe Master 🍳', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onSubmitted: (v) => searchRecipes(v),
                decoration: InputDecoration(
                  hintText: 'חפשו מאכל (למשל: chicken)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
                    itemCount: recipesList.length,
                    itemBuilder: (context, i) {
                      final r = recipesList[i];
                      return GestureDetector(
                        onTap: () => showRecipeDetails(context, r),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: Image.network(r['strMealThumb'], fit: BoxFit.cover))),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['strMeal'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    buildRatingStars(r['idMeal']), // כאן נוספו הכוכבים!
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            )
          ],
        ),
      ),
    );
  }
}