import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes/NotesScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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

  void updateState(dynamic value) {


    setState(() {
      value != null ? myList.remove(value):(){};
    });
    _loadListFromSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3FF),
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final String? query = await showSearch<String?>(
                context: context,
                delegate: _DataSearch(myList: myList, callback: updateState),
              );
              if (query != null) {
                _filterList(query);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8,8.0,8,0),
        child: StaggeredGridView.countBuilder(
          crossAxisCount:2, // Number of columns
          itemCount: myList.length,
          itemBuilder: (BuildContext context, int index) {
            Map<String, dynamic> entryMap = json.decode(myList[index].value);
            String subTitle = entryMap['value'];
            String title = entryMap['title'];
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
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Confirm"),
                      content: Text("Are you sure you want to delete this item?"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text("DELETE"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text("CANCEL"),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) {
                setState(() {
                  myList.removeAt(index);
                  deleteSharedPreferencesItem(item.key);
                });
              },
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotesScreen(type: 'Edit', editContent: entryMap),
                    ),
                  ).then((value) {
                    setState(() {
                      value != null ? myList.remove(value) : () {};
                    });
                    _loadListFromSharedPreferences();
                  });
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.grey, width:0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Visibility(
                          visible: title.isNotEmpty,
                          child: Text(
                            title,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Visibility(
                          visible: subTitle.isNotEmpty,
                          child: Text(
                            maxLines: 6,
                            subTitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          staggeredTileBuilder: (int index) =>
              StaggeredTile.fit(1), // Specify the number of columns each item should occupy
          mainAxisSpacing: 10.0, // Set spacing between items vertically
          crossAxisSpacing: 10.0, // Set spacing between items horizontally
        ),
      ),



      floatingActionButton: FloatingActionButton(
       onPressed: () {
         Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesScreen(type: 'New',))).then((value) {
           setState(() {
             _loadListFromSharedPreferences();
           });
         });

       },
        backgroundColor: const Color(0xFF2D94CE),
        child: const Icon(Icons.add,color: Colors.white,),
      ),
    );
  }
  double calculateItemHeight(String text) {
    // Create a TextPainter object
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 16), // Set the font size according to your design
      ),
      maxLines: 2, // Set the maximum number of lines for the text
      textDirection: ui.TextDirection.ltr, // Set text direction to left-to-right
    );

    // Layout and calculate the text's dimensions
    textPainter.layout(maxWidth: double.infinity);

    // Return the height of the text
    return textPainter.height;
  }

  String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}

class _DataSearch extends SearchDelegate<String?> {
  final List<MapEntry<String, String>> myList;
  final Function(dynamic) callback;


  _DataSearch({required this.myList, required this.callback});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
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
          title: Text('${entryMap['title']}'),
          subtitle: Text(' ${entryMap['value']}'),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    print('query'+query);
    final List<MapEntry<String, String>> suggestions = myList.where((entry) {

      print("entry : " + entry.toString());

      Map<String, dynamic> jsonObject = json.decode(entry.value);
      print("value  : " + jsonObject['title']);
      return jsonObject['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
          jsonObject['value'].toString().toLowerCase().contains(query.toLowerCase());
    }).toList();

    print("myList" + myList.toString());
    print("suggestion" + suggestions.toString());
    return  query == '' ? const Text(''):
     ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> entryMap = json.decode(suggestions[index].value);
        return ListTile(
          onTap: () {
            print('search Navi');
            Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) => NotesScreen(type: 'Edit', editContent: entryMap))).then((value) {
                  callback(value);
            });
          },
          title: entryMap['title'].toString().isNotEmpty == false ? null :Text('${entryMap['title']}'),
          subtitle: Visibility(visible: entryMap['value'].toString().isNotEmpty ,child: Text(' ${entryMap['value']}',overflow: TextOverflow.ellipsis,)),
        );
      },
    );
  }
}

