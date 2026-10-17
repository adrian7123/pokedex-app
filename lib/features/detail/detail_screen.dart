import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.pokemonId, this.siblings});
  final int pokemonId;

  /// Ordem da lista de onde veio, para deslizar ao vizinho.
  final List<int>? siblings;

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('$pokemonId')));
}
