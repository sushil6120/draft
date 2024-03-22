import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UploadedDataScreen extends StatefulWidget {
  @override
  _UploadedDataScreenState createState() => _UploadedDataScreenState();
}

class _UploadedDataScreenState extends State<UploadedDataScreen> {
  late Future<List<Map<String, dynamic>>> _fetchDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = _fetchData();
  }

  Future<List<Map<String, dynamic>>> _fetchData() async {
    final response = await http.get(Uri.parse('https://apna-company.vercel.app/api/worker/category'));
    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      print(responseData);
      return responseData.map((data) => data as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Uploaded Data'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            final List<Map<String, dynamic>> data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data.reversed.toList();
                return ListTile(
                  title: Text(item[index]['categoryName']),
                  subtitle: item[index]['categoryImg'].isEmpty
                      ? null
                      : Image.network(item[index]['categoryImg'],fit: BoxFit.cover, height: MediaQuery.of(context).size.height*.2,),
                );
              },
            );
          }
        },
      ),
    );
  }
}
