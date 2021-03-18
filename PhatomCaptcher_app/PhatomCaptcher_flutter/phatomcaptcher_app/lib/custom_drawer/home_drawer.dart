import 'package:phatomcaptcher_app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:phatomcaptcher_app/login_fresh.dart';
import 'package:phatomcaptcher_app/navigation_home_screen.dart';
import 'package:phatomcaptcher_app/main.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' show utf8;
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';


class HomeDrawer extends StatefulWidget {
  const HomeDrawer({Key key, this.screenIndex, this.iconAnimationController, this.callBackIndex}) : super(key: key);

  final AnimationController iconAnimationController;
  final DrawerIndex screenIndex;
  final Function(DrawerIndex) callBackIndex;

  @override
  _HomeDrawerState createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  List<DrawerList> drawerList;
  String user_id='default';
  String user_picurl='https://storage.googleapis.com/phantomcaptcher_bucket/user_pic/userpic_default.png';

  @override
  void initState() {
    setUserInfo();
    setDrawerListArray();
    super.initState();
  }

  Future<void> setUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    user_id=prefs. getString('user_id');
    user_picurl=prefs. getString('user_picurl');
  }
  void setDrawerListArray() {
    drawerList = <DrawerList>[
      DrawerList(
        index: DrawerIndex.HOME,
        labelName: 'Home',
        icon: Icon(Icons.home),
      ),
      DrawerList(
        index: DrawerIndex.ObjectCapture,
        labelName: 'Object Capture',
        isAssetsImage: true,
        imageName: 'assets/images/target.png',
      ),
      DrawerList(
        index: DrawerIndex.CheckObjects,
        labelName: 'Check Objects',
        isAssetsImage: true,
        imageName: 'assets/images/storage.png',
      ),
      // DrawerList(
      //   index: DrawerIndex.Help,
      //   labelName: 'Help',
      //   isAssetsImage: true,
      //   imageName: 'assets/images/supportIcon.png',
      // ),
      // DrawerList(
      //   index: DrawerIndex.FeedBack,
      //   labelName: 'FeedBack',
      //   icon: Icon(Icons.help),
      // ),
      // DrawerList(
      //   index: DrawerIndex.Invite,
      //   labelName: 'Invite Friend',
      //   icon: Icon(Icons.group),
      // ),
      // DrawerList(
      //   index: DrawerIndex.Share,
      //   labelName: 'Rate the app',
      //   icon: Icon(Icons.share),
      // ),
      // DrawerList(
      //   index: DrawerIndex.About,
      //   labelName: 'About Us',
      //   icon: Icon(Icons.info),
      // ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.notWhite.withOpacity(0.5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: widget.iconAnimationController,
                    builder: (BuildContext context, Widget child) {
                      return ScaleTransition(
                        scale: AlwaysStoppedAnimation<double>(1.0 - (widget.iconAnimationController.value) * 0.2),
                        child: RotationTransition(
                          turns: AlwaysStoppedAnimation<double>(Tween<double>(begin: 0.0, end: 24.0)
                                  .animate(CurvedAnimation(parent: widget.iconAnimationController, curve: Curves.fastOutSlowIn))
                                  .value /
                              360),
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(color: AppTheme.grey.withOpacity(0.6), offset: const Offset(2.0, 4.0), blurRadius: 8),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(60.0)),
                              // child: Image.asset('assets/images/userImage.png'),
                              child: Image.network(user_picurl),
                              // child: Image.network('https://www.nvda.org.tw/img/S783C.png'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      user_id,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.grey,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Divider(
            height: 1,
            color: AppTheme.grey.withOpacity(0.6),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(0.0),
              itemCount: drawerList.length,
              itemBuilder: (BuildContext context, int index) {
                return inkwell(drawerList[index]);
              },
            ),
          ),
          Divider(
            height: 1,
            color: AppTheme.grey.withOpacity(0.6),
          ),
          Column(
            children: <Widget>[
              ListTile(
                title: Text(
                  'Sign Out',
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.darkText,
                  ),
                  textAlign: TextAlign.left,
                ),
                trailing: Icon(
                  Icons.power_settings_new,
                  color: Colors.red,
                ),
                onTap: () {
                  // RestartWidget.restartApp(widget.context);

                  Navigator.of(context).pushAndRemoveUntil(
                      new MaterialPageRoute(
                          builder: (context) => buildLoginFresh()
                      ), (route) => route == null);
                },
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              )
            ],
          ),
        ],
      ),
    );
  }
  Widget inkwell(DrawerList listData) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.grey.withOpacity(0.1),
        highlightColor: Colors.transparent,
        onTap: () {
          navigationtoScreen(listData.index);
        },
        child: Stack(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 6.0,
                    height: 46.0,
                    decoration: BoxDecoration(
                      color: widget.screenIndex == listData.index
                          ? Colors.blue
                          : Colors.transparent,
                      borderRadius: new BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(4.0),
                  ),
                  listData.isAssetsImage
                      ? Container(
                          width: 24,
                          height: 24,
                          child: Image.asset(listData.imageName, color: widget.screenIndex == listData.index ? Colors.blue : AppTheme.nearlyBlack),
                        )
                      : Icon(listData.icon.icon, color: widget.screenIndex == listData.index ? Colors.blue : AppTheme.nearlyBlack),
                  const Padding(
                    padding: EdgeInsets.all(4.0),
                  ),
                  Text(
                    listData.labelName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: widget.screenIndex == listData.index ? Colors.blue : AppTheme.nearlyBlack,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            widget.screenIndex == listData.index
                ? AnimatedBuilder(
                    animation: widget.iconAnimationController,
                    builder: (BuildContext context, Widget child) {
                      return Transform(
                        transform: Matrix4.translationValues(
                            (MediaQuery.of(context).size.width * 0.75 - 64) * (1.0 - widget.iconAnimationController.value - 1.0), 0.0, 0.0),
                        child: Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.75 - 64,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: new BorderRadius.only(
                                topLeft: Radius.circular(0),
                                topRight: Radius.circular(28),
                                bottomLeft: Radius.circular(0),
                                bottomRight: Radius.circular(28),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const SizedBox()
          ],
        ),
      ),
    );
  }
  Future<void> navigationtoScreen(DrawerIndex indexScreen) async {
    widget.callBackIndex(indexScreen);
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

enum DrawerIndex {
  HOME,
  ObjectCapture,
  CheckObjects,
  // FeedBack,
  // Help,
  // Share,
  // About,
  // Invite,
  // Testing,
}

class DrawerList {
  DrawerList({
    this.isAssetsImage = false,
    this.labelName = '',
    this.icon,
    this.index,
    this.imageName = '',
  });

  String labelName;
  Icon icon;
  bool isAssetsImage;
  String imageName;
  DrawerIndex index;
}
