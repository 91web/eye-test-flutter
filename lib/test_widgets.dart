// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const EyeTestApp());
}

class EyeTestApp extends StatelessWidget {
  const EyeTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye Test App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const EyeTestHomePage(),
    );
  }
}

bool _dialogShown = false;

class EyeTestHomePage extends StatefulWidget {
  const EyeTestHomePage({super.key});

  @override
  State<EyeTestHomePage> createState() => _EyeTestHomePageState();
}
 
class _EyeTestHomePageState extends State<EyeTestHomePage>
    with TickerProviderStateMixin {
  int _currentTestIndex = 0;
  final List<Map<String, dynamic>> _testResults = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late FlutterTts flutterTts;
  bool _isSpeaking = false;

  final List<Map<String, dynamic>> _tests = [
    {
      'name': 'Visual Acuity Test',
      'description': 'Test your ability to see letters clearly',
      'widget':
          (dynamic Function(Map<String, dynamic>) onComplete) =>
              VisualAcuityTest(onComplete: onComplete),
    },
    {
      'name': 'Questionnaire',
      'description': 'Answer questions about your vision symptoms',
      'widget':
          (dynamic Function(Map<String, dynamic>) onComplete) =>
              QuestionnaireTest(onComplete: onComplete),
    },
    {
      'name': 'Number Recognition',
      'description': 'Solve math problems and recognize numbers',
      'widget':
          (dynamic Function(Map<String, dynamic>) onComplete) =>
              NumberRecognitionTest(onComplete: onComplete),
    },
    {
      'name': 'Color Vision Test',
      'description': 'Identify different colors accurately',
      'widget':
          (dynamic Function(Map<String, dynamic>) onComplete) =>
              ColorVisionTest(onComplete: onComplete),
    },
    {
      'name': 'Object Recognition',
      'description': 'Identify shapes and objects',
      'widget':
          (dynamic Function(Map<String, dynamic>) onComplete) =>
              ObjectRecognitionTest(onComplete: onComplete),
    },
  ];

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    String confirmText = 'Start',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                child: Text(cancelText),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(confirmText),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  Future<void> _showStartDialog() async {
    if (!mounted) return;
    
    // Speak the instructions
    await _speak("Welcome to the Eye Test App. This test will evaluate your vision through several exercises. Make sure you're in a well-lit environment and have your glasses or contacts if needed.");
    
    final shouldStart = await _showConfirmationDialog(
      title: 'Ready for Eye Test?',
      content:
          'This test will evaluate your vision through several exercises.\n\n'
          'Make sure you\'re in a well-lit environment and have your glasses/contacts if needed.\n\n'
          'Do you want to start the test now?',
      confirmText: 'Start Test',
      cancelText: 'Not Now',
    );
    if (shouldStart && mounted) {
      _resetTests();
    }
  }

  Future<void> _showRestartDialog() async {
    final shouldRestart = await _showConfirmationDialog(
      title: 'Restart Tests?',
      content:
          'Are you sure you want to restart the tests? Your previous results will be lost.',
      confirmText: 'Restart',
      cancelText: 'Cancel',
    );
    if (shouldRestart) _resetTests();
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    
    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await flutterTts.stop();
    }
    
    setState(() {
      _isSpeaking = true;
    });
    
    await flutterTts.speak(text);
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _initTts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(Duration.zero, () {
      if (mounted) _showStartDialog();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _onTestComplete(Map<String, dynamic> result) {
    setState(() {
      _testResults.add(result);
      _currentTestIndex++;
    });
    _fadeController.reset();
    _fadeController.forward();
    
    if (_currentTestIndex < _tests.length) {
      _speak("Next test: ${_tests[_currentTestIndex]['name']}. ${_tests[_currentTestIndex]['description']}");
    } else {
      _speak("All tests completed. Here are your results.");
    }
  }

  void _resetTests() {
    setState(() {
      _currentTestIndex = 0;
      _testResults.clear();
    });
    _fadeController.reset();
    _fadeController.forward();
    
    _speak("Starting test: ${_tests[0]['name']}. ${_tests[0]['description']}");
  }

  @override
  Widget build(BuildContext context) {
    if (!_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showStartDialog();
      });
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child:
          _currentTestIndex >= _tests.length
              ? Scaffold(
                appBar: AppBar(
                  title: const Text('Test Results'),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                body: _buildResultsPage(),
              )
              : Scaffold(
                appBar: AppBar(
                  title: Text(_tests[_currentTestIndex]['name']),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                body: _tests[_currentTestIndex]['widget'](_onTestComplete),
              ),
    );
  }

  Widget _buildResultsPage() {
    // Calculate overall score out of 100
    int totalScore = 0;
    int maxPossibleScore = 0;

    for (int i = 0; i < _testResults.length; i++) {
      final result = _testResults[i];

      if (result['testType'] == 'questionnaire') {
        // Questionnaire: negative responses = 2 marks each
        final answers = result['answers'] as List<int>? ?? [];
        for (int answer in answers) {
          if (answer >= 3) {
            // "Often" or "Always" responses
            totalScore += 2;
          }
        }
        maxPossibleScore += answers.length * 2;
      } else {
        // Other tests: each correct answer = 1 mark
        final correctAnswers = result['correctAnswers'] as int? ?? 0;
        final totalQuestions = result['totalQuestions'] as int? ?? 0;
        totalScore += correctAnswers;
        maxPossibleScore += totalQuestions;
      }
    }

    final double overallScore =
        maxPossibleScore > 0 ? (totalScore / maxPossibleScore) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Test Results Summary', style: AppTextStyles.heading1),
          const SizedBox(height: 24),

          // Overall Score Card with animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: overallScore),
            builder: (context, value, child) {
              return Card(
                color: AppColors.primary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Overall Score',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${value.toStringAsFixed(1)}/100',
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.primary,
                          fontSize: 36,
                        ),
                      ),
                      Text(
                        '$totalScore out of $maxPossibleScore points',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tests[index]['name'],
                            style: AppTextStyles.heading3,
                          ),
                          const SizedBox(height: 8),
                          if (result['accuracy'] != null)
                            Text(
                              'Accuracy: ${result['accuracy'].toStringAsFixed(1)}%',
                            ),
                          if (result['avgResponseTime'] != null)
                            Text(
                              'Avg Response Time: ${result['avgResponseTime'].toStringAsFixed(2)}s',
                            ),
                          if (result['correctAnswers'] != null &&
                              result['totalQuestions'] != null)
                            Text(
                              'Score: ${result['correctAnswers']}/${result['totalQuestions']}',
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton(
              onPressed: _showRestartDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Restart Tests',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Constants and Data Classes
class AppColors {
  static const Color primary = Color.fromARGB(255, 76, 82, 68);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color success = Color(0xFF8BC34A);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF00BCD4);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textLight = Color(0xFFFFFFFF);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
}

class AppConstants {
  // Enhanced letter sets for different difficulty levels
  static const List<String> easyLetters = ['E', 'A', 'O', 'H', 'L', 'T'];
  static const List<String> mediumLetters = ['F', 'P', 'R', 'N', 'K', 'D', 'B'];
  static const List<String> hardLetters = [
    'S',
    'Z',
    'Q',
    'G',
    'C',
    'M',
    'W',
    'X',
    'Y',
  ];
  static const List<String> veryHardLetters = ['I', 'J', 'U', 'V'];

  // All letters combined for easier access
  static const List<String> letters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  // Dynamic visual acuity sizes with more distinct differences (smaller = harder)
  static const List<double> visualAcuitySizes = [
    72.0, // Very large
    48.0, // Large
    36.0, // Medium-large
    24.0, // Medium
    18.0, // Medium-small
    12.0, // Small
    8.0,  // Very small
    6.0,  // Tiny
  ];

  // Enhanced color palette for color vision testing
  static const List<Color> testColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
    Colors.brown,
    Colors.grey,
    Color(0xFF8B4513), // SaddleBrown
    Color(0xFF228B22), // ForestGreen
    Color(0xFF4169E1), // RoyalBlue
    Color(0xFFFFD700), // Gold
    Color(0xFF800080), // Purple
    Color(0xFFFFA500), // Orange
    Color(0xFF00CED1), // DarkTurquoise
    Color(0xFF696969), // DimGrey
  ];

  // Object shapes for identification test
  static const List<String> testObjects = [
    'Circle',
    'Square',
    'Triangle',
    'Star',
    'Heart',
    'Diamond',
    'Arrow',
    'Cross',
    'Oval',
    'Rectangle',
  ];
}

class QuestionnaireQuestion {
  final String question;
  final List<String> options;
  final String category;
  final String? description;

  const QuestionnaireQuestion({
    required this.question,
    required this.options,
    required this.category,
    this.description,
  });
}

class QuestionnaireData {
  static List<QuestionnaireQuestion> getAllQuestions() {
    return [
      // Vision Clarity Questions (8)
      QuestionnaireQuestion(
        question: "How often do you experience blurred vision?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "visionClarity",
        description:
            "Blurred vision can indicate refractive errors or other eye conditions.",
      ),
      QuestionnaireQuestion(
        question: "Do you have difficulty reading small text?",
        options: [
          "No difficulty",
          "Slight difficulty",
          "Moderate difficulty",
          "Great difficulty",
          "Cannot read at all",
        ],
        category: "visionClarity",
      ),
      QuestionnaireQuestion(
        question: "How clear is your vision at arm's length?",
        options: [
          "Very clear",
          "Mostly clear",
          "Somewhat unclear",
          "Very unclear",
          "Cannot see clearly",
        ],
        category: "visionClarity",
      ),
      QuestionnaireQuestion(
        question: "Do objects appear distorted or wavy?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "visionClarity",
        description:
            "Distorted vision may indicate macular degeneration or astigmatism.",
      ),
      QuestionnaireQuestion(
        question: "How often do you squint to see clearly?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "visionClarity",
      ),
      QuestionnaireQuestion(
        question: "Do you see double images?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "visionClarity",
        description:
            "Double vision can indicate various eye muscle or neurological issues.",
      ),
      QuestionnaireQuestion(
        question: "How is your peripheral (side) vision?",
        options: ["Excellent", "Good", "Fair", "Poor", "Very poor"],
        category: "visionClarity",
      ),
      QuestionnaireQuestion(
        question: "Do you have trouble focusing between near and far objects?",
        options: [
          "No trouble",
          "Little trouble",
          "Some trouble",
          "Much trouble",
          "Cannot focus",
        ],
        category: "visionClarity",
      ),

      // Eye Discomfort Questions (8)
      QuestionnaireQuestion(
        question: "How often do your eyes feel dry?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "eyeDiscomfort",
        description: "Dry eyes can affect vision quality and comfort.",
      ),
      QuestionnaireQuestion(
        question: "Do you experience eye pain or aching?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "eyeDiscomfort",
      ),
      QuestionnaireQuestion(
        question: "How often do your eyes feel tired or strained?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "eyeDiscomfort",
      ),
      QuestionnaireQuestion(
        question: "Do you experience burning or stinging in your eyes?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "eyeDiscomfort",
      ),
      QuestionnaireQuestion(
        question: "How often do your eyes water excessively?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "eyeDiscomfort",
      ),
      QuestionnaireQuestion(
        question: "Do you feel like there's something in your eye?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "eyeDiscomfort",
      ),
      QuestionnaireQuestion(
        question: "How often do your eyelids feel heavy?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "eyeDiscomfort",
      ),
      QuestionnaireQuestion(
        question: "Do you experience headaches related to eye use?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "eyeDiscomfort",
      ),

      // Light Sensitivity Questions (7)
      QuestionnaireQuestion(
        question: "How sensitive are you to bright lights?",
        options: [
          "Not sensitive",
          "Slightly sensitive",
          "Moderately sensitive",
          "Very sensitive",
          "Extremely sensitive",
        ],
        category: "lightSensitivity",
      ),
      QuestionnaireQuestion(
        question: "Do you have difficulty with glare from sunlight?",
        options: [
          "No difficulty",
          "Little difficulty",
          "Some difficulty",
          "Much difficulty",
          "Cannot tolerate",
        ],
        category: "lightSensitivity",
      ),
      QuestionnaireQuestion(
        question: "How do you react to oncoming headlights while driving?",
        options: [
          "No problem",
          "Slight discomfort",
          "Moderate discomfort",
          "Severe discomfort",
          "Cannot drive at night",
        ],
        category: "lightSensitivity",
      ),
      QuestionnaireQuestion(
        question: "Do fluorescent lights bother your eyes?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "lightSensitivity",
      ),
      QuestionnaireQuestion(
        question: "How often do you need sunglasses outdoors?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "lightSensitivity",
      ),
      QuestionnaireQuestion(
        question: "Do you see halos around lights?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "lightSensitivity",
        description: "Halos around lights may indicate cataracts or glaucoma.",
      ),
      QuestionnaireQuestion(
        question: "How is your vision in bright environments?",
        options: ["Excellent", "Good", "Fair", "Poor", "Very poor"],
        category: "lightSensitivity",
      ),

      // Night Vision Questions (7)
      QuestionnaireQuestion(
        question: "How well can you see in dim light?",
        options: ["Very well", "Well", "Adequately", "Poorly", "Very poorly"],
        category: "nightVision",
      ),
      QuestionnaireQuestion(
        question: "Do you have trouble driving at night?",
        options: [
          "No trouble",
          "Little trouble",
          "Some trouble",
          "Much trouble",
          "Cannot drive at night",
        ],
        category: "nightVision",
      ),
      QuestionnaireQuestion(
        question: "How long does it take your eyes to adjust to darkness?",
        options: [
          "Very quickly",
          "Quickly",
          "Normal time",
          "Slowly",
          "Very slowly or not at all",
        ],
        category: "nightVision",
      ),
      QuestionnaireQuestion(
        question: "Do you bump into things in dim lighting?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "nightVision",
      ),
      QuestionnaireQuestion(
        question: "Can you distinguish colors in low light?",
        options: [
          "Easily",
          "Mostly",
          "Somewhat",
          "Difficultly",
          "Cannot distinguish",
        ],
        category: "nightVision",
      ),
      QuestionnaireQuestion(
        question: "How is your vision when moving from bright to dark spaces?",
        options: [
          "Adjusts quickly",
          "Adjusts normally",
          "Adjusts slowly",
          "Adjusts very slowly",
          "Cannot adjust",
        ],
        category: "nightVision",
      ),
      QuestionnaireQuestion(
        question:
            "Do you avoid activities in low light because of vision problems?",
        options: ["Never", "Rarely", "Sometimes", "Often", "Always"],
        category: "nightVision",
      ),
    ];
  }

  static List<QuestionnaireQuestion> getRandomQuestions({int count = 20}) {
    final allQuestions = getAllQuestions();
    final random = Random();
    final selectedQuestions = <QuestionnaireQuestion>[];
    final usedIndices = <int>{};

    while (selectedQuestions.length < count &&
        usedIndices.length < allQuestions.length) {
      final index = random.nextInt(allQuestions.length);
      if (!usedIndices.contains(index)) {
        usedIndices.add(index);
        selectedQuestions.add(allQuestions[index]);
      }
    }

    return selectedQuestions;
  }
}

// Letter Data Class for Visual Acuity Test
class LetterData {
  final String letter;
  final double size;
  final Color color;

  LetterData({required this.letter, required this.size, required this.color});
}

// Enhanced Visual Acuity Test - 5 letters with different sizes and colors
class VisualAcuityTest extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const VisualAcuityTest({super.key, required this.onComplete});

  @override
  State<VisualAcuityTest> createState() => _VisualAcuityTestState();
}

class _VisualAcuityTestState extends State<VisualAcuityTest>
    with TickerProviderStateMixin {
  int _currentQuestion = 0;
  int _correctAnswers = 0;
  final List<double> _responseTimes = [];
  late Stopwatch _stopwatch;
  Timer? _testTimer;
  int _timeRemaining = 120;
  final Random _random = Random();
  late FlutterTts flutterTts;

  List<LetterData> _currentLetters = [];
  String _questionText = '';
  List<String> _options = [];
  String _correctAnswer = '';
  final int _totalQuestions = 20;

  // Question types: 0=biggest, 1=smallest, 2=red letter, 3=black letter, 4=identify letter
  late List<int> _questionTypes;

  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _initTts();
    _generateQuestionTypes();
    _generateQuestion();
    _startTestTimer();
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _generateQuestionTypes() {
    _questionTypes = List.generate(
      _totalQuestions,
      (index) => _random.nextInt(5),
    );
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _testTimer?.cancel();
    _scaleController.dispose();
    _slideController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _startTestTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });
      if (_timeRemaining <= 0) {
        _completeTest();
      }
    });
  }

  void _generateQuestion() {
    if (_currentQuestion >= _totalQuestions) {
      _completeTest();
      return;
    }

    // Generate 5 random letters with DISTINCTLY different sizes and colors
    _currentLetters = [];
    final usedLetters = <String>{};
    final usedSizes = <double>{};
    final List<Color> availableColors = [
      Colors.red,
      Colors.black,
      Colors.blue,
      Colors.green,
      Colors.purple,
    ];

    // Ensure we have a good range of sizes
    List<double> sizesToUse = [
      AppConstants.visualAcuitySizes[0], // Very large
      AppConstants.visualAcuitySizes[2], // Medium-large
      AppConstants.visualAcuitySizes[4], // Medium-small
      AppConstants.visualAcuitySizes[5], // Small
      AppConstants.visualAcuitySizes[7], // Tiny
    ];
    
    // Shuffle sizes to randomize which letter gets which size
    sizesToUse.shuffle(_random);

    for (int i = 0; i < 5; i++) {
      String letter;
      do {
        letter =
            AppConstants.letters[_random.nextInt(AppConstants.letters.length)];
      } while (usedLetters.contains(letter));
      usedLetters.add(letter);

      // Use distinctly different sizes
      double size = sizesToUse[i];
      usedSizes.add(size);

      // Ensure we have at least one red and one black letter for those question types
      Color color;
      if (i == 0) {
        color = Colors.red;
      } else if (i == 1) {
        color = Colors.black;
      } else {
        color = availableColors[_random.nextInt(availableColors.length)];
      }

      _currentLetters.add(
        LetterData(
          letter: letter,
          size: size,
          color: color,
        ),
      );
    }

    // Sort by size for easier reference
    _currentLetters.sort((a, b) => a.size.compareTo(b.size));

    final questionType = _questionTypes[_currentQuestion];
    _generateQuestionByType(questionType);

    _stopwatch.reset();
    _stopwatch.start();

    // Start animations
    _scaleController.reset();
    _slideController.reset();
    _scaleController.forward();
    _slideController.forward();
    
    // Speak the question
    _speak(_questionText);
  }

  void _generateQuestionByType(int type) {
    switch (type) {
      case 0: // Biggest letter
        _questionText = 'Which is the BIGGEST letter?';
        _correctAnswer = _currentLetters.last.letter;
        break;
      case 1: // Smallest letter
        _questionText = 'Which is the SMALLEST letter?';
        _correctAnswer = _currentLetters.first.letter;
        break;
      case 2: // Red letter
        final redLetters =
            _currentLetters.where((l) => l.color == Colors.red).toList();
        if (redLetters.isNotEmpty) {
          _questionText = 'Which letter is RED?';
          _correctAnswer = redLetters.first.letter;
        } else {
          _questionText = 'Which is the BIGGEST letter?';
          _correctAnswer = _currentLetters.last.letter;
        }
        break;
      case 3: // Black letter
        final blackLetters =
            _currentLetters.where((l) => l.color == Colors.black).toList();
        if (blackLetters.isNotEmpty) {
          _questionText = 'Which letter is BLACK?';
          _correctAnswer = blackLetters.first.letter;
        } else {
          _questionText = 'Which is the SMALLEST letter?';
          _correctAnswer = _currentLetters.first.letter;
        }
        break;
      case 4: // Identify specific letter
        final targetLetter =
            _currentLetters[_random.nextInt(_currentLetters.length)];
        _questionText = 'Find the letter: ${targetLetter.letter}';
        _correctAnswer = targetLetter.letter;
        break;
    }

    // FIXED: Generate options ensuring correct answer is ALWAYS included
    _options = [_correctAnswer]; // Start with correct answer

    // Get all available letters from current display
    final availableLetters = _currentLetters.map((l) => l.letter).toList();

    // Add other letters from current display as wrong options
    for (String letter in availableLetters) {
      if (letter != _correctAnswer && _options.length < 4) {
        _options.add(letter);
      }
    }

    // If we need more options, add random letters
    while (_options.length < 4) {
      final randomLetter =
          AppConstants.letters[_random.nextInt(AppConstants.letters.length)];
      if (!_options.contains(randomLetter)) {
        _options.add(randomLetter);
      }
    }

    _options.shuffle(_random); // Shuffle to randomize position
  }

  void _handleAnswer(String selectedAnswer) {
    _stopwatch.stop();
    final responseTime = _stopwatch.elapsedMilliseconds / 1000;
    _responseTimes.add(responseTime);

    if (selectedAnswer == _correctAnswer) {
      _correctAnswers++;
      _speak("Correct");
    } else {
      _speak("Incorrect");
    }

    setState(() {
      _currentQuestion++;
      if (_currentQuestion < _totalQuestions && _timeRemaining > 0) {
        _generateQuestion();
      } else {
        _completeTest();
      }
    });
  }

  void _completeTest() {
    _testTimer?.cancel();
    final double accuracy =
        _totalQuestions > 0 ? (_correctAnswers / _totalQuestions) * 100 : 0;
    final double avgResponseTime =
        _responseTimes.isNotEmpty
            ? _responseTimes.reduce((a, b) => a + b) / _responseTimes.length
            : 0;

    _speak("Visual acuity test complete");
    
    widget.onComplete({
      'accuracy': accuracy,
      'correctAnswers': _correctAnswers,
      'totalQuestions': _totalQuestions,
      'responseTimes': _responseTimes,
      'avgResponseTime': avgResponseTime,
      'testType': 'visual_acuity',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          SlideTransition(
            position: _slideAnimation,
            child: _buildQuestionText(),
          ),
          const SizedBox(height: 24),
          ScaleTransition(
            scale: _scaleAnimation,
            child: _buildLettersDisplay(),
          ),
          const SizedBox(height: 24),
          _buildOptions(),
          const SizedBox(height: 24),
          _buildProgress(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('👁️ Visual Acuity Test', style: AppTextStyles.heading3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeRemaining <= 20 ? AppColors.error : AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⏰ ${(_timeRemaining ~/ 60)}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionText() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _questionText,
        style: AppTextStyles.heading3.copyWith(fontSize: 22),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLettersDisplay() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            _currentLetters.asMap().entries.map((entry) {
              final index = entry.key;
              final letterData = entry.value;
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Text(
                      letterData.letter,
                      style: TextStyle(
                        fontSize: letterData.size,
                        color: letterData.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }

  Widget _buildOptions() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: _options.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: () => _handleAnswer(_options[index]),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    _options[index],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Text(
          'Question ${_currentQuestion + 1} of $_totalQuestions',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(
            begin: 0.0,
            end: (_currentQuestion + 1) / _totalQuestions,
          ),
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 8,
            );
          },
        ),
      ],
    );
  }
}

// Enhanced Number Recognition Test - Visual comparison only
class NumberRecognitionTest extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const NumberRecognitionTest({super.key, required this.onComplete});

  @override
  State<NumberRecognitionTest> createState() => _NumberRecognitionTestState();
}

class _NumberRecognitionTestState extends State<NumberRecognitionTest>
    with TickerProviderStateMixin {
  int _currentQuestion = 0;
  int _correctAnswers = 0;
  final List<double> _responseTimes = [];
  late Stopwatch _stopwatch;
  Timer? _testTimer;
  int _timeRemaining = 90;
  final Random _random = Random();
  late FlutterTts flutterTts;

  String _questionText = '';
  List<String> _options = [];
  String _correctAnswer = '';
  List<int> _displayNumbers = [];
  final int _totalQuestions = 15;

  // Question types: 0=biggest, 1=smallest, 2=ascending, 3=descending, 4=missing
  late List<int> _questionTypes;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    _initTts();
    _generateQuestionTypes();
    _generateQuestion();
    _startTestTimer();
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _generateQuestionTypes() {
    _questionTypes = List.generate(
      _totalQuestions,
      (index) => _random.nextInt(5),
    );
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _testTimer?.cancel();
    _bounceController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _startTestTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });
      if (_timeRemaining <= 0) {
        _completeTest();
      }
    });
  }

  void _generateQuestion() {
    if (_currentQuestion >= _totalQuestions) {
      _completeTest();
      return;
    }

    final questionType = _questionTypes[_currentQuestion];
    _generateQuestionByType(questionType);

    _stopwatch.reset();
    _stopwatch.start();

    _bounceController.reset();
    _bounceController.forward();
    
    // Speak the question
    _speak(_questionText);
  }

  void _generateQuestionByType(int type) {
    switch (type) {
      case 0: // Biggest number
        _displayNumbers = List.generate(5, (index) => _random.nextInt(99) + 1);
        _questionText = 'Which is the BIGGEST number?';
        _correctAnswer = _displayNumbers.reduce(max).toString();
        break;
      case 1: // Smallest number
        _displayNumbers = List.generate(5, (index) => _random.nextInt(99) + 1);
        _questionText = 'Which is the SMALLEST number?';
        _correctAnswer = _displayNumbers.reduce(min).toString();
        break;
      case 2: // Ascending sequence
        final start = _random.nextInt(10) + 1;
        _displayNumbers = [start, start + 2, start + 4, start + 6];
        _questionText = 'Complete the sequence (going UP):';
        _correctAnswer = (start + 8).toString();
        break;
      case 3: // Descending sequence
        final start = _random.nextInt(20) + 20;
        _displayNumbers = [start, start - 3, start - 6, start - 9];
        _questionText = 'Complete the sequence (going DOWN):';
        _correctAnswer = (start - 12).toString();
        break;
      case 4: // Missing number
        final start = _random.nextInt(10) + 1;
        final missing = _random.nextInt(3) + 1;
        _displayNumbers = [start, start + 1, start + 2, start + 3, start + 4];
        _displayNumbers.removeAt(missing);
        _questionText = 'Which number is MISSING?';
        _correctAnswer = (start + missing).toString();
        break;
    }

    // FIXED: Generate options ensuring correct answer is ALWAYS included
    _options = [_correctAnswer]; // Start with correct answer

    if (type <= 1) {
      // For biggest/smallest, add other numbers from display
      for (int number in _displayNumbers) {
        if (number.toString() != _correctAnswer && _options.length < 4) {
          _options.add(number.toString());
        }
      }
    }

    // Fill remaining slots with nearby numbers
    while (_options.length < 4) {
      final correctInt = int.parse(_correctAnswer);
      final variation = _random.nextInt(10) - 5; // -5 to +5
      final option = (correctInt + variation).toString();
      if (!_options.contains(option) &&
          int.tryParse(option) != null &&
          int.parse(option) > 0) {
        _options.add(option);
      }
    }

    _options.shuffle(_random); // Shuffle to randomize position
  }

  void _handleAnswer(String selectedAnswer) {
    _stopwatch.stop();
    final responseTime = _stopwatch.elapsedMilliseconds / 1000;
    _responseTimes.add(responseTime);

    if (selectedAnswer == _correctAnswer) {
      _correctAnswers++;
      _speak("Correct");
    } else {
      _speak("Incorrect");
    }

    setState(() {
      _currentQuestion++;
      if (_currentQuestion < _totalQuestions && _timeRemaining > 0) {
        _generateQuestion();
      } else {
        _completeTest();
      }
    });
  }

  void _completeTest() {
    _testTimer?.cancel();
    final double accuracy =
        _totalQuestions > 0 ? (_correctAnswers / _totalQuestions) * 100 : 0;
    final double avgResponseTime =
        _responseTimes.isNotEmpty
            ? _responseTimes.reduce((a, b) => a + b) / _responseTimes.length
            : 0;

    _speak("Number recognition test complete");
    
    widget.onComplete({
      'accuracy': accuracy,
      'correctAnswers': _correctAnswers,
      'totalQuestions': _totalQuestions,
      'responseTimes': _responseTimes,
      'avgResponseTime': avgResponseTime,
      'testType': 'number_recognition',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildQuestionCard(),
          const SizedBox(height: 24),
          ScaleTransition(
            scale: _bounceAnimation,
            child: _buildNumbersDisplay(),
          ),
          const SizedBox(height: 24),
          _buildOptions(),
          const SizedBox(height: 24),
          _buildProgress(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('🔢 Number Recognition', style: AppTextStyles.heading3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeRemaining <= 15 ? AppColors.error : AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⏰ ${(_timeRemaining ~/ 60)}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _questionText,
        style: AppTextStyles.heading3.copyWith(fontSize: 20),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNumbersDisplay() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            _displayNumbers.asMap().entries.map((entry) {
              final index = entry.key;
              final number = entry.value;
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 150)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        number.toString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }

  Widget _buildOptions() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: _options.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: ElevatedButton(
                onPressed: () => _handleAnswer(_options[index]),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  _options[index],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Text(
          'Question ${_currentQuestion + 1} of $_totalQuestions',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(
            begin: 0.0,
            end: (_currentQuestion + 1) / _totalQuestions,
          ),
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 8,
            );
          },
        ),
      ],
    );
  }
}

