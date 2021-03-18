import 'package:phatomcaptcher_app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:collection/collection.dart';
import 'dart:convert' show utf8;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phatomcaptcher_app/main.dart';
import 'package:photo_view/photo_view.dart';
import 'package:loading_animations/loading_animations.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';


class ObjectCapture extends StatefulWidget {
  @override
  _InviteFriendState createState() => _InviteFriendState();
}

class _InviteFriendState extends State<ObjectCapture> {

  bool _saving = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        child: Container(
        color: AppTheme.nearlyWhite,
        child: SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: AppTheme.nearlyWhite,
            body: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      left: 16,
                      right: 16),
                  child: Image.asset('assets/images/ObjectCaptureImage.png'),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Object Capture',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  child: const Text(
                    '對準物件 然後拍照\n即可捕捉去背物件',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 40,
                        decoration: BoxDecoration(
                          // color: Colors.blue,
                          color: Colors.black,
                          borderRadius:
                          const BorderRadius.all(Radius.circular(4.0)),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.6),
                                offset: const Offset(4, 4),
                                blurRadius: 8.0),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              doObjectCapture();
                            },
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    Icons.camera,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(
                                      '開始拍照',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
        inAsyncCall: _saving,
        progressIndicator: LoadingBouncingGrid.square(
          size: 150,
          backgroundColor: Colors.black45,
          inverted: true,
        ),
      ),
    );
  }

  Future<Image> doObjectCapture() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String BackEndUrl=prefs. getString('BackEndUrl');
    if(BackEndUrl!='BackEndUrl in here'){
      final photo = await ImagePicker().getImage(source: ImageSource.camera);

      setState(() {
        _saving = true;
      });

      // File imgfile=File(photo.path);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${BackEndUrl}/ObjectCaptureProcess'),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'data',
          photo.path,
          contentType: MediaType('image', 'jpg'),
        ),
      );
      String user_id=prefs. getString('user_id');
      request.fields['user_id']=user_id;
      http.StreamedResponse r = await request.send();
      String imgurl=await r.stream.transform(utf8.decoder).join();

      print(r.statusCode);
      print(imgurl);

      Navigator.push(
          context, MaterialPageRoute(
          builder: (context) => PhotoView(
            imageProvider:
            NetworkImage(imgurl),
            backgroundDecoration: BoxDecoration(color: Colors.white38),
          )
        )
      );



      setState(() {
        _saving = false;
      });

    }
    else{
      // Navigator.of(context).pushAndRemoveUntil(
      //     new MaterialPageRoute(builder: (context) => buildLoginFresh()
      //     ), (route) => route == null);
    }
  }
}
