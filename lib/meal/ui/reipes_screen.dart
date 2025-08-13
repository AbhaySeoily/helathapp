
import 'package:flutter/material.dart';

class RecipesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final recipes = ['Oat Pancakes','Quinoa Salad','Grilled Veggies'];
    return Scaffold(appBar: AppBar(title: Text('Healthy Recipes')), body: ListView.builder(itemCount: recipes.length, itemBuilder: (_,i){
      return Card(child: ListTile(title: Text(recipes[i]), subtitle: Text('Quick & healthy')));
    }));
  }
}