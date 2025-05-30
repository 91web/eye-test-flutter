// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:i_eye_test/screens.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.initialize();
  runApp(const EyeTestApp());
}

class EyeTestApp extends StatelessWidget {
  const EyeTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EyeCare Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Colors and Styling
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color border = Color(0xFFE0E0E0);
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

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}

// Constants
class AppConstants {
  static const Map<String, double> testWeights = {
    'visualAcuity': 0.3,
    'questionnaire': 0.25,
    'colorPerception': 0.2,
    'numberRecognition': 0.15,
    'objectIdentification': 0.1,
  };

  static const List<String> visualAcuityLetters = [
    'E',
    'F',
    'P',
    'T',
    'O',
    'Z',
    'L',
    'P',
    'E',
    'D',
  ];
  static const List<double> visualAcuitySizes = [
    48,
    40,
    32,
    24,
    20,
    16,
    14,
    12,
    10,
    8,
  ];

  static const List<Color> testColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
  ];

  static const List<String> testObjects = [
    'Circle',
    'Square',
    'Triangle',
    'Star',
    'Heart',
    'Diamond',
    'Arrow',
    'Cross',
  ];
}

// Models
class TestResult {
  final String id;
  final DateTime timestamp;
  final Map<String, dynamic> scores;
  final List<String> detectedConditions;
  final String recommendation;
  final double overallScore;
  final Map<String, List<double>> responseTimes;

  TestResult({
    required this.id,
    required this.timestamp,
    required this.scores,
    required this.detectedConditions,
    required this.recommendation,
    required this.overallScore,
    required this.responseTimes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'scores': jsonEncode(scores),
      'detected_conditions': jsonEncode(detectedConditions),
      'recommendation': recommendation,
      'overall_score': overallScore,
      'response_times': jsonEncode(responseTimes),
    };
  }

  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      scores: Map<String, dynamic>.from(jsonDecode(map['scores'])),
      detectedConditions: List<String>.from(
        jsonDecode(map['detected_conditions']),
      ),
      recommendation: map['recommendation'],
      overallScore: map['overall_score'],
      responseTimes: Map<String, List<double>>.from(
        jsonDecode(
          map['response_times'],
        ).map((key, value) => MapEntry(key, List<double>.from(value))),
      ),
    );
  }
}

class QuestionnaireQuestion {
  final String question;
  final List<String> options;
  final String category;
  final String? description;

  QuestionnaireQuestion({
    required this.question,
    required this.options,
    required this.category,
    this.description,
  });
}

