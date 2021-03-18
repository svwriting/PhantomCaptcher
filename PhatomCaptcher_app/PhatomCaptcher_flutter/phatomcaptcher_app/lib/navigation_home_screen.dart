import 'package:phatomcaptcher_app/app_theme.dart';
import 'package:phatomcaptcher_app/custom_drawer/drawer_user_controller.dart';
import 'package:phatomcaptcher_app/custom_drawer/home_drawer.dart';
import 'package:phatomcaptcher_app/home_screen.dart';
import 'package:phatomcaptcher_app/object_capture.dart';
import 'package:phatomcaptcher_app/check_objects.dart';
import 'package:flutter/material.dart';

class NavigationHomeScreen extends StatefulWidget {
  @override
  _NavigationHomeScreenState createState() => _NavigationHomeScreenState();
}

class _NavigationHomeScreenState extends State<NavigationHomeScreen> {
  Widget screenView;
  DrawerIndex drawerIndex;

  @override
  void initState() {
    drawerIndex = DrawerIndex.HOME;
    // screenView = const MyHomePage();
    screenView = MyHomePage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.nearlyWhite,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          backgroundColor: AppTheme.nearlyWhite,
          body: DrawerUserController(
            screenIndex: drawerIndex,
            drawerWidth: MediaQuery.of(context).size.width * 0.75,
            onDrawerCall: (DrawerIndex drawerIndexdata) {
              changeIndex(drawerIndexdata);
              //callback from drawer for replace screen as user need with passing DrawerIndex(Enum index)
            },
            screenView: screenView,
            //we replace screen view as we need on navigate starting screens like MyHomePage, HelpScreen, FeedbackScreen, etc...
          ),
        ),
      ),
    );
  }

  void changeIndex(DrawerIndex drawerIndexdata) {
    if (drawerIndex != drawerIndexdata) {
      drawerIndex = drawerIndexdata;
      // print(drawerIndex);
      if (drawerIndex == DrawerIndex.HOME) {
        setState(() {
          // screenView = const MyHomePage();
          screenView = MyHomePage();
        });
      } else if (drawerIndex == DrawerIndex.ObjectCapture) {
        setState(() {
          screenView = ObjectCapture();
        });
      } else if (drawerIndex == DrawerIndex.CheckObjects) {
        setState(() {
          screenView = CheckObjects();
        });
      } else {
        //do in your way......
      }
    }
  }
}
