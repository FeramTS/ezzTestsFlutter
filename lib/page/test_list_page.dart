import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:EzzTests/page/test_take_page.dart';

class TestListPage extends StatefulWidget {
  @override
  _TestListPageState createState() => _TestListPageState();
}

class _TestListPageState extends State<TestListPage> {
  List<String> testPaths = [];

  @override
  void initState() {
    super.initState();
    _loadTestPaths();
  }

  Future<void> _loadTestPaths() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> paths = prefs.getStringList('testPaths') ?? [];

    List<String> validPaths = [];
    for (var path in paths) {
      if (await File(path).exists()) {
        validPaths.add(path);
      }
    }

    if (validPaths.length != paths.length) {
      await prefs.setStringList('testPaths', validPaths);
    }

    setState(() {
      testPaths = validPaths;
    });
  }

  Future<void> _addTestPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    testPaths.add(path);
    await prefs.setStringList('testPaths', testPaths);
    setState(() {});
  }

  Future<void> _removeTestPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    testPaths.remove(path);
    await prefs.setStringList('testPaths', testPaths);
    setState(() {});
  }

  void _openTest(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeTestPage(testPath: path),
      ),
    );
  }

  Future<void> _showAddTestDialog() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String path = result.files.single.path!;
      _addTestPath(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Список тестов',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: testPaths.isEmpty
            ? Center(
                child: Text(
                  'Нет доступных тестов',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              )
            : ListView.builder(
                itemCount: testPaths.length,
                itemBuilder: (context, index) {
                  String path = testPaths[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.description,
                        size: 30,
                      ),
                      title: Text(
                        path.split('/').last,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Путь: ${path.split('/').last}'),
                      onTap: () => _openTest(path),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeTestPath(path),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTestDialog,
        icon: Icon(Icons.add),
        label: Text('Добавить тест'),
      ),
    );
  }
}
