import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:numberpicker/numberpicker.dart';

List<SongInfo> musicData = [];

class MusicPage extends StatefulWidget {
  @override
  _MusicPageState createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();
  AudioPlayer audioPlayer = new AudioPlayer();
  bool isPlaying = false;
  bool isPlayerShowing = false;
  bool isLooping = false;
  bool isNextOrPrevious = false;
  PlayerState playerState;
  Duration position = Duration(milliseconds: 0);
  Duration musicLength = Duration(milliseconds: 0);
  String currentMusic;
  int selectedIndex;
  Box box;
  bool isTimerSet = false;
  int hour = 0;
  int min = 0;
  bool isTimerShowing = false;
  var searchSelectedSong;

  @override
  void initState() {
    super.initState();

    initialMusic();

    _controller = AnimationController(
      duration: Duration(milliseconds: 900),
      vsync: this,
      reverseDuration: Duration(milliseconds: 400),
    );

    _animation = new Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      curve: Curves.easeOut,
      parent: _controller,
    ))
      ..addListener(() {
        this.setState(() {
          // print("${_controller.value}");
          // print("${_animation.value}");
        });
      });

    audioPlayer.durationStream.listen((Duration d) {
      // print('Current duration: $d');

      setState(() => musicLength = d);
    });

    audioPlayer.positionStream.listen((Duration p) {
      // print('Current position: $p');
      setState(() => position = p);
    });

    audioPlayer.playerStateStream.listen((PlayerState s) {
      // print('Current player state: $s');

      setState(() {
        playerState = s;
      });
      if (playerState.processingState == ProcessingState.completed) {
        debugPrint("$position : $musicLength");
        onCompletion();
      }
    });

    Future.delayed(Duration(seconds: 1), () {
      // print("box initialized");
      box = Hive.box("music");
      // box.deleteFromDisk();

      if (box.length != 0) {
        setState(() {
          isLooping = box.get("looping");
        });
      }
    });
  }

  initialMusic() async {
    musicData = await audioQuery.getSongs();
    setState(() {
      musicData = musicData;
    });
  }

  onCompletion() async {
    // debugPrint("finished");
    if (isLooping) {
      // debugPrint("looping");
      audioPlayer.setLoopMode(LoopMode.all);
    } else {
      // debugPrint("Next");
      audioPlayer.setLoopMode(LoopMode.off);
      setState(() {
        if (musicData.length - 1 >= selectedIndex + 1) {
          currentMusic = musicData[selectedIndex + 1].uri;
          selectedIndex = selectedIndex + 1;
        } else {
          selectedIndex = 0;
          currentMusic = musicData[selectedIndex].uri;
        }
        isPlaying = true;
        isPlayerShowing = true;
        isNextOrPrevious = false;
      });
      try {
        await audioPlayer.setUrl(currentMusic,
            initialPosition: Duration(seconds: 0));
      } catch (e) {
        setState(() {
          if (musicData.length - 1 >= selectedIndex + 1) {
            currentMusic = musicData[selectedIndex + 1].uri;
            selectedIndex = selectedIndex + 1;
          } else {
            selectedIndex = 0;
            currentMusic = musicData[selectedIndex].uri;
          }
          isPlaying = true;
          isPlayerShowing = true;
          isNextOrPrevious = false;
        });
        await audioPlayer.setUrl(currentMusic,
            initialPosition: Duration(seconds: 0));
      }

      // debugPrint(musicData[selectedIndex].uri);
      await audioPlayer.play();
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _controller.dispose();
    box.close();

    super.dispose();
  }

  setTimer() {
    // var time = Duration(hours: hour, minutes: min);
    Timer(Duration(hours: hour, minutes: min), () async {
      print("STOP --------- STOP");
      if (isTimerSet) {
        await audioPlayer.stop();
      } else {
        print("Timer is not set");
      }
    });
  }

  showOption() async {
    await showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Container(
              padding: EdgeInsets.all(20.0),
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey[400],
              ),
              child: Column(
                children: [
                  Row(
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Looping",
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: GoogleFonts.aBeeZee().fontFamily,
                          fontSize: 20.0,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Checkbox(
                        // tristate: true,
                        value: isLooping,
                        onChanged: (val) {
                          box.put("looping", val);
                          modalSetState(() {
                            isLooping = box.get("looping");
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // print(musicData);
    // debugPrint(musicData[selectedIndex].filePath);
    // debugPrint(isPlaying.toString());
    // debugPrint(selectedIndex.toString());
    // debugPrint(isLooping.toString());
    // print(audioPlayer.playbackEvent);
    // print("MINUTE ---------- $min ------- MINUTE");
    // print("POSITION ---------- $position ------- POSITION");
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Music",
          style: TextStyle(
            fontFamily: GoogleFonts.aclonica().fontFamily,
            fontSize: 26.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            alignment: Alignment.center,
            iconSize: 24.0,
            onPressed: () async {
              searchSelectedSong = await showSearch(
                context: context,
                delegate: DataSearch(),
              );
              if (searchSelectedSong != null) {
                try {
                  setState(() {
                    selectedIndex = musicData.indexOf(musicData.firstWhere(
                        (element) => element.uri == searchSelectedSong));
                    currentMusic = musicData[selectedIndex].uri;
                    isPlayerShowing = true;
                    isNextOrPrevious = false;
                  });
                  if (isPlaying) {
                    await audioPlayer.stop();
                  }
                  await audioPlayer.setUrl(searchSelectedSong,
                      initialPosition: Duration(seconds: 0));
                  await audioPlayer.play();
                } catch (e) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text("Cannot play this song"),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                }
              }

              // print(selectedIndex);
              // print(musicData.firstWhere(
              //         (element) => element.uri == searchSelectedSong));
            },
            icon: FaIcon(
              FontAwesomeIcons.search,
              color: Colors.white70,
            ),
          ),
          IconButton(
            alignment: Alignment.center,
            iconSize: 24.0,
            onPressed: () {
              setState(() {
                isTimerShowing = !isTimerShowing;
                isTimerShowing
                    ? _controller.forward(from: 0)
                    : _controller.reverse(from: 1);
              });
            },
            icon: FaIcon(
              FontAwesomeIcons.solidClock,
              color: Colors.white70,
            ),
          ),
          IconButton(
            alignment: Alignment.center,
            iconSize: 24.0,
            onPressed: () {
              showOption();
            },
            icon: FaIcon(
              FontAwesomeIcons.ellipsisV,
              color: Colors.white70,
            ),
          ),
        ],
        // centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            height: _animation.value * (MediaQuery.of(context).size.height / 2),
            child: TweenAnimationBuilder(
              tween: Tween<double>(
                begin: isTimerShowing ? 5.0 : 0,
                end: isTimerShowing ? 0.0 : 5.0,
              ),
              duration: Duration(milliseconds: 1000),
              curve: Curves.decelerate,
              builder: (context, double value, _) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..translate(value * 0, -200 * value, 0),
                  alignment: Alignment.center,
                  child: Container(
                    padding: EdgeInsets.all(20.0),
                    height: _animation.value *
                        (MediaQuery.of(context).size.height / 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "Hour",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  NumberPicker(
                                    minValue: 0,
                                    maxValue: 24,
                                    value: hour,
                                    infiniteLoop: true,
                                    zeroPad: true,
                                    textStyle: TextStyle(
                                      color: Colors.black38,
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    itemCount: 5,
                                    selectedTextStyle: TextStyle(
                                      color: Colors.black,
                                      fontSize: 36.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        hour = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    "Min",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  NumberPicker(
                                    minValue: 0,
                                    maxValue: 59,
                                    value: min,
                                    infiniteLoop: true,
                                    zeroPad: true,
                                    textStyle: TextStyle(
                                      color: Colors.black38,
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    itemCount: 5,
                                    selectedTextStyle: TextStyle(
                                      color: Colors.black,
                                      fontSize: 36.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        min = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton(
                                child: Text("Cancel"),
                                onPressed: () {
                                  setState(() {
                                    isTimerSet = false;
                                    isTimerShowing = false;
                                    min = 0;
                                    isTimerShowing
                                        ? _controller.forward(from: 0)
                                        : _controller.reverse(from: 1);
                                  });
                                },
                              ),
                              ElevatedButton(
                                child: Text("Set Timer"),
                                onPressed: () {
                                  setState(() {
                                    isTimerSet = true;
                                    isTimerShowing = false;
                                    isTimerShowing
                                        ? _controller.forward(from: 0)
                                        : _controller.reverse(from: 1);
                                  });
                                  setTimer();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              clipBehavior: Clip.antiAlias,
              separatorBuilder: (context, index) {
                return Divider(
                  color: Colors.grey,
                  thickness: 0.5,
                  indent: 15.0,
                  endIndent: 15.0,
                );
              },
              physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 10.0),
                  padding: index == 0
                      ? EdgeInsets.only(top: 10.0)
                      : index == musicData.length - 1
                          ? EdgeInsets.only(bottom: 10.0)
                          : null,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: InkWell(
                    overlayColor:
                        MaterialStateProperty.all<Color>(Colors.grey[300]),
                    onTap: () async {
                      if (isPlaying) {
                        await audioPlayer.stop();
                      }
                      setState(() {
                        selectedIndex = index;
                        currentMusic = musicData[index].uri;
                        isPlayerShowing = true;
                        isNextOrPrevious = false;
                      });
                      try {
                        await audioPlayer.setUrl(musicData[index].uri,
                            initialPosition: Duration(seconds: 0));
                      } catch (e) {
                        setState(() {
                          musicData.length - 1 >= selectedIndex + 1
                              ? selectedIndex = index + 1
                              : selectedIndex = index - 1;
                          musicData.length - 1 >= selectedIndex + 1
                              ? currentMusic = musicData[index + 1].uri
                              : currentMusic = musicData[index - 1].uri;
                          isPlayerShowing = true;
                          isNextOrPrevious = false;
                        });
                        await audioPlayer.setUrl(musicData[selectedIndex].uri,
                            initialPosition: Duration(seconds: 0));
                      }
                      await audioPlayer.play();
                    },
                    splashColor: Colors.black12,
                    autofocus: true,
                    borderRadius: BorderRadius.circular(20.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: musicData[index].albumArtwork == null
                            ? AssetImage('assets/images/music_player.jpg')
                            : FileImage(
                                File(musicData[index].albumArtwork),
                              ),
                        radius: 30,
                      ),
                      title: Text(
                        musicData[index].title,
                        style: TextStyle(
                          // color: Colors.black,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                          fontFamily: GoogleFonts.merienda().fontFamily,
                        ),
                      ),
                      subtitle: Text(musicData[index].artist),
                      selected: selectedIndex == index,
                      selectedTileColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                );
              },
              itemCount: musicData.length,
            ),
          ),
          isPlayerShowing
              ? TweenAnimationBuilder(
                  tween: Tween<double>(
                    begin: 1.0,
                    end: 0.0,
                  ),
                  duration: Duration(milliseconds: 500),
                  curve: Curves.decelerate,
                  builder: (context, double value, _) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateZ((-pi / 2) * value),
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: Colors.grey[800],
                        ),
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    musicData[selectedIndex].title,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w600,
                                      fontFamily:
                                          GoogleFonts.actor().fontFamily,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  color: Colors.transparent,
                                  alignment: Alignment.center,
                                  iconSize: 30.0,
                                  icon: Icon(
                                    Icons.cancel,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () async {
                                    await audioPlayer.stop();

                                    setState(() {
                                      isPlayerShowing = false;
                                      // isPlaying = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                            Container(
                              width: 500.0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    position.inMinutes
                                            .toString()
                                            .padLeft(2, "0") +
                                        ":" +
                                        position.inSeconds
                                            .remainder(60)
                                            .toString()
                                            .padLeft(2, "0"),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: 300.0,
                                      child: Slider.adaptive(
                                        activeColor: Colors.blue[800],
                                        inactiveColor: Colors.grey[350],
                                        value: position !=
                                                Duration(milliseconds: 0)
                                            ? position.inMilliseconds.toDouble()
                                            : Duration.zero.inMilliseconds
                                                .toDouble(),
                                        max: musicLength !=
                                                Duration(milliseconds: 0)
                                            ? musicLength.inMilliseconds
                                                .toDouble()
                                            : Duration.zero.inMilliseconds
                                                .toDouble(),
                                        onChanged: (value) {
                                          setState(() {
                                            Duration newPos = Duration(
                                                milliseconds: value.toInt());
                                            audioPlayer.seek(newPos);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  Text(
                                    musicLength.inMinutes
                                            .toString()
                                            .padLeft(2, "0") +
                                        ":" +
                                        musicLength.inSeconds
                                            .remainder(60)
                                            .toString()
                                            .padLeft(2, "0"),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  iconSize: 45.0,
                                  color: Colors.blue,
                                  onPressed: () async {
                                    await audioPlayer.stop();
                                    setState(() {
                                      0 == selectedIndex
                                          ? currentMusic =
                                              musicData[selectedIndex].uri
                                          : currentMusic =
                                              musicData[selectedIndex - 1].uri;
                                      0 == selectedIndex
                                          ? selectedIndex = selectedIndex
                                          : selectedIndex = selectedIndex - 1;
                                      isNextOrPrevious = true;
                                    });
                                    try {
                                      await audioPlayer.setUrl(currentMusic,
                                          initialPosition:
                                              Duration(seconds: 0));
                                    } catch (e) {
                                      setState(() {
                                        0 == selectedIndex
                                            ? currentMusic =
                                                musicData[selectedIndex].uri
                                            : currentMusic =
                                                musicData[selectedIndex - 1]
                                                    .uri;
                                        0 == selectedIndex
                                            ? selectedIndex = selectedIndex
                                            : selectedIndex = selectedIndex - 1;
                                        isNextOrPrevious = true;
                                      });
                                      await audioPlayer.setUrl(currentMusic,
                                          initialPosition:
                                              Duration(seconds: 0));
                                    }

                                    await audioPlayer.play();
                                  },
                                  icon: Icon(
                                    Icons.skip_previous,
                                  ),
                                ),
                                IconButton(
                                  iconSize: 62.0,
                                  color: Colors.blue[800],
                                  onPressed: () async {
                                    if (!playerState.playing) {
                                      // debugPrint(currentMusic);
                                      await audioPlayer.play();
                                    } else {
                                      await audioPlayer.pause();
                                    }
                                  },
                                  icon: Icon(
                                    !playerState.playing
                                        ? Icons.play_arrow
                                        : Icons.pause,
                                  ),
                                ),
                                IconButton(
                                  iconSize: 45.0,
                                  color: Colors.blue,
                                  onPressed: () async {
                                    await audioPlayer.stop();
                                    setState(() {
                                      musicData.length - 1 >= selectedIndex + 1
                                          ? currentMusic =
                                              musicData[selectedIndex + 1].uri
                                          : currentMusic =
                                              musicData[selectedIndex].uri;
                                      musicData.length - 1 >= selectedIndex + 1
                                          ? selectedIndex = selectedIndex + 1
                                          : selectedIndex = selectedIndex;
                                      isNextOrPrevious = true;
                                    });
                                    try {
                                      await audioPlayer.setUrl(currentMusic,
                                          initialPosition:
                                              Duration(seconds: 0));
                                    } catch (e) {
                                      setState(() {
                                        musicData.length - 1 >=
                                                selectedIndex + 1
                                            ? currentMusic =
                                                musicData[selectedIndex + 1].uri
                                            : currentMusic =
                                                musicData[selectedIndex].uri;
                                        musicData.length - 1 >=
                                                selectedIndex + 1
                                            ? selectedIndex = selectedIndex + 1
                                            : selectedIndex = selectedIndex;
                                        isNextOrPrevious = true;
                                      });
                                      await audioPlayer.setUrl(currentMusic,
                                          initialPosition:
                                              Duration(seconds: 0));
                                    }
                                    await audioPlayer.play();
                                  },
                                  icon: Icon(
                                    Icons.skip_next,
                                  ),
                                ),
                                playerState.processingState !=
                                        ProcessingState.buffering
                                    ? Container()
                                    : Center(
                                        child: SpinKitFadingCircle(
                                          color: Colors.blue,
                                          size: 20.0,
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Container(),
        ],
      ),
    );
  }
}

class DataSearch extends SearchDelegate {
  final musicList = musicData;
  // final suggestionsList ;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = "";
          })
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: AnimatedIcon(
          icon: AnimatedIcons.menu_arrow,
          progress: transitionAnimation,
        ),
        onPressed: () {
          close(context, null);
        });
  }

  @override
  Widget buildResults(BuildContext context) {
    final songInfo = query.isNotEmpty
        ? musicList
            .where((element) =>
                element.title.toLowerCase().contains(query.toLowerCase()) ||
                element.title.toLowerCase().startsWith(query.toLowerCase()))
            .toList()
        : null;

    return songInfo != null
        ? ListView.separated(
            clipBehavior: Clip.antiAlias,
            separatorBuilder: (context, index) {
              return Divider(
                color: Colors.grey,
                thickness: 0.5,
                indent: 15.0,
                endIndent: 15.0,
              );
            },
            physics:
                BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            itemBuilder: (context, index) => ListTile(
              leading: Icon(Icons.music_note_rounded),
              title: Text(songInfo[index].title),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              subtitle: Text(songInfo[index].artist),
              onTap: () {
                close(context, songInfo[index].uri);
              },
            ),
            itemCount: songInfo.length,
          )
        : Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final songInfo = query.isNotEmpty
        ? musicList
            .where((element) =>
                element.title.toLowerCase().contains(query.toLowerCase()) ||
                element.title.toLowerCase().startsWith(query.toLowerCase()))
            .toList()
        : null;

    return songInfo != null
        ? ListView.separated(
            clipBehavior: Clip.antiAlias,
            separatorBuilder: (context, index) {
              return Divider(
                color: Colors.grey,
                thickness: 0.5,
                indent: 15.0,
                endIndent: 15.0,
              );
            },
            physics:
                BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            itemBuilder: (context, index) => ListTile(
              leading: Icon(Icons.music_note_rounded),
              title: Text(songInfo[index].title),
              subtitle: Text(songInfo[index].artist),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              onTap: () {
                close(context, songInfo[index].uri);
              },
            ),
            itemCount: songInfo.length,
          )
        : Container();
  }
}
