import 'dart:io';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:music/music_page.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Directory documentDirectory = await getApplicationDocumentsDirectory();
  // debugPrint(documentDirectory.path);
  Hive.init(documentDirectory.path);
  // await Hive.initFlutter();
  await Hive.openBox("music");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.lato().fontFamily,
      ),
      home: AnimatedSplashScreen(
        splash: Container(
          alignment: Alignment.center,
          child: ClipRRect(
            child: Image.asset(
              "assets/images/music_player.jpg",
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        nextScreen: MusicPage(),
        animationDuration: Duration(seconds: 2),
        backgroundColor: Colors.white,
        duration: 1000,
        curve: Curves.bounceOut,
        splashIconSize: 250,
        centered: true,
        splashTransition: SplashTransition.fadeTransition,
      ),
      // home: MusicPage(),
    );
  }
}
