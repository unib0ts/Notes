import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesScreen extends StatefulWidget {
  final String type;
  final Map<String, dynamic>? editContent;
  const NotesScreen({super.key, required this.type, this.editContent});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  TextEditingController _controller = TextEditingController();
  TextEditingController _controllertitle = TextEditingController();
  late int randomNum;
  String content = "";
  late String _title = '';
  late String _content = '';
  late SharedPreferences _prefs;

  @override
  void dispose() {
    _controller.dispose();
    _controllertitle.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _initSharedPreferences();
    if(widget.type == 'Edit') {
      _controller.text = widget.editContent!['value'];
      _controllertitle.text = widget.editContent!['title'];
      print('editContent' + widget.editContent!.toString());
    }
    super.initState();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    int maxLines = (screenHeight / 20).floor(); // Assuming each line is
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.type! == 'Edit') {
              updateSharedPreferencesItem(widget.editContent!['key'],content);
            } else {
              _addStringMapEntry(
                  generateRandom4DigitNumber().toString(), _controller.text, _controllertitle.text);
            }
            Navigator.pop(context);
          },
        ),
        title: Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(Icons.share_sharp),
            onPressed: () {
              shareText(content);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete,color: Colors.red,),
            onPressed: () {
              deleteSharedPreferencesItem(widget.editContent!['key']);

              widget.type == 'Edit' ? Navigator.pop(context,widget.editContent!['key'].toString()): (){};
            },
          ),
          IconButton(
            icon: Text('Done', style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () {
              if (widget.type! == 'Edit') {
                updateSharedPreferencesItem(widget.editContent!['key'],content);
              } else {
                _addStringMapEntry(
                    generateRandom4DigitNumber().toString(), content, 'title');
              }
              Navigator.pop(context);
            },
          ),

        ],
      ),
      backgroundColor: Colors.white,
      body:  SizedBox(
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0,right: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 8, right: 8),
                child: TextField(
                  autofocus: widget.type! == 'Edit'? false : true,
                  controller: _controllertitle,
                  maxLines: null, // Allow multiple lines
                  textInputAction: TextInputAction.next,
                    maxLength: 100,
                 // maxLengthEnforcement: MaxLengthEnforcement.values,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 24),
                    counter: SizedBox.shrink(),
                  ),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  onChanged: (value) {
                    setState(() {
                      //content = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 8, right: 8),
                  child: TextField(
                    autofocus: widget.type! == 'Edit'? false : true,
                    controller: _controller,
                    keyboardType: TextInputType.multiline,
                    maxLines: maxLines, // Allow multiple lines
                    decoration: InputDecoration(
                      hintText: 'Note',
                      hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 17),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      setState(() {
                        content = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addStringMapEntry(String key, String value, String title) {
    DateTime now = DateTime.now();
    String dateTimeString = now.toIso8601String();
    Map<String, dynamic> entry = {
      'key': key,
      'value': value,
      'timestamp': dateTimeString,
      'title': title,
    };
    _prefs.setString(key, json.encode(entry));
  }

  int generateRandom4DigitNumber() {
    Random random = Random();
    return random.nextInt(9000) + 1000;
  }
  Future<void> updateSharedPreferencesItem(String key, String newValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Fetch current data from SharedPreferences
    String? jsonString = prefs.getString(key);
    if (jsonString != null) {
      // Decode JSON string to Map
      Map<String, dynamic> data = json.decode(jsonString);

      // Update specific item in the data
      data['value'] = newValue;

      // Encode Map to JSON string
      String updatedJsonString = json.encode(data);

      // Save updated data back to SharedPreferences
      await prefs.setString(key, updatedJsonString);
    }
  }
  Future<void> deleteSharedPreferencesItem(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
  void shareText(String text) {
    Share.share(text);
  }
}
