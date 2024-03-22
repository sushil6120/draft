import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PostViewModel with ChangeNotifier {
  bool isLaoding = false;

  setLoading(bool value) {
    isLaoding = value;
    notifyListeners();
  }

  Future<void> uploadToApi(
      String title, File _image, BuildContext context, String location) async {
    setLoading(true);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://apna-company.vercel.app/api/worker/category'),
      );

      // Set content type header
      request.headers['Content-Type'] = 'multipart/form-data';

      request.fields['categoryName'] = title;
      request.files
          .add(await http.MultipartFile.fromPath('categoryImg', _image.path));
      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Post uploaded successfully');
        final responseData = await response.stream.bytesToString();
        print(response.stream.bytesToString());
        print(response.statusCode);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Post Uploaded")));
        setLoading(false);
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        print('Failed to upload post');
        final responseData = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text("Category Already Exist !. Usse diffrent Title Name")));
        print('Response Data: $responseData');
        print(response.stream.bytesToString());
        print(response.statusCode);
        setLoading(false);
      }else{
           final responseData = await response.stream.bytesToString();
          print('Response Data: $responseData');
        print(response.stream.bytesToString());
        print(response.statusCode);
        setLoading(false);
      }
    } catch (e) {
      print('Error uploading post: $e');
      setLoading(false);
      // print(response.statusCode);
    }
  }
}
