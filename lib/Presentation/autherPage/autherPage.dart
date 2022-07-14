import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:text_to_speech/text_to_speech.dart';

import '../../Utils/constant.dart';

class AutherPage extends StatefulWidget {
  @override
  State<AutherPage> createState() => _AutherPageState();
}

class _AutherPageState extends State<AutherPage> {
  int wordsc = 0;
  final words = TextEditingController();

  // TextToSpeech tts = TextToSpeech();
  String actionAudio = 'Play';
  var wordCount = {};

  audioSpeak(String? action) {
    if (action == 'Play') {
      // tts.speak(words.text);
    } else {
      // tts.stop();
    }
  }

  repeatedWords() {
    for (var match in RegExp(r"\w+('\w+)?").allMatches(words.text)) {
      wordCount.update(match.group(0), (value) => value + 1, ifAbsent: () => 1);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(wordsc <= 0
              ? 'WellCome Author :) .....'
              : 'Words count is $wordsc'),
          actions: [
            wordsc > 0
                ? TextButton(
                    onPressed: () {
                      if (actionAudio == 'Play') {
                        audioSpeak('Play');
                        actionAudio = 'Stop';
                      } else {
                        audioSpeak('Stop');
                        actionAudio = 'Play';
                      }

                      setState(() {});
                    },
                    child: Text(
                      '$actionAudio',
                      style: TextStyle(color: Colors.white),
                    ))
                : Container(),
            wordsc > 0
                ? TextButton(
                    onPressed: () async {
                      await repeatedWords();
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: Column(
                                    children: [
                                      Align(
                                          alignment: Alignment.topCenter,
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.blue,
                                                border: Border.all(
                                                  color: Colors.blue,
                                                ),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(20))),
                                            child: IconButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                icon: Icon(Icons.close_rounded,
                                                    color: Colors.white)),
                                          )),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: Colors.blue,
                                            ),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20))),
                                        // color: Colors.white,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                1.5,
                                        height:
                                            MediaQuery.of(context).size.height /
                                                0.8,
                                        child: Padding(
                                          padding: const EdgeInsets.all(18.0),
                                          child: Text(wordCount.toString()),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          });
                    },
                    child: Text(
                      'Words',
                      style: TextStyle(color: Colors.white),
                    ))
                : Container(),
          ]),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  hintText: "Insert your message",
                ),
                scrollPadding: EdgeInsets.all(20.0),
                keyboardType: TextInputType.multiline,
                controller: words,
                onChanged: (val) {
                  RegExp regExp = RegExp(" ");
                  if (words.text.isNotEmpty) {
                    wordsc = regExp
                            .allMatches(
                                val.trim().replaceAll(RegExp(r"\s+"), " "))
                            .length +
                        1;
                  } else {
                    wordsc = 0;
                  }
                  setState(() {});
                },
                maxLines: 99999,
                autofocus: true,
              )
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