// Enhanced Color Vision Test - Similar color matching
class ColorVisionTest extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const ColorVisionTest({super.key, required this.onComplete});

  @override
  State<ColorVisionTest> createState() => _ColorVisionTestState();
}

class _ColorVisionTestState extends State<ColorVisionTest>
    with TickerProviderStateMixin {
  int _currentTest = 0;
  int _correctAnswers = 0;
  final List<double> _responseTimes = [];
  late Stopwatch _stopwatch;
  Timer? _testTimer;
  int _timeRemaining = 75;
  final Random _random = Random();
  late FlutterTts flutterTts;

  Color _baseColor = Colors.red;
  List<Color> _colorOptions = [];
  Color _correctColor = Colors.red;
  final int _totalTests = 12;

  late AnimationController _colorController;
  late Animation<double> _colorAnimation;

  // Enhanced similar color mappings with more precise variations
  final Map<Color, List<Color>> _similarColors = {
    Colors.red: [
      Color(0xFFFF6B6B), // Light red
      Color(0xFFFF4757), // Medium red
      Color(0xFFFF3838), // Bright red
    ],
    Colors.green: [
      Color(0xFF6BCF7F), // Light green
      Color(0xFF4CD137), // Medium green
      Color(0xFF00D2D3), // Teal green
    ],
    Colors.blue: [
      Color(0xFF74B9FF), // Light blue
      Color(0xFF0984E3), // Medium blue
      Color(0xFF6C5CE7), // Indigo blue
    ],
    Colors.yellow: [
      Color(0xFFFDCB6E), // Light yellow
      Color(0xFFFFDA79), // Medium yellow
      Color(0xFFFFE066), // Bright yellow
    ],
    Colors.orange: [
      Color(0xFFE17055), // Light orange
      Color(0xFFFF9F43), // Medium orange
      Color(0xFFFF6348), // Bright orange
    ],
    Colors.purple: [
      Color(0xFFA29BFE), // Light purple
      Color(0xFF6C5CE7), // Medium purple
      Color(0xFF5F27CD), // Deep purple
    ],
  };

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    _initTts();
    _generateColorTest();
    _startTestTimer();
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _testTimer?.cancel();
    _colorController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _startTestTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });
      if (_timeRemaining <= 0) {
        _completeTest();
      }
    });
  }

  void _generateColorTest() {
    if (_currentTest >= _totalTests) {
      _completeTest();
      return;
    }

    final baseColors = _similarColors.keys.toList();
    _baseColor = baseColors[_random.nextInt(baseColors.length)];

    final similarColors = _similarColors[_baseColor]!;
    _correctColor = similarColors[_random.nextInt(similarColors.length)];

    // Start with correct color
    _colorOptions = [_correctColor];

    // Get all base colors except current one
    final otherBaseColors = List<Color>.from(baseColors)..remove(_baseColor);

    // Add 3 distinctly different wrong colors
    while (_colorOptions.length < 4) {
      final wrongBaseColor =
          otherBaseColors[_random.nextInt(otherBaseColors.length)];
      final wrongSimilarColors = _similarColors[wrongBaseColor]!;
      final wrongColor =
          wrongSimilarColors[_random.nextInt(wrongSimilarColors.length)];

      // Ensure color isn't already in options and is distinctly different
      if (!_colorOptions.contains(wrongColor) && !_colorsAreSimilar(wrongColor, _correctColor)) {
        _colorOptions.add(wrongColor);
      }

      // Fallback if stuck in loop
      if (_colorOptions.length < 4 && _colorOptions.length > 1) {
        final fallbackColor = _generateFallbackColor();
        if (!_colorOptions.contains(fallbackColor) && !_colorsAreSimilar(fallbackColor, _correctColor)) {
          _colorOptions.add(fallbackColor);
        }
      }
    }

    // Ensure exactly 4 options
    _colorOptions = _colorOptions.take(4).toList();
    _colorOptions.shuffle(_random);

    _stopwatch.reset();
    _stopwatch.start();
    _colorController.reset();
    _colorController.forward();
    
    // Speak the instruction
    _speak("Tap the color that looks most similar to the color shown above");
  }

  Color _generateFallbackColor() {
    final allColors = _similarColors.values.expand((colors) => colors).toList();
    return allColors[_random.nextInt(allColors.length)];
  }

  bool _colorsAreSimilar(Color c1, Color c2) {
    return (c1.red - c2.red).abs() < 80 &&
        (c1.green - c2.green).abs() < 80 &&
        (c1.blue - c2.blue).abs() < 80;
  }

  void _handleAnswer(Color selectedColor) {
    _stopwatch.stop();
    final responseTime = _stopwatch.elapsedMilliseconds / 1000;
    _responseTimes.add(responseTime);

    if (selectedColor == _correctColor) {
      _correctAnswers++;
      _speak("Correct");
    } else {
      _speak("Incorrect");
    }

    setState(() {
      _currentTest++;
      if (_currentTest < _totalTests && _timeRemaining > 0) {
        _generateColorTest();
      } else {
        _completeTest();
      }
    });
  }

  void _completeTest() {
    _testTimer?.cancel();
    final double accuracy =
        _totalTests > 0 ? (_correctAnswers / _totalTests) * 100 : 0;
    final double avgResponseTime =
        _responseTimes.isNotEmpty
            ? _responseTimes.reduce((a, b) => a + b) / _responseTimes.length
            : 0;

    _speak("Color vision test complete");
    
    widget.onComplete({
      'accuracy': accuracy,
      'correctAnswers': _correctAnswers,
      'totalQuestions': _totalTests,
      'responseTimes': _responseTimes,
      'avgResponseTime': avgResponseTime,
      'testType': 'color_vision',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildInstructions(),
          const SizedBox(height: 24),
          ScaleTransition(
            scale: _colorAnimation,
            child: _buildBaseColorDisplay(),
          ),
          const SizedBox(height: 24),
          _buildColorOptions(),
          const SizedBox(height: 24),
          _buildProgress(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('🎨 Color Vision Test', style: AppTextStyles.heading3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeRemaining <= 15 ? AppColors.error : AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⏰ ${(_timeRemaining ~/ 60)}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        '👆 Tap the color that looks MOST SIMILAR to the color shown above',
        style: AppTextStyles.bodyLarge,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBaseColorDisplay() {
    return Column(
      children: [
        const Text('👀 Look at this color:', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: _baseColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorOptions() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.0,
      ),
      itemCount: _colorOptions.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 150)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: GestureDetector(
                onTap: () => _handleAnswer(_colorOptions[index]),
                child: Container(
                  decoration: BoxDecoration(
                    color: _colorOptions[index],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Text(
          'Test ${_currentTest + 1} of $_totalTests',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: (_currentTest + 1) / _totalTests),
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 8,
            );
          },
        ),
      ],
    );
  }
}

// Enhanced Object Recognition Test - Position and similarity based
class ObjectRecognitionTest extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const ObjectRecognitionTest({super.key, required this.onComplete});

  @override
  State<ObjectRecognitionTest> createState() => _ObjectRecognitionTestState();
}

class _ObjectRecognitionTestState extends State<ObjectRecognitionTest>
    with TickerProviderStateMixin {
  int _currentTest = 0;
  int _correctAnswers = 0;
  final List<double> _responseTimes = [];
  late Stopwatch _stopwatch;
  Timer? _testTimer;
  int _timeRemaining = 60;
  final Random _random = Random();
  late FlutterTts flutterTts;

  List<String> _displayObjects = [];
  String _questionText = '';
  List<String> _options = [];
  String _correctAnswer = '';
  final int _totalTests = 10;

  // Question types: 0=left, 1=middle, 2=right, 3=matching
  late List<int> _questionTypes;

  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;

  // Similar object mappings
  final Map<String, List<String>> _similarObjects = {
    'Circle': ['Circle', 'Oval'],
    'Square': ['Square', 'Rectangle'],
    'Triangle': ['Triangle', 'Arrow'],
    'Star': ['Star', 'Diamond'],
    'Heart': ['Heart', 'Diamond'],
  };

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    _initTts();
    _generateQuestionTypes();
    _generateObjectTest();
    _startTestTimer();
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _generateQuestionTypes() {
    _questionTypes = List.generate(_totalTests, (index) => _random.nextInt(4));
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _testTimer?.cancel();
    _rotateController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _startTestTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });
      if (_timeRemaining <= 0) {
        _completeTest();
      }
    });
  }

  void _generateObjectTest() {
    if (_currentTest >= _totalTests) {
      _completeTest();
      return;
    }

    final questionType = _questionTypes[_currentTest];
    _generateQuestionByType(questionType);

    _stopwatch.reset();
    _stopwatch.start();

    _rotateController.reset();
    _rotateController.forward();
    
    // Speak the question
    _speak(_questionText);
  }

  void _generateQuestionByType(int type) {
    switch (type) {
      case 0: // Left object
        _displayObjects = _generateRandomObjects(3);
        _questionText = 'Which object is on the LEFT? ⬅️';
        _correctAnswer = _displayObjects[0];
        break;
      case 1: // Middle object
        _displayObjects = _generateRandomObjects(3);
        _questionText = 'Which object is in the MIDDLE? ⬆️';
        _correctAnswer = _displayObjects[1];
        break;
      case 2: // Right object
        _displayObjects = _generateRandomObjects(3);
        _questionText = 'Which object is on the RIGHT? ➡️';
        _correctAnswer = _displayObjects[2];
        break;
      case 3: // Matching objects
        final baseObject =
            AppConstants.testObjects[_random.nextInt(
              AppConstants.testObjects.length,
            )];
        final similarObjects = _similarObjects[baseObject] ?? [baseObject];
        final matchingObject =
            similarObjects[_random.nextInt(similarObjects.length)];

        _displayObjects = [baseObject];
        _questionText = 'Which object is SIMILAR to this one? 🔍';
        _correctAnswer = matchingObject;
        break;
    }

    // FIXED: Generate options ensuring correct answer is ALWAYS included
    _options = [_correctAnswer]; // Start with correct answer

    if (type <= 2) {
      // For position questions, add other objects from display
      for (String obj in _displayObjects) {
        if (obj != _correctAnswer && _options.length < 4) {
          _options.add(obj);
        }
      }
    }

    // Fill remaining slots with random objects
    while (_options.length < 4) {
      final randomObject =
          AppConstants.testObjects[_random.nextInt(
            AppConstants.testObjects.length,
          )];
      if (!_options.contains(randomObject)) {
        _options.add(randomObject);
      }
    }

    _options.shuffle(_random); // Shuffle to randomize position
  }

  List<String> _generateRandomObjects(int count) {
    final objects = <String>[];
    final usedObjects = <String>{};

    while (objects.length < count) {
      final obj =
          AppConstants.testObjects[_random.nextInt(
            AppConstants.testObjects.length,
          )];
      if (!usedObjects.contains(obj)) {
        objects.add(obj);
        usedObjects.add(obj);
      }
    }
    return objects;
  }

  void _handleAnswer(String selectedObject) {
    _stopwatch.stop();
    final responseTime = _stopwatch.elapsedMilliseconds / 1000;
    _responseTimes.add(responseTime);

    if (selectedObject == _correctAnswer) {
      _correctAnswers++;
      _speak("Correct");
    } else {
      _speak("Incorrect");
    }

    setState(() {
      _currentTest++;
      if (_currentTest < _totalTests && _timeRemaining > 0) {
        _generateObjectTest();
      } else {
        _completeTest();
      }
    });
  }

  void _completeTest() {
    _testTimer?.cancel();
    final double accuracy =
        _totalTests > 0 ? (_correctAnswers / _totalTests) * 100 : 0;
    final double avgResponseTime =
        _responseTimes.isNotEmpty
            ? _responseTimes.reduce((a, b) => a + b) / _responseTimes.length
            : 0;

    _speak("Object recognition test complete");
    
    widget.onComplete({
      'accuracy': accuracy,
      'correctAnswers': _correctAnswers,
      'totalQuestions': _totalTests,
      'responseTimes': _responseTimes,
      'avgResponseTime': avgResponseTime,
      'testType': 'object_recognition',
    });
  }

  Widget _buildObjectShape(String objectName) {
    switch (objectName.toLowerCase()) {
      case 'circle':
        return Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        );
      case 'square':
        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case 'triangle':
        return CustomPaint(
          size: const Size(70, 70),
          painter: TrianglePainter(),
        );
      case 'star':
        return CustomPaint(size: const Size(70, 70), painter: StarPainter());
      case 'heart':
        return CustomPaint(size: const Size(70, 70), painter: HeartPainter());
      case 'diamond':
        return CustomPaint(size: const Size(70, 70), painter: DiamondPainter());
      case 'arrow':
        return CustomPaint(size: const Size(70, 70), painter: ArrowPainter());
      case 'cross':
        return CustomPaint(size: const Size(70, 70), painter: CrossPainter());
      case 'oval':
        return Container(
          width: 70,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(35),
          ),
        );
      case 'rectangle':
        return Container(
          width: 80,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      default:
        return Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildQuestionCard(),
          const SizedBox(height: 24),
          RotationTransition(
            turns: _rotateAnimation,
            child: _buildObjectsDisplay(),
          ),
          const SizedBox(height: 24),
          _buildOptions(),
          const SizedBox(height: 24),
          _buildProgress(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('🔺 Object Recognition', style: AppTextStyles.heading3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeRemaining <= 10 ? AppColors.error : AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⏰ ${_timeRemaining}s',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _questionText,
        style: AppTextStyles.heading3.copyWith(fontSize: 20),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildObjectsDisplay() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            _displayObjects.asMap().entries.map((entry) {
              final index = entry.key;
              final obj = entry.value;
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 200)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildObjectShape(obj),
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }

  Widget _buildOptions() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: _options.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: ElevatedButton(
                onPressed: () => _handleAnswer(_options[index]),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  _options[index],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Text(
          'Test ${_currentTest + 1} of $_totalTests',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: (_currentTest + 1) / _totalTests),
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 8,
            );
          },
        ),
      ],
    );
  }
}