// Services
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static StorageService get instance => _instance;
  Database? _database;

  Future<void> initialize() async {
    _database = await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'eye_test.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE test_results (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        scores TEXT NOT NULL,
        detected_conditions TEXT NOT NULL,
        recommendation TEXT NOT NULL,
        overall_score REAL NOT NULL,
        response_times TEXT NOT NULL
      )
    ''');
  }

  Future<void> saveTestResult(TestResult testResult) async {
    final db = _database;
    if (db == null) return;

    await db.insert(
      'test_results',
      testResult.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TestResult>> getAllTestResults() async {
    final db = _database;
    if (db == null) return [];

    final List<Map<String, dynamic>> maps = await db.query(
      'test_results',
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => TestResult.fromMap(map)).toList();
  }

  Future<void> deleteTestResult(String id) async {
    final db = _database;
    if (db == null) return;

    await db.delete('test_results', where: 'id = ?', whereArgs: [id]);
  }
}




























class TestService {
  static final TestService _instance = TestService._internal();
  factory TestService() => _instance;
  TestService._internal();

  final Map<String, Map<String, dynamic>> _currentTestResults = {};
  DateTime? _testStartTime;

  void initializeTest() {
    _currentTestResults.clear();
    _testStartTime = DateTime.now();
  }

  void saveTestResults(String testType, Map<String, dynamic> results) {
    _currentTestResults[testType] = results;
  }

  Map<String, Map<String, dynamic>> getAllTestResults() {
    return Map.from(_currentTestResults);
  }

  DateTime? getTestStartTime() {
    return _testStartTime;
  }

  void clearTestResults() {
    _currentTestResults.clear();
    _testStartTime = null;
  }
}

class ScoringService {
  static final ScoringService _instance = ScoringService._internal();
  factory ScoringService() => _instance;
  ScoringService._internal();

  Future<TestResult> processTestResults(
    Map<String, Map<String, dynamic>> testResults,
  ) async {
    final String testId = _generateTestId();
    final DateTime timestamp = DateTime.now();

    final Map<String, dynamic> scores = {};
    final Map<String, List<double>> responseTimes = {};

    double totalWeightedScore = 0;
    double totalWeight = 0;

    for (final entry in testResults.entries) {
      final testType = entry.key;
      final results = entry.value;
      final weight = AppConstants.testWeights[testType] ?? 0.0;

      double testScore = _calculateTestScore(testType, results);
      scores[testType] = testScore;

      if (results.containsKey('responseTimes')) {
        responseTimes[testType] = List<double>.from(results['responseTimes']);
      }

      totalWeightedScore += testScore * weight;
      totalWeight += weight;
    }

    final double overallScore =
        totalWeight > 0 ? totalWeightedScore / totalWeight : 0;
    final List<String> detectedConditions = _detectConditions(
      testResults,
      scores,
    );
    final String recommendation = _generateRecommendation(
      overallScore,
      detectedConditions,
    );

    final TestResult testResult = TestResult(
      id: testId,
      timestamp: timestamp,
      scores: scores,
      detectedConditions: detectedConditions,
      recommendation: recommendation,
      overallScore: overallScore,
      responseTimes: responseTimes,
    );

    await StorageService.instance.saveTestResult(testResult);
    return testResult;
  }

  double _calculateTestScore(String testType, Map<String, dynamic> results) {
    switch (testType) {
      case 'visualAcuity':
        final double accuracy = results['accuracy'] ?? 0.0;
        final double avgResponseTime = results['avgResponseTime'] ?? 0.0;
        double score = accuracy;
        if (avgResponseTime < 2.0) {
          score *= 0.9;
        } else if (avgResponseTime > 8.0)
          // ignore: curly_braces_in_flow_control_structures
          score *= 0.8;
        return score.clamp(0.0, 100.0);

      case 'questionnaire':
        final Map<String, int> symptomScores = Map<String, int>.from(
          results['symptomScores'] ?? {},
        );
        double totalSymptomScore = 0;
        int totalQuestions = 0;
        for (final score in symptomScores.values) {
          totalSymptomScore += score;
          totalQuestions += 3;
        }
        double score =
            totalQuestions > 0
                ? (1 - (totalSymptomScore / (totalQuestions * 3))) * 100
                : 100;
        return score.clamp(0.0, 100.0);

      case 'colorPerception':
        final double accuracy = results['accuracy'] ?? 0.0;
        final Map<String, int> deficiencyPatterns = Map<String, int>.from(
          results['deficiencyPatterns'] ?? {},
        );
        double score = accuracy;
        final int totalErrors = deficiencyPatterns.values.fold(
          0,
          (sum, errors) => sum + errors,
        );
        if (totalErrors > 2) {
          score *= 0.7;
        } else if (totalErrors > 0)
          score *= 0.85;
        return score.clamp(0.0, 100.0);

      case 'numberRecognition':
      case 'objectIdentification':
        final double accuracy = results['accuracy'] ?? 0.0;
        final double avgResponseTime = results['avgResponseTime'] ?? 0.0;
        double score = accuracy;
        if (avgResponseTime > 10.0) score *= 0.85;
        return score.clamp(0.0, 100.0);

      default:
        return 0.0;
    }
  }

  List<String> _detectConditions(
    Map<String, Map<String, dynamic>> testResults,
    Map<String, dynamic> scores,
  ) {
    final List<String> conditions = [];

    final double visualAcuityScore = scores['visualAcuity'] ?? 100.0;
    if (visualAcuityScore < 70) conditions.add('Refractive Error Indicators');
    if (visualAcuityScore < 50) {
      conditions.add('Significant Visual Acuity Impairment');
    }

    if (testResults.containsKey('colorPerception')) {
      final Map<String, int> deficiencyPatterns = Map<String, int>.from(
        testResults['colorPerception']!['deficiencyPatterns'] ?? {},
      );
      if ((deficiencyPatterns['Red-Green'] ?? 0) >= 2) {
        conditions.add('Red-Green Color Vision Deficiency');
      }
      if ((deficiencyPatterns['Blue-Yellow'] ?? 0) >= 2) {
        conditions.add('Blue-Yellow Color Vision Deficiency');
      }
    }

    if (testResults.containsKey('questionnaire')) {
      final Map<String, int> symptomScores = Map<String, int>.from(
        testResults['questionnaire']!['symptomScores'] ?? {},
      );
      if ((symptomScores['lightSensitivity'] ?? 0) >= 6) {
        conditions.add('Light Sensitivity (Photophobia)');
      }
      if ((symptomScores['nightVision'] ?? 0) >= 6) {
        conditions.add('Night Vision Difficulties');
      }
      if ((symptomScores['eyeDiscomfort'] ?? 0) >= 8) {
        conditions.add('Dry Eye Syndrome Indicators');
      }
    }

    final double numberScore = scores['numberRecognition'] ?? 100.0;
    final double objectScore = scores['objectIdentification'] ?? 100.0;
    if (numberScore < 60 || objectScore < 60) {
      conditions.add('Visual Processing Difficulties');
    }

    return conditions;
  }

  String _generateRecommendation(
    double overallScore,
    List<String> detectedConditions,
  ) {
    if (overallScore >= 85 && detectedConditions.isEmpty) {
      return 'No significant issues detected. Continue regular eye care and annual check-ups.';
    } else if (overallScore >= 70 && detectedConditions.length <= 2) {
      return 'Minor concerns detected. Monitor these symptoms and consider an eye examination within 3-6 months.';
    } else if (overallScore >= 50 || detectedConditions.length <= 4) {
      return 'Several concerns identified. Schedule an appointment with an eye care professional within 1-2 months.';
    } else {
      return 'Multiple significant concerns detected. See an ophthalmologist within 1-2 weeks for comprehensive evaluation.';
    }
  }

  String _generateTestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'test_${timestamp}_$random';
  }
}

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  Future<void> generateAndShareReport(TestResult testResult) async {
    final pdf = await _generatePDF(testResult);
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/eye_test_report_${testResult.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Eye Test Report');
  }

  Future<void> printReport(TestResult testResult) async {
    final pdf = await _generatePDF(testResult);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<pw.Document> _generatePDF(TestResult testResult) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EyeCare Pro',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.Text(
                        'Comprehensive Eye Test Report',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.blue600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Test Information',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Test ID: ${testResult.id}'),
                  pw.Text('Date: ${_formatDate(testResult.timestamp)}'),
                  pw.Text('Overall Score: ${testResult.overallScore.round()}%'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Recommendations',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(testResult.recommendation),
          ];
        },
      ),
    );

    return pdf;
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
