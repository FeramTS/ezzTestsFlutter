import 'package:flutter/material.dart';
import 'package:EzzTests/page/test_create_page.dart';
import 'package:EzzTests/page/test_take_page.dart';

import 'page/test_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EzzTests',
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomePage(),
        '/createTest': (context) => CreateTestPage(),
        '/takeTest': (context) => TakeTestPage(testPath: ''),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple,),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    TestListPage(),
    CreateTestPage(),
    TakeTestPage(
      testPath: '',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(
      //  title: Text('Тесты'),
      //  automaticallyImplyLeading: false,
      //),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.article_sharp),
            label: 'Мои тесты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create),
            label: 'Создать тест',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow),
            label: 'Пройти тест',
          ),
        ],
      ),
    );
  }
}