// Enhanced Questionnaire Test
class QuestionnaireTest extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const QuestionnaireTest({super.key, required this.onComplete});

  @override
  State<QuestionnaireTest> createState() => _QuestionnaireTestState();
}

class _QuestionnaireTestState extends State<QuestionnaireTest>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  final List<int> _answers = [];
  late List<QuestionnaireQuestion> _questions;
  late Stopwatch _stopwatch;
  final List<double> _responseTimes = [];
  Timer? _testTimer;
  int _timeRemaining = 300; // 5 minutes for 20 questions
  late FlutterTts flutterTts;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _questions = QuestionnaireData.getRandomQuestions(count: 20);
    _stopwatch = Stopwatch();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _initTts();
    _startQuestion();
    _startTestTimer();
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _testTimer?.cancel();
    _slideController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _startTestTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        _completeTest();
      }
    });
  }

  void _startQuestion() {
    _stopwatch.reset();
    _stopwatch.start();
    _slideController.reset();
    _slideController.forward();
    
    // Speak the question
    if (_currentQuestionIndex < _questions.length) {
      _speak(_questions[_currentQuestionIndex].question);
    }
  }

  void _handleAnswer(int answerIndex) {
    _stopwatch.stop();
    final responseTime = _stopwatch.elapsedMilliseconds / 1000;
    _responseTimes.add(responseTime);
    _answers.add(answerIndex);

    setState(() {
      _currentQuestionIndex++;
      if (_currentQuestionIndex < _questions.length) {
        _startQuestion();
      } else {
        _completeTest();
      }
    });
  }

  void _completeTest() {
    _testTimer?.cancel();

    final Map<String, int> symptomScores = {
      'visionClarity': 0,
      'eyeDiscomfort': 0,
      'lightSensitivity': 0,
      'nightVision': 0,
    };

    for (int i = 0; i < _answers.length && i < _questions.length; i++) {
      final question = _questions[i];
      final answer = _answers[i];
      symptomScores[question.category] =
          (symptomScores[question.category] ?? 0) + answer;
    }

    final double avgResponseTime =
        _responseTimes.isNotEmpty
            ? _responseTimes.reduce((a, b) => a + b) / _responseTimes.length
            : 0;

    final int maxPossibleScore =
        _questions.length * 4; // 4 is max score per question
    final int totalScore = symptomScores.values.reduce((a, b) => a + b);
    final double normalizedScore = (totalScore / maxPossibleScore) * 100;

    _speak("Questionnaire complete");
    
    final Map<String, dynamic> results = {
      'totalScore': normalizedScore,
      'symptomScores': symptomScores,
      'answers': _answers,
      'responseTimes': _responseTimes,
      'avgResponseTime': avgResponseTime,
      'testType': 'questionnaire',
    };

    widget.onComplete(results);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestionIndex >= _questions.length) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final question = _questions[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          SlideTransition(
            position: _slideAnimation,
            child: _buildQuestionCard(question),
          ),
          const SizedBox(height: 16),
          _buildOptions(question),
          const SizedBox(height: 16),
          _buildProgress(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('📋 Health Questions', style: AppTextStyles.heading3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeRemaining <= 30 ? AppColors.error : AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⏰ ${(_timeRemaining ~/ 60)}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionnaireQuestion question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: AppTextStyles.heading3.copyWith(fontSize: 20),
          ),
          if (question.description != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 ${question.description!}',
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions(QuestionnaireQuestion question) {
    return Column(
      children: List.generate(question.options.length, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => _handleAnswer(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border, width: 2),
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          question.options[index],
                          style: AppTextStyles.bodyLarge.copyWith(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Text(
          'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(
            begin: 0.0,
            end: (_currentQuestionIndex + 1) / _questions.length,
          ),
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 8,
            );
          },
        ),
      ],
    );
  }
}

