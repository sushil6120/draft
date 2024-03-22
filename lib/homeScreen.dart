import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/postViewModel.dart';
import 'package:flutter_application_1/upadeddataScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  final picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  late List<Map<String, dynamic>> _drafts = [];
  bool _isImagePickerActive = false;
  bool isLoading = false;
  late ConnectivityResult _connectivityResult = ConnectivityResult.none;

  int _selectedDraftIndex = 0;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadDrafts();
    _uploadDraftsIfInternetAvailable();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectivityResult = result;
        if (_connectivityResult == ConnectivityResult.wifi ||
            _connectivityResult == ConnectivityResult.mobile) {
          _uploadDraftsIfInternetAvailable();
        }
      });
    });
  }

  Future<void> _initConnectivity() async {
    _connectivityResult = await Connectivity().checkConnectivity();
  }

  Future<void> _uploadDraftsIfInternetAvailable() async {
    if (_connectivityResult == ConnectivityResult.none) return;

    for (var draft in _drafts) {
      String title = draft['title'] ?? '';
      File image = File(draft['image_path'] ?? '');
      String location = draft['location'] ?? '';
      await Provider.of<PostViewModel>(context, listen: false)
          .uploadToApi(title, image, context, location);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploading draft: $title'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Remove all drafts after they are uploaded
    await _removeAllDrafts();
  }

  Future<void> _removeAllDrafts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('drafts');
    await prefs.clear();
    setState(() {
      _drafts.clear();
    });
  }

  Future<void> _loadDrafts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? drafts = prefs.getStringList('drafts') ?? [];
    List<Map<String, dynamic>> parsedDrafts = [];
    for (String draft in drafts) {
      Map<String, dynamic> draftMap = jsonDecode(draft);
      parsedDrafts.add({
        'title': draftMap['title'].toString(),
        'image_path': draftMap['image_path'].toString(),
        'location': draftMap['location'].toString(),
      });
    }
    setState(() {
      _drafts = parsedDrafts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Image Upload'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UploadedDataScreen(),
                      ));
                },
                child: Text("Upload Data Screen"))
          ],
        ),
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _image == null
                        ? Text('No image selected.')
                        : Image.file(_image!),
                    ElevatedButton(
                      onPressed: () => _showImageSourceOptions(),
                      child: Text('Select Image'),
                    ),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                    ),
                    Consumer<PostViewModel>(
                      builder: (context, value, child) {
                        return ElevatedButton(
                          onPressed: _uploadPost,
                          child: 
                               Text('Upload Post'),
                        );
                      },
                    ),
                    Divider(),
                    Text(
                      'Drafts',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _drafts.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_drafts[index]['title'] ?? ''),
                          subtitle: Text(_drafts[index]['location'] ?? ''),
                          leading: _drafts[index]['image_path'] != null
                              ? Image.file(
                                  File(_drafts[index]['image_path']!),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : null,
                          // trailing: TextButton(
                          //     onPressed: () {
                          //       setState(() {
                          //         _drafts.removeAt(index);
                          //       });
                          //     },
                          //     child: Text(
                          //       "remove",
                          //       style: TextStyle(color: Colors.red),
                          //     )),
                          onTap: () {
                            setState(() {
                              _selectedDraftIndex = index;
                            });
                            _loadDraftImage(_drafts[index]['image_path']);
                            _titleController.text =
                                _drafts[index]['title'] ?? '';
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Consumer<PostViewModel>(
              builder: (context, value, child) {
                return value.isLaoding
                    ? Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.red,
                          ),
                        ),
                      )
                    : SizedBox();
              },
            )
          ],
        ));
  }

  void _showImageSourceOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Image From"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _getImage(ImageSource.camera);
              },
              child: Text("Camera"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _getImage(ImageSource.gallery);
              },
              child: Text("Gallery"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    setState(() {
      _isImagePickerActive = true;
    });

    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      _isImagePickerActive = false;
    });

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _uploadPost() async {
    final posProvider = Provider.of<PostViewModel>(context, listen: false);
    if (_image == null) {
      print('No image selected.');
      return;
    }

    String title = _titleController.text.trim();
    if (title.isEmpty) {
      print('Title cannot be empty.');
      return;
    }

    String location = '';
    if (_connectivityResult != ConnectivityResult.none) {
      location = await _getLocation();
    }

    if (_connectivityResult == ConnectivityResult.none || location.isEmpty) {
      await _saveAsDraft(title, location);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Saved as draft: $title")));
      _clearFields();
      _loadDrafts();
      return;
    }

    print('Uploaded: $title');

    posProvider.uploadToApi(title, _image!, context, location);

    if (_selectedDraftIndex != null) {
      _removeDraftFromList().then((value) {
        setState(() {
          _loadDrafts();
        });
      });
    }

    _clearFields();
  }

  Future<void> _removeDraftFromList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? drafts = prefs.getStringList('drafts') ?? [];
    drafts.removeAt(_selectedDraftIndex);
    await prefs.setStringList('drafts', drafts);
  }

  Future<void> _saveAsDraft(String title, String location) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? drafts = prefs.getStringList('drafts') ?? [];
    drafts.add(jsonEncode({
      'title': title,
      'image_path': _image!.path,
      'location': location,
    }));
    prefs.setStringList('drafts', drafts);
  }

  Future<void> _clearFields() async {
    setState(() {
      _image = null;
      _titleController.clear();
    });
  }

  void _loadDraftImage(String? imagePath) {
    if (imagePath != null) {
      setState(() {
        _image = File(imagePath);
      });
    }
  }

  Future<String> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      return "${position.latitude}, ${position.longitude}";
    } catch (e) {
      print("Error getting location: $e");
      return "";
    }
  }
}
