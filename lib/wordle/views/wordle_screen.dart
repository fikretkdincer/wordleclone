import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:wordleclone/wordle/wordle.dart';
import 'dart:math';
import 'package:wordleclone/wordle/data/word_list.dart';
import 'package:flip_card/flip_card.dart';

enum GameStatus { playing, submitting, lost, won }

class WordleScreen extends StatefulWidget {
  const WordleScreen({super.key});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  GameStatus _gameStatus = GameStatus.playing;
  final List<Word> _board = List.generate(
      6, (_) => Word(letters: List.generate(5, (_) => Letter.empty())));

  final List<List<GlobalKey<FlipCardState>>> _flipCardKeys = List.generate(
    6,
    (_) => List.generate(5, (_) => GlobalKey<FlipCardState>()),
  );

  int _currentWordIndex = 0;

  Word? get _currentWord =>
      _currentWordIndex < _board.length ? _board[_currentWordIndex] : null;

  Word _solution = Word.fromString(
    fiveLetterWords[Random().nextInt(fiveLetterWords.length)],
  );

  final Set<Letter> _keyboardLetters = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'WORDLE',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Board(board: _board, flipCardKeys: _flipCardKeys),
            const SizedBox(
              height: 80,
            ),
            Keyboard(
              onKeyTapped: _onKeyTapped,
              onDeleteTapped: _onDeleteTapped,
              onEnterTapped: _onEnterTapped,
              letters: _keyboardLetters,
            )
          ],
        ));
  }

  void _onKeyTapped(String val) {
    if (_gameStatus == GameStatus.playing) {
      setState(() => _currentWord?.addLetter(val));
    }
  }

  void _onDeleteTapped() {
    if (_gameStatus == GameStatus.playing) {
      setState(() => _currentWord?.removeLetter());
    }
  }

  Future<void> _onEnterTapped() async {
    if (fiveLetterWords.contains(_currentWord?.wordString)) {
      if (_gameStatus == GameStatus.playing &&
          _currentWord != null &&
          !_currentWord!.letters.contains(Letter.empty())) {
        _gameStatus = GameStatus.submitting;

        // Count occurrences of each letter in the solution
        Map<Letter, int> letterCount = HashMap();
        for (var letter in _solution.letters) {
          letterCount.update(letter, (value) => value + 1, ifAbsent: () => 1);
        }

        // First pass: mark correct letters
        for (var i = 0; i < _currentWord!.letters.length; i++) {
          final currentWordLetter = _currentWord!.letters[i];
          final currentSolutionLetter = _solution.letters[i];

          if (currentWordLetter == currentSolutionLetter) {
            setState(() {
              _currentWord!.letters[i] =
                  currentWordLetter.copyWith(status: LetterStatus.correct);
            });
            letterCount.update(currentSolutionLetter, (value) => value - 1);
          }
        }

        // Second pass: mark in-word and notInWord letters
        for (var i = 0; i < _currentWord!.letters.length; i++) {
          final currentWordLetter = _currentWord!.letters[i];

          if (_currentWord!.letters[i].status != LetterStatus.correct) {
            if (_solution.letters.contains(currentWordLetter) &&
                letterCount[currentWordLetter] != null &&
                letterCount[currentWordLetter]! > 0) {
              setState(() {
                _currentWord!.letters[i] =
                    currentWordLetter.copyWith(status: LetterStatus.inWord);
              });
              letterCount.update(currentWordLetter, (value) => value - 1);
            } else {
              setState(() {
                _currentWord!.letters[i] =
                    currentWordLetter.copyWith(status: LetterStatus.notInWord);
              });
            }
          }
        }

        // Update the keyboard letters immediately after setting statuses
        setState(() {
          for (var i = 0; i < _currentWord!.letters.length; i++) {
            final currentWordLetter = _currentWord!.letters[i];
            final letter = _keyboardLetters.firstWhere(
              (e) => e.val == currentWordLetter.val,
              orElse: () => Letter.empty(),
            );
            if (letter.status != LetterStatus.correct) {
              _keyboardLetters
                  .removeWhere((e) => e.val == currentWordLetter.val);
              _keyboardLetters.add(_currentWord!.letters[i]);
            }
          }
        });

        // Flip cards with a delay
        for (var i = 0; i < _currentWord!.letters.length; i++) {
          await Future.delayed(
            const Duration(milliseconds: 150),
            () =>
                _flipCardKeys[_currentWordIndex][i].currentState?.toggleCard(),
          );
        }

        _checkWinOrLoss();
      }
    } else if (_gameStatus == GameStatus.playing &&
        _currentWord != null &&
        !_currentWord!.letters.contains(Letter.empty())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          dismissDirection: DismissDirection.horizontal,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.white,
          content: Container(
              height: 25,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
              child: const Column(
                children: [
                  Text(
                    'Not In Word List',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              )),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _checkWinOrLoss() {
    if (_currentWord!.wordString == _solution.wordString) {
      _gameStatus = GameStatus.won;
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('You Won!'),
              content:
                  Text('You guessed the word at your $_currentWordIndex. try!'),
              actions: [
                MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => HomeScreen()));
                  },
                  child: const Text('Menu'),
                ),
                MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _restart();
                  },
                  child: const Text('New Game'),
                )
              ],
            );
          });
    } else if (_currentWordIndex + 1 >= _board.length) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('You Lost!'),
              content: Text('Solution: ${_solution.wordString}.'),
              actions: [
                MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => HomeScreen()));
                  },
                  child: const Text('Menu'),
                ),
                MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _restart();
                  },
                  child: const Text('New Game'),
                )
              ],
            );
          });
    } else {
      _gameStatus = GameStatus.playing;
    }
    _currentWordIndex += 1;
  }

  void _restart() {
    setState(() {
      _gameStatus = GameStatus.playing;
      _currentWordIndex = 0;
      _board
        ..clear()
        ..addAll(
          List.generate(
              6, (_) => Word(letters: List.generate(5, (_) => Letter.empty()))),
        );
      _solution = Word.fromString(
          fiveLetterWords[Random().nextInt(fiveLetterWords.length)]
              .toUpperCase());
      _flipCardKeys
        ..clear()
        ..addAll(
          List.generate(
            6,
            (_) => List.generate(5, (_) => GlobalKey<FlipCardState>()),
          ),
        );
      _keyboardLetters.clear();
    });
  }
}