// Custom Painters for different shapes
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;

    for (int i = 0; i < 10; i++) {
      final angle = (i * pi) / 5;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = centerX + radius * cos(angle - pi / 2);
      final y = centerY + radius * sin(angle - pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width / 2, height * 0.25);
    path.cubicTo(
      width / 2,
      height * 0.1,
      width * 0.1,
      height * 0.1,
      width * 0.1,
      height * 0.4,
    );
    path.cubicTo(
      width * 0.1,
      height * 0.55,
      width / 2,
      height * 0.8,
      width / 2,
      height,
    );
    path.cubicTo(
      width / 2,
      height * 0.8,
      width * 0.9,
      height * 0.55,
      width * 0.9,
      height * 0.4,
    );
    path.cubicTo(
      width * 0.9,
      height * 0.1,
      width / 2,
      height * 0.1,
      width / 2,
      height * 0.25,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DiamondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width * 0.2, height * 0.4);
    path.lineTo(width * 0.6, height * 0.4);
    path.lineTo(width * 0.6, height * 0.2);
    path.lineTo(width, height * 0.5);
    path.lineTo(width * 0.6, height * 0.8);
    path.lineTo(width * 0.6, height * 0.6);
    path.lineTo(width * 0.2, height * 0.6);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;

    // Horizontal bar
    path.addRect(Rect.fromLTWH(0, height * 0.4, width, height * 0.2));
    // Vertical bar
    path.addRect(Rect.fromLTWH(width * 0.4, 0, width * 0.2, height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}