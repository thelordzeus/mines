import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

void main() => runApp(MinesApp());

class MinesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mines Game',
      theme: ThemeData.dark(),
      home: MinesGameScreen(),
    );
  }
}

class MinesGameScreen extends StatefulWidget {
  @override
  _MinesGameScreenState createState() => _MinesGameScreenState();
}

class _MinesGameScreenState extends State<MinesGameScreen> {
  final int gridSize = 5;
  int mineCount = 3;
  int wallet = 1000;
  int betAmount = 10;
  bool gameActive = false;
  late List<List<bool>> mines;
  late List<List<bool>> revealed;
  late ConfettiController _confettiController;
  String winningsMessage = '';

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _generateMines();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generateMines() {
    mines =
        List.generate(gridSize, (i) => List.generate(gridSize, (j) => false));
    revealed =
        List.generate(gridSize, (i) => List.generate(gridSize, (j) => false));

    Random random = Random();
    int placedMines = 0;
    while (placedMines < mineCount) {
      int row = random.nextInt(gridSize);
      int col = random.nextInt(gridSize);
      if (!mines[row][col]) {
        mines[row][col] = true;
        placedMines++;
      }
    }
  }

  void _revealTile(int row, int col) {
    setState(() {
      revealed[row][col] = true;
      if (mines[row][col]) {
        wallet -= betAmount;
        gameActive = false;
      }
    });
  }

  void _startGame() {
    setState(() {
      if (wallet >= betAmount) {
        wallet -= betAmount;
        gameActive = true;
        _generateMines();
      }
    });
  }

  void _cashOut() {
    int safeTiles = 0;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (revealed[i][j] && !mines[i][j]) {
          safeTiles++;
        }
      }
    }
    int winnings = (betAmount * 0.5 * safeTiles).toInt();
    setState(() {
      wallet += winnings;
      gameActive = false;
      winningsMessage = '+\$${winnings.toString()}';
    });
    _confettiController.play();
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        winningsMessage = '';
      });
    });
  }

  void _resetGame() {
    setState(() {
      _generateMines();
      gameActive = false;
    });
  }

  void _addMoney() {
    setState(() {
      wallet += 100;
    });
  }

  Widget _buildGrid() {
    return GridView.builder(
      itemCount: gridSize * gridSize,
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize),
      itemBuilder: (context, index) {
        int row = index ~/ gridSize;
        int col = index % gridSize;
        return GestureDetector(
          onTap: gameActive ? () => _revealTile(row, col) : null,
          child: Container(
            margin: EdgeInsets.all(2.0),
            color: revealed[row][col]
                ? (mines[row][col] ? Colors.red : Colors.green)
                : Colors.grey,
            child: Center(
              child: revealed[row][col]
                  ? (mines[row][col]
                      ? Icon(Icons.warning, color: Colors.black)
                      : Icon(Icons.check, color: Colors.black))
                  : null,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mines Game'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Wallet: \$${wallet}', style: TextStyle(fontSize: 24)),
                    AnimatedOpacity(
                      opacity: winningsMessage.isEmpty ? 0.0 : 1.0,
                      duration: Duration(seconds: 1),
                      child: Text(
                        ' $winningsMessage',
                        style: TextStyle(fontSize: 24, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                Text('Mines: $mineCount', style: TextStyle(fontSize: 18)),
                Slider(
                  value: mineCount.toDouble(),
                  min: 1,
                  max: (gridSize * gridSize - 1).toDouble(),
                  divisions: gridSize * gridSize - 1,
                  label: mineCount.toString(),
                  onChanged: (value) {
                    setState(() {
                      mineCount = value.toInt();
                      _generateMines();
                    });
                  },
                ),
                Text('Bet Amount: \$${betAmount}',
                    style: TextStyle(fontSize: 20)),
                Slider(
                  value: betAmount.toDouble(),
                  min: 1,
                  max: wallet.toDouble(),
                  divisions: wallet,
                  label: betAmount.toString(),
                  onChanged: (value) {
                    setState(() {
                      betAmount = value.toInt();
                    });
                  },
                ),
                Expanded(child: _buildGrid()),
                ElevatedButton(
                    onPressed: _startGame, child: Text('Start Game')),
                ElevatedButton(
                  onPressed: gameActive ? _cashOut : null,
                  child: Text('Cash Out'),
                ),
                ElevatedButton(
                    onPressed: _resetGame, child: Text('Reset Game')),
                ElevatedButton(
                    onPressed: _addMoney, child: Text('Add \$100 to Wallet')),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}
