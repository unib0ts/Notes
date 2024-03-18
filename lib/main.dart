import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  void _addStringMapEntry(String key, String value) {
    DateTime now = DateTime.now();
    String dateTimeString = now.toIso8601String();
    Map<String, dynamic> entry = {
      'key': key,
      'value': value,
      'timestamp': dateTimeString,
    };
    _prefs.setString(key, json.encode(entry));
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
      body: Expanded(
        child: ListView.builder(
          itemCount: myList.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> entryMap = json.decode(myList[index].value);
            String timestamp = entryMap['timestamp'];
            String subTitle = entryMap['value'];
            return Padding(
              padding: const EdgeInsets.all(8.0),
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
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
       onPressed: () {
          _addStringMapEntry('key6', 'value32');
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

