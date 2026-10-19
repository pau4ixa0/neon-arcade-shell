import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // Фізика руху персонажа
  static const double _gravity = -3.8;
  double _birdY = 0.0;
  double _time = 0.0;
  double _initialPos = 0.0;
  final double _velocity = 2.3;

  // Стан гри
  bool _gameStarted = false;
  bool _gameOver = false;
  int _score = 0;
  int _highScore = 0;
  Timer? _gameLoop;

  // Параметри перешкод (координати X від -1.5 до 1.5)
  static const double _barrierGap = 0.52;
  double _barrierX1 = 1.3;
  double _barrierX2 = 2.1;
  double _barrierHeight1 = 0.35;
  double _barrierHeight2 = 0.25;

  final Random _random = Random();

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _gameOver = false;
      _birdY = 0.0;
      _time = 0.0;
      _initialPos = 0.0;
      _score = 0;
      _barrierX1 = 1.3;
      _barrierX2 = 2.1;
      _barrierHeight1 = 0.2 + _random.nextDouble() * 0.35;
      _barrierHeight2 = 0.2 + _random.nextDouble() * 0.35;
    });

    _gameLoop?.cancel();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      _time += 0.032;
      final double displacement = _gravity * _time * _time + _velocity * _time;

      setState(() {
        _birdY = _initialPos - displacement;

        // Рух неонових труб вліво
        _barrierX1 -= 0.024;
        _barrierX2 -= 0.024;

        // Повернення праворуч та нарахування очок
        if (_barrierX1 < -1.3) {
          _barrierX1 += 2.2;
          _barrierHeight1 = 0.2 + _random.nextDouble() * 0.35;
          _score++;
        }
        if (_barrierX2 < -1.3) {
          _barrierX2 += 2.2;
          _barrierHeight2 = 0.2 + _random.nextDouble() * 0.35;
          _score++;
        }
      });

      if (_checkCollision()) {
        _endGame();
      }
    });
  }

  void _jump() {
    if (!_gameStarted || _gameOver) {
      _startGame();
      return;
    }

    setState(() {
      _time = 0;
      _initialPos = _birdY;
    });
  }

  bool _checkCollision() {
    // Зіткнення з підлогою або стелею
    if (_birdY > 0.95 || _birdY < -1.0) {
      return true;
    }

    // Зіткнення з першою парою труб
    if (_barrierX1 > -0.22 && _barrierX1 < 0.22) {
      final double topLimit = -1.0 + (_barrierHeight1 * 2);
      final double bottomLimit = topLimit + _barrierGap;
      if (_birdY < topLimit || _birdY > bottomLimit) {
        return true;
      }
    }

    // Зіткнення з другою парою труб
    if (_barrierX2 > -0.22 && _barrierX2 < 0.22) {
      final double topLimit = -1.0 + (_barrierHeight2 * 2);
      final double bottomLimit = topLimit + _barrierGap;
      if (_birdY < topLimit || _birdY > bottomLimit) {
        return true;
      }
    }

    return false;
  }

  void _endGame() {
    _gameLoop?.cancel();
    setState(() {
      _gameOver = true;
      _gameStarted = false;
      if (_score > _highScore) {
        _highScore = _score;
      }
    });
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _jump,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: SafeArea(
          child: Column(
            children: [
              // Ігрове поле
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    // Персонаж (неонова сфера з кутом нахилу)
                    AnimatedContainer(
                      alignment: Alignment(0, _birdY),
                      duration: Duration.zero,
                      child: Transform.rotate(
                        angle: _gameStarted ? (_birdY * 0.5).clamp(-0.6, 0.6) : 0,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFF00FFCC), Color(0xFF0066FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FFCC).withValues(alpha: 0.8),
                                blurRadius: 18,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.flash_on, color: Colors.white, size: 22),
                        ),
                      ),
                    ),

                    // Перешкода 1 (Верхня та нижня)
                    AnimatedContainer(
                      alignment: Alignment(_barrierX1, -1.0),
                      duration: Duration.zero,
                      child: _buildBarrier(heightFactor: _barrierHeight1),
                    ),
                    AnimatedContainer(
                      alignment: Alignment(_barrierX1, 1.0),
                      duration: Duration.zero,
                      child: _buildBarrier(heightFactor: 1.0 - (_barrierHeight1 + (_barrierGap / 2))),
                    ),

                    // Перешкода 2 (Верхня та нижня)
                    AnimatedContainer(
                      alignment: Alignment(_barrierX2, -1.0),
                      duration: Duration.zero,
                      child: _buildBarrier(heightFactor: _barrierHeight2),
                    ),
                    AnimatedContainer(
                      alignment: Alignment(_barrierX2, 1.0),
                      duration: Duration.zero,
                      child: _buildBarrier(heightFactor: 1.0 - (_barrierHeight2 + (_barrierGap / 2))),
                    ),

                    // Поточний рахунок під час польоту
                    if (_gameStarted && !_gameOver)
                      Positioned(
                        top: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            '$_score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Color(0xFF00FFCC), blurRadius: 20),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Оверлей Tap to play / Game Over
                    if (!_gameStarted)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181825).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00FFCC), width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 25, offset: Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _gameOver ? Icons.replay_rounded : Icons.sports_esports_rounded,
                                size: 48,
                                color: const Color(0xFF00FFCC),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _gameOver ? 'GAME OVER' : 'NEON FLAPPY ARCADE',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _gameOver ? 'Score: $_score  |  Record: $_highScore' : 'Tap screen to jump & dodge lasers',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00FFCC), Color(0xFF0072FF)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _gameOver ? 'PLAY AGAIN' : 'START GAME',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
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

              // Панель статистики
              Container(
                height: 75,
                color: const Color(0xFF141422),
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SCORE', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
                        Text('$_score', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('BEST RECORD', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
                        Text('$_highScore', style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 26, fontWeight: FontWeight.bold)),
                      ],
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

  Widget _buildBarrier({required double heightFactor}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double height = (constraints.maxHeight * heightFactor).clamp(15.0, constraints.maxHeight);
        return Container(
          width: 54,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB000FF), Color(0xFF4900E6)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD600FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB000FF).withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          ),
        );
      },
    );
  }
}
