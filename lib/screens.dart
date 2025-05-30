// Main Screen with Bottom Navigation
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:i_eye_test/main.dart';
import 'package:i_eye_test/test_widgets.dart';
import 'package:i_eye_test/test_widgets.dart' as widgets;
import 'package:i_eye_test/widgets.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          HomeScreen(
            onStartTest: () {
              _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutQuart,
              );
              setState(() {
                _currentIndex = 1;
              });
            },
          ),
          const TestScreen(),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutQuart,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.visibility), label: 'Test'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  final VoidCallback? onStartTest;
  const HomeScreen({super.key, this.onStartTest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widgets.AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('EyeCare'),
            Text('Rafiu Tunde', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'welcome-card',
              child: Material(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widgets.AppColors.primary, Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome to EyeCare Pro',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Comprehensive eye testing for better vision health',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: onStartTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: widgets.AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Start Test'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Available Tests',
              style: widgets.AppTextStyles.heading2,
            ),
            const SizedBox(height: 16),
            _buildTestCard(
              title: 'Visual Acuity Test',
              description: 'Measures clarity and sharpness of vision',
              icon: Icons.remove_red_eye,
              color: widgets.AppColors.primary,
              duration: '3-5 minutes',
              delay: 0,
            ),
            _buildTestCard(
              title: 'Color Perception Test',
              description: 'Tests for color vision deficiencies',
              icon: Icons.palette,
              color: widgets.AppColors.secondary,
              duration: '2-3 minutes',
              delay: 100,
            ),
            _buildTestCard(
              title: 'Symptom Assessment',
              description: 'Evaluates visual symptoms and comfort',
              icon: Icons.quiz,
              color: widgets.AppColors.warning,
              duration: '3-4 minutes',
              delay: 200,
            ),
            _buildTestCard(
              title: 'Number Recognition',
              description: 'Assesses cognitive visual processing',
              icon: Icons.numbers,
              color: widgets.AppColors.success,
              duration: '2-3 minutes',
              delay: 300,
            ),
            _buildTestCard(
              title: 'Object Identification',
              description: 'Tests visual recognition abilities',
              icon: Icons.category,
              color: widgets.AppColors.info,
              duration: '2-3 minutes',
              delay: 400,
            ),
            Center(child: Text('Rafiu Tunde', style: TextStyle(fontSize: 10))),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String duration,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: clampedValue,
          child: Opacity(
            opacity: clampedValue,
            child: TestCard(
              title: title,
              description: description,
              icon: icon,
              color: color,
              duration: duration,
            ),
          ),
        );
      },
    );
  }
}

// Test Screen
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  int _currentTestIndex = 0;
  final List<String> _testTypes = [
    'visualAcuity',
    'questionnaire',
    'colorPerception',
    'numberRecognition',
    'objectIdentification',
  ];

  @override
  void initState() {
    super.initState();
    TestService().initializeTest();
  }

  void _nextTest(Map<String, dynamic> results) {
    TestService().saveTestResults(_testTypes[_currentTestIndex], results);

    if (_currentTestIndex < _testTypes.length - 1) {
      setState(() {
        _currentTestIndex++;
      });
    } else {
      _completeAllTests();
    }
  }

  Future<void> _completeAllTests() async {
    final allResults = TestService().getAllTestResults();
    final testResult = await ScoringService().processTestResults(allResults);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(testResult: testResult),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test ${_currentTestIndex + 1} of ${_testTypes.length}'),
        backgroundColor: widgets.AppColors.primary,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentTestIndex + 1) / _testTypes.length,
            backgroundColor: widgets.AppColors.border,
            color: widgets.AppColors.primary,
          ),
          Expanded(child: _buildCurrentTest()),
        ],
      ),
    );
  }

  Widget _buildCurrentTest() {
    switch (_testTypes[_currentTestIndex]) {
      case 'visualAcuity':
        return VisualAcuityTest(onComplete: _nextTest);
      case 'questionnaire':
        return QuestionnaireTest(onComplete: _nextTest);
      case 'colorPerception':
        return ColorVisionTest(onComplete: _nextTest);
      case 'numberRecognition':
        return NumberRecognitionTest(onComplete: _nextTest);
      case 'objectIdentification':
        return ObjectRecognitionTest(onComplete: _nextTest);
      default:
        return const Center(child: Text('Unknown test'));
    }
  }
}

