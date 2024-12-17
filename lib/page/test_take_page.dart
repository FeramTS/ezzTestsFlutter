import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import '../callback/callback.dart';

class TakeTestPage extends StatefulWidget {
  final String testPath;

  TakeTestPage({required this.testPath});

  @override
  _TakeTestPageState createState() => _TakeTestPageState();
}

class _TakeTestPageState extends State<TakeTestPage> {
  Map<String, dynamic>? testData;
  List<Map<String, dynamic>> userAnswers = [];
  int currentQuestionIndex = 0;
  PageController _pageController = PageController();

  // Загрузка теста
  Future<void> _loadTestFromPath(String path) async {
    try {
      final file = File(path);
      final contents = await file.readAsString();
      setState(() {
        testData = jsonDecode(contents);
        userAnswers = List.generate(testData?['questions'].length ?? 0,
            (index) => {'questionId': index, 'answer': null});
      });
    } catch (e) {
      print("Error loading test: $e");
    }
  }

  Future<void> _loadTestFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final file = File(result.files.single.path!);
      final contents = await file.readAsString();
      setState(() {
        testData = jsonDecode(contents);
        userAnswers = List.generate(testData?['questions'].length ?? 0,
            (index) => {'questionId': index, 'answer': null});
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.testPath.isNotEmpty) {
      _loadTestFromPath(widget.testPath);
    }
  }

  bool _allQuestionsAnswered() {
    return userAnswers.every((answer) => answer['answer'] != null);
  }

  void _showIncompleteWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Внимание"),
        content: Text("Ответьте на все вопросы перед завершением теста."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ОК"),
          ),
        ],
      ),
    );
  }

  void _finishTest() {
    if (_allQuestionsAnswered()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestResultsPage(
            answers: userAnswers,
            testData: testData!,
          ),
        ),
      );
    } else {
      _showIncompleteWarning();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Пройти тест'),
      ),
      body: testData == null
          ? Center(
              child: ElevatedButton(
                onPressed: _loadTestFile,
                child: Text('Выберите файл теста'),
              ),
            )
          : Column(
              children: [
                CustomProgressBar(
                  progress: (currentQuestionIndex + 1) /
                      (testData?['questions'].length ?? 1),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentQuestionIndex = index;
                      });
                    },
                    itemCount: testData!['questions'].length,
                    itemBuilder: (context, index) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(10.0),
                        child: QuestionWidget(
                          question: testData!['questions'][index],
                          onAnswerChanged: (answer) {
                            setState(() {
                              userAnswers[index]['answer'] = answer;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (currentQuestionIndex > 0) {
                            _pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Text('Назад'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (currentQuestionIndex <
                              (testData!['questions'].length - 1)) {
                            _pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finishTest();
                          }
                        },
                        child: Text(currentQuestionIndex ==
                                (testData!['questions'].length - 1)
                            ? 'Завершить'
                            : 'Вперед'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class QuestionWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  final Function(String) onAnswerChanged;

  QuestionWidget({required this.question, required this.onAnswerChanged});

  @override
  _QuestionWidgetState createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  String? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.question['question'] ?? '',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Ответы',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ...widget.question['answers'].map<Widget>((answer) {
                return RadioListTile<String>(
                  title: Text(answer['text']),
                  value: answer['text'],
                  groupValue: selectedAnswer,
                  onChanged: (value) {
                    setState(() {
                      selectedAnswer = value;
                    });
                    widget.onAnswerChanged(value!);
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomProgressBar extends StatelessWidget {
  final double progress;

  CustomProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Фон прогресс-бара
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // Индикатор прогресса
        Container(
          height: 20,
          width: progress *
              MediaQuery.of(context)
                  .size
                  .width, // Ширина пропорциональна прогрессу
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // Текст прогресса поверх бара
        Positioned.fill(
          child: Center(
            child: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TestResultsPage extends StatelessWidget {
  final List<Map<String, dynamic>> answers;
  final Map<String, dynamic> testData;

  TestResultsPage({required this.answers, required this.testData});

  num _calculateScore() {
    num score = 0;
    for (int i = 0; i < answers.length; i++) {
      var question = testData['questions'][i];
      var selectedAnswer = answers[i]['answer'];
      var selectedAnswerData = question['answers']
          .firstWhere((answer) => answer['text'] == selectedAnswer);
      score += selectedAnswerData['weight'] ?? 0;
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    num score = _calculateScore();

    String resultText = '';
    for (var result in testData['results']) {
      if (score >= result['minScore'] && score <= result['maxScore']) {
        resultText = result['resultText'];
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Результаты теста'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 100,
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.blue[50],
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Ваш балл',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              color: Colors.green[50],
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Результат',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      resultText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Вернуться',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
