import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

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

  AudioPlayer player = AudioPlayer();
  double _value = 6;
  bool isPlaying = false;
  bool isResume = false;
  FilePickerResult? selectedfileResult;
  int maxduration = 100;
  int currentpos = 0;
  String currentpostlabel = "00:00";
  String audioasset = "assets/audios/Jada.mp3";

  // bool isplaying = false;
  bool audioplayed = false;
  late Uint8List audiobytes;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      ByteData bytes =
          await rootBundle.load(audioasset); //load audio from assets
      audiobytes =
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
      //convert ByteData to Uint8List

      player.onDurationChanged.listen((Duration d) {
        //get the duration of audio
        maxduration = d.inMilliseconds;
        setState(() {});
      });

      player.onAudioPositionChanged.listen((Duration p) {
        currentpos =
            p.inMilliseconds; //get the current position of playing audio

        //generating the duration label
        int shours = Duration(milliseconds: currentpos).inHours;
        int sminutes = Duration(milliseconds: currentpos).inMinutes;
        int sseconds = Duration(milliseconds: currentpos).inSeconds;

        int rhours = shours;
        int rminutes = sminutes - (shours * 60);
        int rseconds = sseconds - (sminutes * 60 + shours * 60 * 60);

        currentpostlabel = "$rhours:$rminutes:$rseconds";

        setState(() {
          //refresh the UI
        });
      });
    });
    super.initState();
    // _initSpeech();
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
    selectedfileResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );
    // Uint8List uint8list = Uint8List.fromList(File(selectedfileResult?.files.first.path ?? "").readAsBytesSync());
    Future.delayed(Duration.zero, () async {
      // /load audio from assets
      audiobytes = Uint8List.fromList(
          File(selectedfileResult?.files.first.path ?? "").readAsBytesSync());
      //convert ByteData to Uint8List
    });
    setState(() {});
  }

  playAudio() async {
    if (isPlaying == true) {
      int result = await player.stop();
      if (result == 1) {
        isPlaying = false;
        setState(() {});
      }
      tx = 'Play Audio';
    } else {
      // final file = new File(selectedfileResult?.files.single.path ?? "");
      // await file.writeAsBytes((await pickFiles()).buffer.asUint8List());
      // setState(() {});
      print('trying to play audio');
      // final result = await player.play(audioPath, isLocal: true);

      int result = await player.playBytes(audiobytes);
      if (result == 1) {
        isPlaying = true;

        setState(() {});
      }
      print('done to play audio');

      tx = 'Stop Audio';
    }
    setState(() {});
  }

  pausAud() async {
    if (isResume == false) {
      int result = await player.pause();
      if (result == 1) {
        isResume = true;
        setState(() {});
      }
    } else {
      int result = await player.resume();
      if (result == 1) {
        isResume = false;
        setState(() {});
      }
    }
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
            // Container(
            //   padding: EdgeInsets.all(16),
            //   child: Text(
            //     'Recognized words:',
            //     style: TextStyle(fontSize: 20.0),
            //   ),
            // ),
            // Container(
            //   padding: EdgeInsets.all(16),
            //   child: Text(
            //     'Speech not available',
            //   ),
            // ),
            Text(selectedfileResult?.files.first.name ?? ""),
            TextButton(
                onPressed: () {
                  pickFiles();
                },
                child: Text(
                    'Select audio ${selectedfileResult == null ? "" : "for Replace"}')),
            if (selectedfileResult == null)
              Container()
            else
              Container(
                  child: Slider(
                value: double.parse(currentpos.toString()),
                min: 0,
                max: double.parse(maxduration.toString()),
                divisions: maxduration,
                label: currentpostlabel,
                onChanged: (double value) async {
                  int seekval = value.round();
                  int result =
                      await player.seek(Duration(milliseconds: seekval));
                  if (result == 1) {
                    //seek successful
                    currentpos = seekval;
                  } else {
                    print("Seek unsuccessful.");
                  }
                },
              )),
            if (selectedfileResult == null)
              Container()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Text('00:00'),
                  TextButton(
                      onPressed: () {
                        playAudio();
                      },
                      child: Text(isPlaying == false ? 'Play' : 'Stop')),
                  Text('$currentpostlabel'),
                ],
              ),
            isPlaying
                ? TextButton(
                    onPressed: () {
                      pausAud();
                    },
                    child: Text(!isResume ? 'Pause' : 'Resume'))
                : Container(),
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
