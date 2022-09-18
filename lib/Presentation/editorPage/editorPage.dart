import 'dart:io';
import 'dart:typed_data';
import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({Key? key}) : super(key: key);

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  FilePickerResult? selectedfileResult;
  late Uint8List videobytes;

  pickFiles() async {
    selectedfileResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4'],
    );
    // Uint8List uint8list = Uint8List.fromList(File(selectedfileResult?.files.first.path ?? "").readAsBytesSync());
    Future.delayed(Duration.zero, () async {
      // /load audio from assets
      videobytes = Uint8List.fromList(
          File(selectedfileResult?.files.first.path ?? "").readAsBytesSync());
      //convert ByteData to Uint8List
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wellcome Animator :).....'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextButton(
                onPressed: () {
                  pickFiles();
                },
                child: Text('Select video ${selectedfileResult == null ? "" : "for Replace"}')),


          ],
        ),
      ),
    );
  }
}
