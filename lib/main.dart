import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes/NotesScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SharedPreferencesListDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class SharedPreferencesListDemo extends StatefulWidget {
  @override
  _SharedPreferencesListDemoState createState() => _SharedPreferencesListDemoState();
}

class _SharedPreferencesListDemoState extends State<SharedPreferencesListDemo> {
  late SharedPreferences _prefs;
  List<MapEntry<String, String>> myList = [];
  List<MapEntry<String, String>> filteredList = [];

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadListFromSharedPreferences();
  }

  void _filterList(String query) {
    setState(() {
      filteredList = myList
          .where((entry) =>
      entry.key.toLowerCase().contains(query.toLowerCase()) ||
          entry.value.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _loadListFromSharedPreferences() async {
    List<String> keys = _prefs.getKeys().toList();
    List<MapEntry<String, String>> list = [];
    for (String key in keys) {
      String? value = _prefs.getString(key);
      if (value != null) {
        list.add(MapEntry(key, value));
      }
    }
    setState(() {
      myList = list;
    });
  }

  Future<void> deleteSharedPreferencesItem(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F3FF),
      appBar: AppBar(
        title: Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              final String? query = await showSearch<String?>(
                context: context,
                delegate: _DataSearch(myList: myList),
              );
              if (query != null) {
                _filterList(query);
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: myList.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> entryMap = json.decode(myList[index].value);
          String timestamp = entryMap['timestamp'];
          String subTitle = entryMap['value'];
          final item = myList[index];
          return Dismissible(
            key: Key(item.key),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                myList.removeAt(index);
                deleteSharedPreferencesItem(item.key);
              });
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => NotesScreen(type: 'Edit', editContent: entryMap))).then((value) {
                  setState(() {
                    value != null ? myList.remove(value):(){};
                  });
                      _loadListFromSharedPreferences();
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${myList[index].key}'),
                            Text(subTitle),
                          ],
                        ),
                        Text(formatDate(DateTime.parse(timestamp)))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
       onPressed: () {
         Navigator.push(context, MaterialPageRoute(builder: (context) => NotesScreen(type: 'New',))).then((value) {
           setState(() {
             _loadListFromSharedPreferences();
           });
         });

       },
        backgroundColor: Color(0xFF2D94CE),
        child: Icon(Icons.add,color: Colors.white,),
      ),
    );
  }

  String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}

class _DataSearch extends SearchDelegate<String?> {
  final List<MapEntry<String, String>> myList;

  _DataSearch({required this.myList});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final List<MapEntry<String, String>> results = myList
        .where((entry) =>
    entry.key.toLowerCase().contains(query.toLowerCase()) ||
        entry.value.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> entryMap = json.decode(myList[index].value);

        return ListTile(
          title: Text('${results[index].key}: ${entryMap['value']}'),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<MapEntry<String, String>> suggestions = myList
        .where((entry) =>
    entry.key.toLowerCase().contains(query.toLowerCase()) ||
        entry.value.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> entryMap = json.decode(myList[index].value);
        return ListTile(
          title: Text('${suggestions[index].key}: ${entryMap['value']}'),
        );
      },
    );
  }
}

