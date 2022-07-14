// import 'dart:html';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_recognition_result.dart';
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:audioplayers/audioplayers.dart';

class VoiceView extends StatefulWidget {
  @override
  State<VoiceView> createState() => _VoiceViewState();
}

class _VoiceViewState extends State<VoiceView> {
  // SpeechToText _speechToText = SpeechToText();
  // AudioPlayer audioPlayer = AudioPlayer();
  String audioPath = "assets/audios/Jada.mp3";
  bool _speechEnabled = false;
  String? file;
  bool filewxits = false;
  String _lastWords = '';
  String tx = 'Play Audio';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    // _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  // /// Each time to start a speech recognition session
  // void _startListening() async {
  //   await _speechToText.listen(onResult: _onSpeechResult);
  //   setState(() {});
  // }
  //
  // /// Manually stop the active speech recognition session
  // /// Note that there are also timeouts that each platform enforces
  // /// and the SpeechToText plugin supports setting timeouts on the
  // /// listen method.
  // void _stopListening() async {
  //   await _speechToText.stop();
  //   setState(() {});
  // }
  //
  // /// This is the callback that the SpeechToText plugin calls when
  // /// the platform returns recognized words.
  // void _onSpeechResult(SpeechRecognitionResult result) {
  //   setState(() {
  //     _lastWords = result.recognizedWords;
  //   });
  // }

  pickFiles() async {
    var result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null) {
      print(result.files.first.path);
      // audioPath = result.files.first.name;
      filewxits = true;
    } else {
      filewxits = false;
    }

    setState(() {});
  }

  playAudio() async {
    if (tx == 'Stop Audio') {
      // int result = await audioPlayer.stop();
      tx = 'Play Audio';
    } else {
      // int result = await audioPlayer.play(audioPath, isLocal: false);

      tx = 'Stop Audio';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wellcome Narrator :).....'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'Recognized words:',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Text('Speech not available',
              ),
            ),
            TextButton(
                onPressed: () {
                  pickFiles();
                },
                child: Text('select audio')),
            filewxits != false
                ? TextButton(
                    onPressed: () {
                      playAudio();
                    },
                    child: Text(tx))
                : Container(),
          ],
        ),
      ),
    );
  }

  // Widget oldbuild(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('Wellcome Narrator :).....'),
  //     ),
  //     body: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: <Widget>[
  //           Container(
  //             padding: EdgeInsets.all(16),
  //             child: Text(
  //               'Recognized words:',
  //               style: TextStyle(fontSize: 20.0),
  //             ),
  //           ),
  //           Container(
  //             padding: EdgeInsets.all(16),
  //             child: Text(
  //               // If listening is active show the recognized words
  //               _speechToText.isListening
  //                   ? '$_lastWords'
  //                   // If listening isn't active but could be tell the user
  //                   // how to start it, otherwise indicate that speech
  //                   // recognition is not yet ready or not supported on
  //                   // the target device
  //                   : _speechEnabled
  //                       ? 'Tap the microphone to start listening...'
  //                       : 'Speech not available',
  //             ),
  //           ),
  //           TextButton(
  //               onPressed: () {
  //                 pickFiles();
  //               },
  //               child: Text('select audio')),
  //           filewxits != false
  //               ? TextButton(
  //                   onPressed: () {
  //                     playAudio();
  //                   },
  //                   child: Text(tx))
  //               : Container(),
  //         ],
  //       ),
  //     ),
  //     floatingActionButton: FloatingActionButton(
  //       onPressed:
  //           // If not yet listening for speech start, otherwise stop
  //           _speechToText.isNotListening ? _startListening : _stopListening,
  //       tooltip: 'Listen',
  //       child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
  //     ),
  //   );
  // }
}
