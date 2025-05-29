import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const PongWarsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PongWarsPage extends StatefulWidget {
  const PongWarsPage({super.key});

  @override
  State<PongWarsPage> createState() => _PongWarsPageState();
}

class _PongWarsPageState extends State<PongWarsPage> {
  late PongWarsGameModel gameModel;
  Timer? timer;
  int gridSize = 10;
  double gameSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    gameModel = PongWarsGameModel();
    startGameTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startGameTimer() {
    timer?.cancel();
    timer = Timer.periodic(
      Duration(microseconds: (1000000 / (60.0 * gameSpeed)).round()),
      (_) => gameModel.update(),
    );
  }

  void updateGameSpeed() {
    startGameTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF172B36), Color(0xFFD9E8E3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Game canvas - top half of screen
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: GameCanvas(gameModel: gameModel),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Controls section - bottom half
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Score display
                      ListenableBuilder(
                        listenable: gameModel,
                        builder: (context, _) {
                          return Text(
                            'Day: ${gameModel.dayScore}  |  Night: ${gameModel.nightScore}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172B36),
                              fontSize: 24,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // Controls section
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Grid size control
                            Column(
                              children: [
                                Text(
                                  'Grid Size: $gridSize x $gridSize',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF172B36),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Slider(
                                  value: gridSize.toDouble(),
                                  min: 10,
                                  max: 40,
                                  divisions: 30,
                                  activeColor: const Color(0xFF114C5A),
                                  onChanged: (value) {
                                    setState(() {
                                      gridSize = value.round();
                                      gameModel.resetWithGridSize(gridSize);
                                    });
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Speed control
                            Column(
                              children: [
                                Text(
                                  'Game Speed: ${gameSpeed.toStringAsFixed(1)}x',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF172B36),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Slider(
                                  value: gameSpeed,
                                  min: 0.5,
                                  max: 10.0,
                                  activeColor: const Color(0xFF114C5A),
                                  onChanged: (value) {
                                    setState(() {
                                      gameSpeed = value;
                                      updateGameSpeed();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Attribution
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            Text(
                              '@iAhmadAmin | Flutter Version',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF172B36),
                              ),
                            ),
                            Text(
                              'Available on GitHub',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF172B36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameCanvas extends StatelessWidget {
  final PongWarsGameModel gameModel;

  const GameCanvas({super.key, required this.gameModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameModel,
      builder: (context, _) {
        return CustomPaint(painter: GamePainter(gameModel));
      },
    );
  }
}

class GamePainter extends CustomPainter {
  final PongWarsGameModel gameModel;

  GamePainter(this.gameModel);

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / gameModel.numSquaresX;

    // Draw squares
    for (int i = 0; i < gameModel.numSquaresX; i++) {
      for (int j = 0; j < gameModel.numSquaresY; j++) {
        final rect = Rect.fromLTWH(
          i * squareSize,
          j * squareSize,
          squareSize,
          squareSize,
        );

        final color =
            gameModel.squares[i][j] == gameModel.dayColor
                ? _hexToColor(gameModel.dayColor)
                : _hexToColor(gameModel.nightColor);

        final paint = Paint()..color = color;
        canvas.drawRect(rect, paint);
      }
    }

    // Draw balls with better visibility
    for (final ball in gameModel.balls) {
      final ballX = ball.x / gameModel.canvasWidth * size.width;
      final ballY = ball.y / gameModel.canvasHeight * size.height;
      final radius =
          squareSize * 0.4; // Make balls slightly smaller than squares

      // Draw ball shadow/border
      final borderPaint =
          Paint()
            ..color = Colors.black.withAlpha(30)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(ballX + 1, ballY + 1), radius + 1, borderPaint);

      // Draw main ball
      final ballPaint =
          Paint()
            ..color = _hexToColor(ball.ballColor)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(ballX, ballY), radius, ballPaint);

      // Draw ball highlight
      final highlightPaint =
          Paint()
            ..color = Colors.white.withAlpha(30)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(ballX - radius * 0.3, ballY - radius * 0.3),
        radius * 0.3,
        highlightPaint,
      );
    }
  }

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Ball {
  double x;
  double y;
  double dx;
  double dy;
  String reverseColor;
  String ballColor;

  Ball({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.reverseColor,
    required this.ballColor,
  });
}

class PongWarsGameModel extends ChangeNotifier {
  String dayColor = '#D9E8E3';
  String dayBallColor = '#114C5A';
  String nightColor = '#114C5A';
  String nightBallColor = '#D9E8E3';

  int squareSize = 60;
  final double minSpeed = 5;
  final double maxSpeed = 10;
  final int canvasWidth = 600;
  final int canvasHeight = 600;

  int numSquaresX = 10;
  int numSquaresY = 10;

  int dayScore = 0;
  int nightScore = 0;
  List<List<String>> squares = [];
  List<Ball> balls = [];

  PongWarsGameModel() {
    squareSize = canvasWidth ~/ numSquaresX;
    _initializeSquares();
    _initializeBalls();
  }

  void _initializeSquares() {
    squares = List.generate(
      numSquaresX,
      (i) => List.generate(
        numSquaresY,
        (j) => i < numSquaresX / 2 ? dayColor : nightColor,
      ),
    );
  }

  void _initializeBalls() {
    balls = [
      Ball(
        x: canvasWidth / 4,
        y: canvasHeight / 2,
        dx: 8,
        dy: -8,
        reverseColor: dayColor,
        ballColor: dayBallColor,
      ),
      Ball(
        x: canvasWidth * 3 / 4,
        y: canvasHeight / 2,
        dx: -8,
        dy: 8,
        reverseColor: nightColor,
        ballColor: nightBallColor,
      ),
    ];
  }

  void resetWithGridSize(int size) {
    numSquaresX = size;
    numSquaresY = size;
    squareSize = canvasWidth ~/ numSquaresX;
    _initializeSquares();
    _initializeBalls();
    notifyListeners();
  }

  void update() {
    _updateScores();

    for (int i = 0; i < balls.length; i++) {
      _checkSquareCollision(balls[i]);
      _checkBoundaryCollision(balls[i]);

      balls[i].x += balls[i].dx;
      balls[i].y += balls[i].dy;

      _addRandomness(balls[i]);
    }

    notifyListeners();
  }

  void _updateScores() {
    dayScore = 0;
    nightScore = 0;

    for (int i = 0; i < numSquaresX; i++) {
      for (int j = 0; j < numSquaresY; j++) {
        if (squares[i][j] == dayColor) {
          dayScore++;
        } else if (squares[i][j] == nightColor) {
          nightScore++;
        }
      }
    }
  }

  void _checkSquareCollision(Ball ball) {
    for (double angle = 0; angle < 2 * math.pi; angle += math.pi / 4) {
      final checkX = ball.x + math.cos(angle) * (squareSize / 2);
      final checkY = ball.y + math.sin(angle) * (squareSize / 2);

      final i = (checkX / squareSize).floor();
      final j = (checkY / squareSize).floor();

      if (i >= 0 && i < numSquaresX && j >= 0 && j < numSquaresY) {
        if (squares[i][j] != ball.reverseColor) {
          squares[i][j] = ball.reverseColor;

          if (math.cos(angle).abs() > math.sin(angle).abs()) {
            ball.dx = -ball.dx;
          } else {
            ball.dy = -ball.dy;
          }
        }
      }
    }
  }

  void _checkBoundaryCollision(Ball ball) {
    final radius = squareSize / 2;
    if (ball.x + ball.dx > canvasWidth - radius || ball.x + ball.dx < radius) {
      ball.dx = -ball.dx;
    }
    if (ball.y + ball.dy > canvasHeight - radius || ball.y + ball.dy < radius) {
      ball.dy = -ball.dy;
    }
  }

  void _addRandomness(Ball ball) {
    ball.dx += math.Random().nextDouble() * 0.02 - 0.01;
    ball.dy += math.Random().nextDouble() * 0.02 - 0.01;

    ball.dx = math.min(math.max(ball.dx, -maxSpeed), maxSpeed);
    ball.dy = math.min(math.max(ball.dy, -maxSpeed), maxSpeed);

    if (ball.dx.abs() < minSpeed) {
      ball.dx = ball.dx > 0 ? minSpeed : -minSpeed;
    }
    if (ball.dy.abs() < minSpeed) {
      ball.dy = ball.dy > 0 ? minSpeed : -minSpeed;
    }
  }
}