// Results Screen
class ResultsScreen extends StatefulWidget {
  final TestResult testResult;

  const ResultsScreen({super.key, required this.testResult});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();

    _scoreAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.testResult.overallScore,
    ).animate(
      CurvedAnimation(
        parent: _scoreAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        backgroundColor: widgets.AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareReport),
          IconButton(icon: const Icon(Icons.print), onPressed: _printReport),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallScoreCard(),
            const SizedBox(height: 24),
            _buildDetailedResults(),
            const SizedBox(height: 24),
            _buildDetectedConditions(),
            const SizedBox(height: 24),
            _buildRecommendations(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Home'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const TestScreen()),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Take Another Test'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getScoreGradientColors(widget.testResult.overallScore),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.visibility, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Overall Eye Health Score',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return Text(
                '${_scoreAnimation.value.round()}%',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
          Text(
            _getScoreInterpretation(widget.testResult.overallScore),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedResults() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text('Detailed Results', style: widgets.AppTextStyles.heading2),
          const SizedBox(height: 20),
          ...widget.testResult.scores.entries.map((entry) {
            final testName = _getTestDisplayName(entry.key);
            final score = entry.value as double;
            return _buildTestScoreItem(testName, score);
          }),
        ],
      ),
    );
  }

  Widget _buildTestScoreItem(String testName, double score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                testName,
                style: widgets.AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${score.round()}%',
                style: widgets.AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: widgets.AppColors.border,
            color: _getScoreColor(score),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedConditions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Detected Conditions',
            style: widgets.AppTextStyles.heading2,
          ),
          const SizedBox(height: 16),
          if (widget.testResult.detectedConditions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widgets.AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No significant conditions detected',
                style: TextStyle(
                  color: widgets.AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ...widget.testResult.detectedConditions.map((condition) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widgets.AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  condition,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: widgets.AppColors.warning,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Medical Recommendations',
            style: widgets.AppTextStyles.heading2,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widgets.AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.testResult.recommendation,
              style: widgets.AppTextStyles.bodyLarge.copyWith(
                color: widgets.AppColors.primary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareReport,
                icon: const Icon(Icons.share),
                label: const Text('Share Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widgets.AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _printReport,
                icon: const Icon(Icons.print),
                label: const Text('Print Report'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TestScreen()),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Take Another Test'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return widgets.AppColors.success;
    if (score >= 70) return widgets.AppColors.warning;
    return widgets.AppColors.error;
  }

  List<Color> _getScoreGradientColors(double score) {
    if (score >= 85) {
      return [widgets.AppColors.success, const Color(0xFF66BB6A)];
    } else if (score >= 70) {
      return [widgets.AppColors.warning, const Color(0xFFFFB74D)];
    } else {
      return [widgets.AppColors.error, const Color(0xFFEF5350)];
    }
  }

  String _getScoreInterpretation(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs Attention';
  }

  String _getTestDisplayName(String testKey) {
    switch (testKey) {
      case 'visualAcuity':
        return 'Visual Acuity Test';
      case 'questionnaire':
        return 'Symptom Assessment';
      case 'colorPerception':
        return 'Color Perception Test';
      case 'numberRecognition':
        return 'Number Recognition Test';
      case 'objectIdentification':
        return 'Object Identification Test';
      default:
        return testKey;
    }
  }

  Future<void> _shareReport() async {
    try {
      await ReportService().generateAndShareReport(widget.testResult);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing report: $e'),
            backgroundColor: widgets.AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _printReport() async {
    try {
      await ReportService().printReport(widget.testResult);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing report: $e'),
            backgroundColor: widgets.AppColors.error,
          ),
        );
      }
    }
  }
}

// History Screen
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TestResult> _testResults = [];
  bool _isLoading = true;
  final Map<String, bool> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _loadTestResults();
  }

  Future<void> _loadTestResults() async {
    setState(() => _isLoading = true);
    try {
      final results = await StorageService.instance.getAllTestResults();
      setState(() {
        _testResults = results;
        _isLoading = false;
        // Initialize expanded state for each item
        for (var result in results) {
          _expandedItems[result.id] = false;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: ${e.toString()}'),
            backgroundColor: widgets.AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteTestResult(String id) async {
    try {
      await StorageService.instance.deleteTestResult(id);
      setState(() {
        _testResults.removeWhere((result) => result.id == id);
        _expandedItems.remove(id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test result deleted successfully'),
            backgroundColor: widgets.AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting test result: ${e.toString()}'),
            backgroundColor: widgets.AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      _expandedItems[id] = !(_expandedItems[id] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        backgroundColor: widgets.AppColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Test History'),
            Text('Rafiu Tunde', style: TextStyle(fontSize: 10)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTestResults,
            tooltip: 'Refresh history',
          ),
        ],
      ),

      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: widgets.AppColors.primary,
                ),
              )
              : _testResults.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: widgets.AppColors.textLight),
          const SizedBox(height: 24),
          const Text('No Test History', style: widgets.AppTextStyles.heading2),
          const SizedBox(height: 12),
          Text(
            'Take your first eye test to see results here',
            style: widgets.AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const TestScreen()),
              );
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Start New Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widgets.AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _testResults.length,
      itemBuilder: (context, index) {
        final testResult = _testResults[index];
        final isExpanded = _expandedItems[testResult.id] ?? false;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getScoreColor(testResult.overallScore),
                    child: Text(
                      '${testResult.overallScore.round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    _formatDate(testResult.timestamp),
                    style: widgets.AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${testResult.detectedConditions.length} condition(s) detected',
                    style: widgets.AppTextStyles.bodyMedium,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: widgets.AppColors.textSecondary,
                        ),
                        onPressed: () => _toggleExpand(testResult.id),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: widgets.AppColors.error,
                        ),
                        onPressed: () => _showDeleteDialog(testResult.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ResultsScreen(testResult: testResult),
                      ),
                    );
                  },
                ),
                if (isExpanded) _buildExpandedContent(testResult),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedContent(TestResult testResult) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Test Summary',
            style: widgets.AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...testResult.scores.entries.map((entry) {
            final testName = _getTestDisplayName(entry.key);
            final score = entry.value as double;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      testName,
                      style: widgets.AppTextStyles.bodyMedium,
                    ),
                  ),
                  Text(
                    '${score.round()}%',
                    style: TextStyle(
                      color: _getScoreColor(score),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (testResult.detectedConditions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Detected Conditions',
              style: widgets.AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  testResult.detectedConditions.map((condition) {
                    return Chip(
                      label: Text(
                        condition,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: widgets.AppColors.warning.withOpacity(
                        0.1,
                      ),
                      labelStyle: TextStyle(color: widgets.AppColors.warning),
                    );
                  }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ResultsScreen(testResult: testResult),
                    ),
                  ).then((_) => _loadTestResults());
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widgets.AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ResultsScreen(testResult: testResult),
                    ),
                  ).then((_) => _loadTestResults());
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Test Result'),
          content: const Text(
            'Are you sure you want to delete this test result? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: widgets.AppColors.error),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTestResult(id);
              },
            ),
          ],
        );
      },
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return widgets.AppColors.success;
    if (score >= 70) return widgets.AppColors.warning;
    return widgets.AppColors.error;
  }

  String _formatDate(DateTime dateTime) {
    final formatter = DateFormat('MMM dd, yyyy - hh:mm a');
    return formatter.format(dateTime);
  }

  String _getTestDisplayName(String testKey) {
    switch (testKey) {
      case 'visualAcuity':
        return 'Visual Acuity';
      case 'questionnaire':
        return 'Symptom Assessment';
      case 'colorPerception':
        return 'Color Perception';
      case 'numberRecognition':
        return 'Number Recognition';
      case 'objectIdentification':
        return 'Object Identification';
      default:
        return testKey;
    }
  }
}
