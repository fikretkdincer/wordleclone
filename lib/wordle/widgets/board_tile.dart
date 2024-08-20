import 'package:flutter/material.dart';
import 'package:wordleclone/wordle/wordle.dart';

class BoardTile extends StatelessWidget {
  const BoardTile({
    super.key,
    required this.letter,
  });

  final Letter letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      height: 60,
      width: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: letter.backgroundColor,
        border: Border.all(color: letter.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        letter.val,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
