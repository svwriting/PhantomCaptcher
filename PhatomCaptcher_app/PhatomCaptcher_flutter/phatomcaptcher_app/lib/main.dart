import 'dart:io';
import 'package:phatomcaptcher_app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'navigation_home_screen.dart';
import 'package:phatomcaptcher_app/login_fresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' show utf8,json;
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';


void main() async {
  runApp(MyApp());
  await SystemChrome.setPreferredOrientations(
      <DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown
      ])
      .then((_) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('BackEndUrl',
            // 'BackEndUrl in here'
            // 'https://phantomcaptcher.appspot.com/'
            'http://aa79d1b16f5f.ngrok.io/'
        );
      })
      .then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Platform.isAndroid ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.grey,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    return MaterialApp(
      title: 'Phantom Captcher Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // primarySwatch: Colors.blue,
        primarySwatch: Colors.deepPurple,
        textTheme: AppTheme.textTheme,
        platform: TargetPlatform.iOS,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // home: NavigationHomeScreen(),
        home: buildLoginFresh()
      //   home: CameraScreen()
    );
  }

  LoginFresh buildLoginFresh() {
    List<LoginFreshTypeLoginModel> listLogin = [
      LoginFreshTypeLoginModel(
          callFunction: (BuildContext _buildContext) {
            print("FACEBOOK");
            // develop what they want the facebook to do when the user clicks
          },
          logo: TypeLogo.facebook),
      LoginFreshTypeLoginModel(
          callFunction: (BuildContext _buildContext) {
            print("GOOGLE");
            // develop what they want the Google to do when the user clicks
          },
          logo: TypeLogo.google),
      LoginFreshTypeLoginModel(
          callFunction: (BuildContext _buildContext) {
            print("APPLE");
            // develop what they want the Apple to do when the user clicks
          },
          logo: TypeLogo.apple),
      LoginFreshTypeLoginModel(
          callFunction: (BuildContext _buildContext) {
            print("NORMAL");
            Navigator.of(_buildContext).push(MaterialPageRoute(
              builder: (_buildContext) => widgetLoginFreshUserAndPassword(),
            ));
          },
          logo: TypeLogo.userPassword),
    ];

    return LoginFresh(
      pathLogo: 'assets/logo.png',
      isExploreApp: true,
      functionExploreApp: () {
        // develop what they want the ExploreApp to do when the user clicks
      },
      isFooter: true,
      widgetFooter: this.widgetFooter(),
      typeLoginModel: listLogin,
      isSignUp: true,
      widgetSignUp: this.widgetLoginFreshSignUp(),
    );
  }
  Widget widgetLoginFreshUserAndPassword() {
    return LoginFreshUserAndPassword(
      callLogin: (BuildContext _context, Function isRequest, String user_id,
          String user_password) async {
          isRequest(true);
          print('-------------- function call----------------');
          var ifPass=true;
          String user_picurl ='https://www.nvda.org.tw/img/S783C.png';
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String BackEndUrl=prefs. getString('BackEndUrl');
          if(user_id==''){
            user_id='user_test';
            user_password='user_test';
          }
          print(user_id);
          print(user_password);
          if(BackEndUrl!='BackEndUrl in here'){
            var request = http.MultipartRequest(
              'POST',
              Uri.parse('${BackEndUrl}/ifPass'),
            );
            request.fields['user_id']=user_id;
            request.fields['user_password']=user_password;
            http.StreamedResponse r = await request.send();
            user_picurl = await r.stream.transform(utf8.decoder).join();
            ifPass=user_picurl != 'DECLINE';
          }else{
          }

          if(ifPass) {
            await prefs.setString('user_id', user_id);
            await prefs.setString('user_picurl', user_picurl);
            print(user_picurl);
            // Navigator.push(
            //     _context, MaterialPageRoute(
            //     builder: (context) => NavigationHomeScreen())
            // );
            Navigator.of(_context).pushAndRemoveUntil(
                new MaterialPageRoute(builder: (context) => NavigationHomeScreen()
                ), (route) => route == null);
          }else{
            Fluttertoast.showToast(
              msg: "密碼錯誤 / 帳號不存在",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
            );
          }
          print('--------------   end call   ----------------');
          isRequest(false);
      },
      logo: './assets/logo_head.png',
      isFooter: true,
      widgetFooter: this.widgetFooter(),
      isResetPassword: true,
      widgetResetPassword: this.widgetResetPassword(),
      isSignUp: true,
      signUp: this.widgetLoginFreshSignUp(),
    );
  }
  Widget widgetResetPassword() {
    return LoginFreshResetPassword(
      logo: 'assets/logo_head.png',
      funResetPassword:
          (BuildContext _context, Function isRequest, String email) {
        isRequest(true);

        Future.delayed(Duration(seconds: 2), () {
          print('-------------- function call----------------');
          print(email);
          print('--------------   end call   ----------------');
          isRequest(false);
        });
      },
      isFooter: true,
      widgetFooter: this.widgetFooter(),
    );
  }
  Widget widgetFooter() {
    return LoginFreshFooter(
      logo: 'assets/logo_footer.png',
      text: 'Power by',
      funFooterLogin: () {
        // develop what they want the footer to do when the user clicks
      },
    );
  }
  Widget widgetLoginFreshSignUp() {
    return LoginFreshSignUp(
        isFooter: true,
        widgetFooter: this.widgetFooter(),
        logo: 'assets/logo_head.png',
        funSignUp: (BuildContext _context, Function isRequest,
            SignUpModel signUpModel) async {
          isRequest(true);

          print(signUpModel.user_id);
          print(signUpModel.user_password);
          print(signUpModel.repeatPassword);
          print(signUpModel.user_pic);
          if(signUpModel.user_password!=signUpModel.user_password){
            Fluttertoast.showToast(
              msg: "密碼兩次輸入不相符",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
            );
          }else{
            String user_id = signUpModel.user_id;
            String user_password = signUpModel.user_password;
            String user_picpath = signUpModel.user_pic.path;
            var ifPass=true;
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String BackEndUrl=prefs. getString('BackEndUrl');
            var request = http.MultipartRequest(
              'POST',
              Uri.parse('${BackEndUrl}/CreateAccount'),
            );
            request.files.add(
              await http.MultipartFile.fromPath(
                'data',
                user_picpath,
                contentType: MediaType('image', 'jpg'),
              ),
            );
            request.fields['user_id']=user_id;
            request.fields['user_password']=user_password;
            http.StreamedResponse r = await request.send();
            String user_picurl = await r.stream.transform(utf8.decoder).join();
            ifPass=user_picurl != 'DECLINE';
            if(ifPass) {
              await prefs.setString('user_id', user_id);
              await prefs.setString('user_picurl', user_picurl);
              print(user_picurl);
              Navigator.of(_context).pushAndRemoveUntil(
                  new MaterialPageRoute(builder: (context) => NavigationHomeScreen()
                  ), (route) => route == null);
              Fluttertoast.showToast(
                msg: "帳號新增成功，已自動登入。",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 3
              );
            }else{
              Fluttertoast.showToast(
                msg: "密碼錯誤 / 帳號不存在",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 3
              );
            }
          }
          isRequest(false);
        });
  }
}




class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }
}