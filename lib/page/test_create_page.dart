import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CreateTestPage extends StatefulWidget {
  @override
  _CreateTestPageState createState() => _CreateTestPageState();
}

class _CreateTestPageState extends State<CreateTestPage> {
  String testTitle = '';
  List<Map<String, dynamic>> questions = [];
  List<Map<String, dynamic>> results = [];

  // Метод для сброса теста
  void resetTest() {
    setState(() {
      testTitle = '';
      questions.clear();
      results.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание теста'),
        automaticallyImplyLeading: false,
        actions: [
          // Кнопка сброса теста
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetTest,
            tooltip: 'Сбросить тест',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            // Название теста
            TextField(
              decoration: InputDecoration(
                labelText: 'Название теста',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                testTitle = value;
              },
            ),
            SizedBox(height: 20),

            // Секция вопросов
            ElevatedButton(
              onPressed: () {
                setState(() {
                  questions.add({
                    'question': '',
                    'answers': [],
                  });
                });
              },
              child: Text('Добавить вопрос'),
            ),
            ...questions.asMap().entries.map((entry) {
              int index = entry.key;
              var question = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: QuestionWidget(
                  question: question,
                  onChanged: (updatedQuestion) {
                    setState(() {
                      questions[index] = updatedQuestion;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      questions.removeAt(index);
                    });
                  },
                ),
              );
            }).toList(),

            // Секция результатов
            SizedBox(height: 20),
            Text(
              'Результаты теста',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  results.add({
                    'minScore': 0,
                    'maxScore': 0,
                    'resultText': '',
                  });
                });
              },
              child: Text('Добавить результат'),
            ),
            ...results.asMap().entries.map((entry) {
              int index = entry.key;
              var result = entry.value;
              return ResultWidget(
                result: result,
                onChanged: (updatedResult) {
                  setState(() {
                    results[index] = updatedResult;
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
      // Закрепленная кнопка
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () async {
              // Проверяем, что название теста введено
              if (testTitle.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Введите название теста')),
                );
                return;
              }

              // Формируем данные теста
              final testData = {
                'title': testTitle,
                'questions': questions,
                'results': results,
              };

              // Сохраняем данные в файл
              await saveTestToFile(testData);

              // Уведомление об успешном сохранении
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Тест успешно сохранён!')),
              );
            },
            child: Text('Сохранить тест'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50), // Растянуть кнопку
            ),
          ),
        ),
      ),
    );
  }
}

class QuestionWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final Function(Map<String, dynamic>) onChanged;
  final VoidCallback onDelete;

  QuestionWidget(
      {required this.question,
      required this.onChanged,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Вопрос',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                question['question'] = value;
                onChanged(question);
              },
              maxLines: null, // Автоматический перенос текста на новую строку
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                question['answers'].add({'text': '', 'weight': 0});
                onChanged(question);
              },
              child: Text('Добавить ответ'),
            ),
            ...question['answers'].asMap().entries.map((entry) {
              int index = entry.key;
              var answer = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: AnswerWidget(
                  answer: answer,
                  onChanged: (updatedAnswer) {
                    question['answers'][index] = updatedAnswer;
                    onChanged(question);
                  },
                ),
              );
            }).toList(),

            // Кнопка для удаления вопроса
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onDelete,
                child:
                    Text('Удалить вопрос', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnswerWidget extends StatelessWidget {
  final Map<String, dynamic> answer;
  final Function(Map<String, dynamic>) onChanged;

  AnswerWidget({required this.answer, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(labelText: 'Ответ'),
              onChanged: (value) {
                answer['text'] = value;
                onChanged(answer);
              },
              maxLines: 1, // Обработка текста, не выходящего за пределы
            ),
          ),
          SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: TextField(
              decoration: InputDecoration(labelText: 'Вес'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                answer['weight'] = int.tryParse(value) ?? 0;
                onChanged(answer);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ResultWidget extends StatelessWidget {
  final Map<String, dynamic> result;
  final Function(Map<String, dynamic>) onChanged;

  ResultWidget({required this.result, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Минимальный балл',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                result['minScore'] = int.tryParse(value) ?? 0;
                onChanged(result);
              },
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Максимальный балл',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                result['maxScore'] = int.tryParse(value) ?? 0;
                onChanged(result);
              },
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Текст результата',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                result['resultText'] = value;
                onChanged(result);
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> getExternalDocumentPath() async {
  // Проверка разрешения на доступ к хранилищу
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
  Directory _directory = Directory("");
  if (Platform.isAndroid) {
    // Путь для Android — папка "Download"
    _directory = Directory("/storage/emulated/0/Download");
  } else {
    // Для других платформ (например, iOS)
    _directory = await getApplicationDocumentsDirectory();
  }

  final exPath = _directory.path;
  print("Путь сохранения: $exPath");
  await Directory(exPath).create(recursive: true);
  return exPath;
}

Future<String> get _localPath async {
  final String directory = await getExternalDocumentPath();
  return directory;
}

Future<File> saveTestToFile(Map<String, dynamic> testData) async {
  try {
    // Получаем путь для сохранения файла
    final path = await _localPath;
    // Формируем имя файла, используя title из testData или 'test' по умолчанию
    String filePath = '$path/${testData['title'] ?? 'test'}.json';

    // Преобразуем данные в формат JSON
    final jsonData = jsonEncode(testData);

    // Создаём файл и записываем данные
    final file = File(filePath);
    await file.writeAsString(jsonData);

    print('Файл успешно сохранён: $filePath');
    return file;
  } catch (e) {
    print('Ошибка при сохранении файла: $e');
    rethrow;
  }
}
