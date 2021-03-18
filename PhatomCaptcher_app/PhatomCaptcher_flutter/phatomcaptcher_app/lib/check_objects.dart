import 'dart:io';
import 'dart:typed_data';
import 'dart:convert' show utf8,json;
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:phatomcaptcher_app/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'dart:async';
import 'package:loading_animations/loading_animations.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';


const int Trigger = 1;
const int Cancle = 2;
const int SelectAll = 3;
const int Delete = 4;
const int CurrentState = 5;
typedef OnActionFinished = int Function(List<int> indexes); // 进行数据清除工作，并返回当前list的length
typedef OnItemSelectedChanged = void Function(int index, bool isSelected); // 选中状态回调
typedef OnItemBuild = void Function(Size size);
typedef ResultCallBack = bool Function();
typedef IndexCallBack = void Function(int index);


class CustomAnimateGrid extends StatefulWidget {
  final SliverGridDelegate delegate;
  final IndexedWidgetBuilder itemBuilder;
  final Function onActionCancled;
  final OnActionFinished onActionFinished;
  final IndexCallBack onItemPressed;
  final IndexCallBack onDragStart;
  final IndexCallBack onDragEnd;
  int itemCount;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController controller;
  final bool primary;
  final ScrollPhysics physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;
  final Map<int, Function> actionToken;

  CustomAnimateGrid({
    Key key,
    @required this.delegate,
    @required this.itemCount,
    @required this.itemBuilder,
    @required this.onActionCancled,
    @required this.onActionFinished,
    @required this.actionToken,
    this.onItemPressed,
    this.onDragStart,
    this.onDragEnd,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CustomAnimateGridState();
  }
}
class _CustomAnimateGridState extends State<CustomAnimateGrid>with TickerProviderStateMixin {
  final List<int> selectedItems = []; // 被选中的item的index集合
  final List<int> remainsItems = []; // 删除后将会保留的item的index集合

  Size _itemSize;

  StateSetter _deleteSheetState;

  AnimationController _slideController;
  AnimationController _deleteSheetController;
  Animation<Offset> _deleteSheetAnimation;

  int _oldItemCount;

  bool _needToAnimate = false; // 是否需要进行平移动画
  bool _readyToDelete = false; // 是否是删除状态
  bool _singleDelete = false; // 是否是单独删除状态，长按item触发

  bool _canAccept = false; // 长按删除时，是否移动到了指定位置

  @override
  void initState() {
    super.initState();
    initActionTokenes();
    _slideController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    _deleteSheetController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 150));
    _deleteSheetAnimation =
        Tween(begin: Offset(0.0, 1.0), end: Offset(0.0, 0.0)).animate(
            CurvedAnimation(
                parent: _deleteSheetController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    super.dispose();
    widget.actionToken.clear();
    _slideController.dispose();
    _deleteSheetController.dispose();
  }

  void initActionTokenes() {
    if (!widget.actionToken.containsKey(Trigger)) {
      widget.actionToken[Trigger] = triggerDeleteAction;
    }
    if (!widget.actionToken.containsKey(Cancle)) {
      widget.actionToken[Cancle] = cancleDeleteAction;
    }
    if (!widget.actionToken.containsKey(SelectAll)) {
      widget.actionToken[SelectAll] = selectAllItems;
    }
    if (!widget.actionToken.containsKey(Delete)) {
      widget.actionToken[Delete] = doDeleteAction;
    }
    if (!widget.actionToken.containsKey(CurrentState)) {
      widget.actionToken[CurrentState] = getCurrentState;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Stack(
          children: <Widget>[
            GridView.builder(
                gridDelegate: widget.delegate,
                itemCount: widget.itemCount,
                scrollDirection: widget.scrollDirection,
                reverse: widget.reverse,
                controller: widget.controller,
                primary: widget.primary,
                physics: (widget.physics != null
                    ? widget.physics
                    : BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics())),
                shrinkWrap: widget.shrinkWrap,
                padding: widget.padding,
                itemBuilder: (context, index) {
                  bool isSelected = selectedItems.contains(index);

                  // Animation<Offset> slideAnimation;
                  // 需要动画时，添加一个位移动画
                  // if (_needToAnimate) {
                  //   slideAnimation = createTargetItemSlideAnimation(index);
                  // }
                  return _GridItem(
                    index,
                    _readyToDelete,
                    widget.itemBuilder(context, index),
                    onItemSelected,
                    widget.onItemPressed,
                    widget.onDragStart,
                    widget.onDragEnd,
                    triggerSingleDelete,
                    cancleSingleDelete,
                    isSelected,
                    // slideAnimation,
                    onItemBuild: itemBuildCallBack,
                  );
                }),
            // StatefulBuilder(
            //   builder: (context, state) {
            //     _deleteSheetState = state;
            //     return Offstage(
            //       offstage: !_singleDelete,
            //       child: Align(
            //         alignment: Alignment.bottomCenter,
            //         child: SlideTransition(
            //           position: _deleteSheetAnimation,
            //           child: DragTarget<int>(onWillAccept: (data) {
            //             _canAccept = true;
            //             return data != null; // dada不是null的时候,接收该数据。
            //           },
            //               onAccept: (data) {
            //             selectedItems.add(data);
            //             doSingleDelete(data);
            //           },
            //               onLeave: (data) {
            //             _canAccept = false;
            //           },
            //               builder: (context, candidateData, rejectedData) {
            //             return SizedBox(
            //               width: MediaQuery.of(context).size.width,
            //               height: 64.0,
            //               child: Material(
            //                 // color: Colors.black54,
            //                 color: Colors.black12,
            //                 child: Center(
            //                   child: Icon(
            //                     Icons.delete_forever,
            //                     // color: Colors.red,
            //                     color: Colors.black,
            //                   ),
            //                 ),
            //               ),
            //             );
            //           }),
            //         ),
            //       ),
            //     );
            //   },
            // )
          ],
        ),
        onWillPop: onBackPressed);
  }

  // 拦截返回按键
  Future<bool> onBackPressed() async {
    if (_readyToDelete) {
      cancleDeleteAction();
      return false;
    }
    return true;
  }

  // 首次触发时，计算item所占空间的大小，用于计算位移动画的位置
  void itemBuildCallBack(Size size) {
    if (_itemSize == null) {
      _itemSize = size;
    }
  }

  // Item选中状态回调 --- 将其从选中item的list中添加或删除
  void onItemSelected(int index, bool isSelected) {
    if (isSelected) {
      selectedItems.add(index);
    } else {
      selectedItems.remove(index);
    }
  }

  // 长按Item触发底部删除条状态回调
  void triggerSingleDelete() {
    _deleteSheetState(() {
      _singleDelete = true;
      _deleteSheetController.forward();
    });
  }

  // 未移动至底部删除条，取消单独删除状态
  bool cancleSingleDelete() {
    // 未移动到指定位置时，隐藏底部删除栏，并刷新item状态 --- 移动到指定位置时，只修改item的状态，不刷新布局
    if (!_canAccept) {
      _deleteSheetController.reverse().whenComplete(() {
        // _deleteSheetState(() {
        //   _canAccept = false;
        //   _singleDelete = false;
        // });
      });
    }
    return _canAccept;
  }

  // 移动至底部删除条，删除item，然后取消状态单独删除状态
  List doSingleDelete(int index) {
    _deleteSheetController.reverse().whenComplete(() {
      _deleteSheetState(() {
        _canAccept = false;
        _singleDelete = false;
        selectedItems.add(index);
      });
      doDeleteAction();
    });
    return [index];
  }

  // 1.触发删除状态，刷新布局，显示可选择的checkbox
  void triggerDeleteAction() {
    setState(() {
      _readyToDelete = true;
    });
  }
  // 2.取消删除状态，刷新布局
  void cancleDeleteAction() {
    setState(() {
      _readyToDelete = false;
      selectedItems.clear();
      widget.onActionCancled();
    });
  }
  // 3.将所有item设置为被选中状态
  void selectAllItems() {
    setState(() {
      if (selectedItems.length != widget.itemCount) {
        selectedItems.clear();
        for (int i = 0; i < widget.itemCount; i++) {
          selectedItems.add(i);
        }
      } else {
        selectedItems.clear();
      }
    });
  }
  // 4.删除Item，执行动画，完成后重绘界面
  List doDeleteAction() {
    var selectedItems_=selectedItems;
    _readyToDelete = false;
    if (selectedItems.length == 0 || selectedItems.length == widget.itemCount) {
      // 未选中ite或选中了所有item --- 删除item，然后刷新布局，无动画效果
      setState(() {
        widget.itemCount =
            widget.onActionFinished(selectedItems.reversed.toList());
        selectedItems.clear();
      });
    } else {
      // 选中部分item --- 计算需要动画的item，刷新item布局，加入动画控件，然后统一执行动画，结束后刷新布局
      getRemainsItemsList();
      setState(() {
        _needToAnimate = true;
        widget.itemCount =
            widget.onActionFinished(selectedItems.reversed.toList());
      });
      _slideController.forward().whenComplete(() {
        setState(() {
          _slideController.value = 0.0;
          _needToAnimate = false;
          selectedItems.clear();
          remainsItems.clear();
        });
      });
    }
    return selectedItems_;
  }
  // 5.
  bool getCurrentState() {
    return _readyToDelete;
  }

  // 获取将会保留的item的index集合
  void getRemainsItemsList() {
    _oldItemCount = widget.itemCount;
    for (int i = 0; i < _oldItemCount; i++) {
      if (selectedItems.contains(i)) {
        continue;
      }
      remainsItems.add(i);
    }
  }

  // 创建指定item的位移动画
  Animation<Offset> createTargetItemSlideAnimation(int index) {
    int startIndex = remainsItems[index];
    if (startIndex != index) {
      Tween<Offset> tween = Tween(
          begin: getTargetOffset(remainsItems[index], index),
          end: Offset(0.0, 0.0));
      return tween.animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    }
    return null;
  }
  // 返回动画的位置
  Offset getTargetOffset(int startIndex, int endIndex) {
    SliverGridDelegateWithFixedCrossAxisCount delegate = widget.delegate;
    int horizionalSeparation = (startIndex % delegate.crossAxisCount) -
        (endIndex % delegate.crossAxisCount);
    int verticalSeparation = (startIndex ~/ delegate.crossAxisCount) -
        (endIndex ~/ delegate.crossAxisCount);

    double dx = (delegate.crossAxisSpacing + _itemSize.width) *
        horizionalSeparation /
        _itemSize.width;
    double dy = (delegate.mainAxisSpacing + _itemSize.height) *
        verticalSeparation /
        _itemSize.width;

    return Offset(dx, dy);
  }
}

class _GridItem extends StatefulWidget {
  final int index;

  final bool readyToDelete;

  final Widget child;

  final OnItemSelectedChanged onItemSelectedChanged;

  final IndexCallBack onItemPressed;
  final IndexCallBack onDragStart;
  final IndexCallBack onDragEnd;

  final Function singleDeleteStart;
  final ResultCallBack singleDeleteCancle;

  // final Animation<Offset> slideAnimation;

  final OnItemBuild onItemBuild;

  _GridItemState _state;

  bool _isSelected;

  _GridItem(
      this.index,
      this.readyToDelete,
      this.child,
      this.onItemSelectedChanged,
      this.onItemPressed,
      this.onDragStart,
      this.onDragEnd,
      this.singleDeleteStart,
      this.singleDeleteCancle,
      this._isSelected,
      // this.slideAnimation,
      {this.onItemBuild});

  @override
  State<StatefulWidget> createState() {
    _state = _GridItemState();
    return _state;
  }
}
class _GridItemState extends State<_GridItem> with TickerProviderStateMixin {
  Size _size;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // 获取当前控件的size属性,当渲染完成之后，自动回调,无需unregist
    WidgetsBinding.instance.addPostFrameCallback(onAfterRender);
  }

  @override
  void didUpdateWidget(_GridItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 获取当前控件的size属性,当渲染完成之后，自动回调,无需unregist
    WidgetsBinding.instance.addPostFrameCallback(onAfterRender);
  }
  void onAfterRender(Duration timeStamp) {
    _size = context.size;
    widget.onItemBuild(_size);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: buildItem(context),
      onTap: () {
        // 未触发删除状态时，可以调用传入的点击回调参数
        if (!widget.readyToDelete) {
          widget.onItemPressed(widget.index);
          // print('flag1');
        }else{
          // print('flag2');
        }
      },
    );
  }
  Widget buildItem(BuildContext context) {
    return (widget.readyToDelete
        ? Stack(
      children: <Widget>[
        widget.child,
        Align(
          alignment: Alignment.topRight,
          child: StatefulBuilder(builder: (context, state) {
            return Checkbox(
                value: widget._isSelected,
                onChanged: (isSelected) {
                  state(() {
                    widget._isSelected = isSelected;
                    widget.onItemSelectedChanged(
                        widget.index, isSelected);
                  });
                });
          }),
        )
      ],
    )
        : LongPressDraggable<int>(
      data: widget.index,
      child: (_isDragging
          ? Material(
        color: Colors.transparent,
      )
          : buildItemChild()),
      feedback: StatefulBuilder(builder: (context, state) {
        return SizedBox.fromSize(size: _size, child: widget.child);
      }),
      onDragStarted: () {
        setState(() {
          widget.onDragStart(widget.index);
          // _isDragging = true;
          // widget.singleDeleteStart();
        });
      },
      onDragEnd: (details) {
        widget.onDragEnd(widget.index);
        // if (widget.singleDeleteCancle()) {
        //   _isDragging = false;
        // } else {
        //   setState(() {
        //     _isDragging = false;
        //   });
        // }
      },
      onDraggableCanceled: (velocity, offset) {
        setState(() {
          _isDragging = false;
          widget.singleDeleteCancle();
        });
      },
    ));
  }
  // 若动画不为空，则添加动画控件
  Widget buildItemChild() {
    // if (widget.slideAnimation != null) {
    //   return SlideTransition(
    //     position: widget.slideAnimation,
    //     child: widget.child,
    //   );
    // }
    return widget.child;
  }
}

class CheckObjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return
      _CheckObjects();
  }
}
class _CheckObjects extends StatelessWidget {

  List imgObjects = [
    // 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRex2zxzwUFVdclMBYRu0c6hAciP1lc8rKUlw&usqp=CAU',
    // 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRex2zxzwUFVdclMBYRu0c6hAciP1lc8rKUlw&usqp=CAU',
    // 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRex2zxzwUFVdclMBYRu0c6hAciP1lc8rKUlw&usqp=CAU',
    // 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRex2zxzwUFVdclMBYRu0c6hAciP1lc8rKUlw&usqp=CAU',
    // 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRex2zxzwUFVdclMBYRu0c6hAciP1lc8rKUlw&usqp=CAU',
  ];

  StateSetter _actionState;
  final Map<int, Function> map = {}; // 这部分需要的方法调用也可以用GlobalKey去做。

  @override
  Widget build(BuildContext context) {
    return
      FutureBuilder<List<String>>(
        future: getUserImgs(),
        // future: fetchGalleryData(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return
              Scaffold(
                backgroundColor: Colors.white,
                appBar:
                  AppBar(
                  centerTitle: true,
                  title:
                    Text(
                      "Object List",
                      style:TextStyle(color: Colors.black87)
                    ),
                  backgroundColor: Colors.white,
                  actions: <Widget>[
                    StatefulBuilder(builder: (context, state) {
                      _actionState = state;
                      if (map[CurrentState]()) {
                        return Row(
                          children: <Widget>[
                            IconButton(
                                icon: Icon(
                                  Icons.done_all,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  map[SelectAll]();
                                }),
                            IconButton(
                                icon: Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                    List list_=map[Delete]();
                                    if(list_.length>0){
                                      SharedPreferences prefs = await SharedPreferences.getInstance();
                                      String BackEndUrl=prefs. getString('BackEndUrl');
                                      for(int i=list_.length-1;i>=0;i--){
                                        var request = http.MultipartRequest(
                                          'POST',
                                          Uri.parse('${BackEndUrl}/delImgBySnap'),
                                        );
                                        String img_snap=imgObjects[list_[i]];

                                        imgObjects.removeAt(list_[i]);

                                        request.fields['img_snap']=img_snap;
                                        http.StreamedResponse r = await request.send();
                                        if (r.statusCode == 200) {
                                          print(await r.stream.transform(utf8.decoder).join());
                                        }else {
                                          print('Failed to load');
                                          throw Exception('Failed to load');
                                        }
                                      }
                                    }
                                }
                            )
                          ],
                        );
                      }
                      return IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            state(() {
                              map[Trigger]();
                            });
                          });
                    }),
                  ],
                ),
                body:
                  CustomAnimateGrid(
                    actionToken: map,
                    delegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 1.0,
                    ),
                    padding: EdgeInsets.all(8.0),
                    itemCount: snapshot.data.length,
                    itemBuilder: (BuildContext context, int index) {
                      imgObjects.add(snapshot.data[index]);
                      return Material(
                        elevation: 2.0,
                        borderRadius: BorderRadius.all(Radius.circular(2.0)),
                        child: Center(
                          child:
                          Container(
                              decoration: new BoxDecoration(
                                  image: new DecorationImage(
                                      image: new NetworkImage(
                                          snapshot.data[index]),
                                      fit: BoxFit.cover
                                  )
                              )
                          ),
                        ),
                      );
                    },
                    onActionCancled: (){
                      print(777);
                      _actionState((){});
                    },
                    onActionFinished: (indexes) {
                      print(888);
                      _actionState((){});
                      indexes.forEach((index) {
                        snapshot.data.removeAt(index);
                      });
                      return snapshot.data.length;
                    },
                    onItemPressed: (index) {
                      _actionState((){});
                      print('Pressed');
                      print(imgObjects[index]);
                      Navigator.push(
                          context, MaterialPageRoute(
                          builder: (context) => CameraScreen(objectUrl:imgObjects[index]))
                      );
                    },
                    onDragStart: (index) {
                      _actionState((){});
                      print('DragStart');
                      print(imgObjects[index]);
                    },onDragEnd: (index) {
                      _actionState((){});
                      print('DragEnd');
                      print(imgObjects[index]);
                    },
                  ),
              );
          }
          return Center(child: CircularProgressIndicator());
        }
    );
  }
}

Future<List<String>> getUserImgs() async {
  //-----------------------------------------------------------------
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String BackEndUrl=prefs. getString('BackEndUrl');
  String user_id=prefs. getString('user_id');
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${BackEndUrl}/getUserImgs'),
  );
  request.fields['user_id']=user_id;
  http.StreamedResponse r = await request.send();
  if (r.statusCode == 200) {
    List imgList=(await r.stream
        .transform(utf8.decoder)
        .transform(json.decoder)
        .toList())[0] as List;
    List<String> imgUrls=[];
    for(int i=0;i<imgList.length;i++){
      imgUrls.add(imgList[i][0]);
    }
    // imgUrls
    //-----------------------------------------------------------------
    return compute(parseGalleryData, imgUrls);
  }
  else {
    print('Failed to load');
    throw Exception('Failed to load');
  }
}
List<String> parseGalleryData(List<String> imgList) {
  return imgList;
}

Future<List<String>> fetchGalleryData() async {
  final response = await http
      .get(
      'https://kaleidosblog.s3-eu-west-1.amazonaws.com/flutter_gallery/data.json')
      .timeout(Duration(seconds: 5));

  if (response.statusCode == 200) {
    return compute(parseGalleryData1, response.body);
  } else {
    throw Exception('Failed to load');
  }
}
List<String> parseGalleryData1(String responseBody) {
  final parsed = List<String>.from(json.decode(responseBody));
  return parsed;
}


class CameraScreen extends StatefulWidget {
  final String  objectUrl;
  CameraScreen({
    Key key,
    @required this.objectUrl
  }) : super(key: key);
  @override
  _CameraScreenState createState() => _CameraScreenState();
}
class _CameraScreenState extends State<CameraScreen> {
  CameraController cameraController;
  List cameras;
  int selectedCameraIndex;
  bool _saving = false;

  Future initCamera(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      await cameraController.dispose();
    }

    cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);

    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (cameraController.value.hasError) {
      print('Camera Error ${cameraController.value.errorDescription}');
    }

    try {
      await cameraController.initialize();
    } catch (e) {
      showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  /// Display camera preview
  Widget cameraPreview() {
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Text(
        'Loading',
        style: TextStyle(
            color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
      );
    }

    // return AspectRatio(
    //   aspectRatio: cameraController.value.aspectRatio,
    //   child: CameraPreview(cameraController),
    // );
    return CameraPreview(cameraController);
  }
  Widget cameraControl(context) {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            FloatingActionButton(
              child: Icon(
                Icons.camera,
                color: Colors.black,
              ),
              backgroundColor: Colors.white,
              onPressed: () async {


                setState(() {
                  _saving = true;
                });


                XFile photo_=await onCapture();
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String BackEndUrl=prefs. getString('BackEndUrl');
                String user_id=prefs. getString('user_id');
                var request = http.MultipartRequest(
                  'POST',
                  Uri.parse('${BackEndUrl}/getUserIP'),
                );
                request.fields['user_id']=user_id;
                http.StreamedResponse r = await request.send();
                String user_ip = await r.stream.transform(utf8.decoder).join();

                Socket socket = await Socket.connect(user_ip, 1278);


                socket.write(widget.objectUrl);
                var a=File(photo_.path).readAsBytesSync();
                socket.add(a.toList());
                socket.write('XXX');


                socket.listen(
                  (data) {
                    final serverResponse = String.fromCharCodes(data);
                    print('Server: $serverResponse');
                  },
                  onError: (error) {
                    print(error);
                    socket.destroy();
                  },
                  onDone: () {
                    print('Server left.');
                    socket.destroy();
                    setState(() {
                      _saving = false;
                    });
                  },
                );



              },
            )
          ],
        ),
      ),
    );
  }
  Widget cameraToggle() {
    if (cameras == null || cameras.isEmpty) {
      return Spacer();
    }

    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return Expanded(
      child: Align(
        alignment: Alignment.centerLeft,
        child: FlatButton.icon(
            onPressed: () {
              onSwitchCamera();
            },
            icon: Icon(
              getCameraLensIcons(lensDirection),
              color: Colors.white,
              size: 24,
            ),
            label: Text(
              '${lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1).toUpperCase()}',
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            )),
      ),
    );
  }

  onCapture() async {
    try {
      XFile photo_=await cameraController.takePicture();
      return photo_;
    } catch (e) {
      showCameraException(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    availableCameras().then((value) {
      cameras = value;
      if(cameras.length > 0){
        setState(() {
          selectedCameraIndex = 0;
        });
        initCamera(cameras[selectedCameraIndex]).then((value) {

        });
      } else {
        print('No camera available');
      }
    }).catchError((e){
      print('Error : ${e.code}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ModalProgressHUD(
        child: Container(
        child: Stack(
          children: <Widget>[
           // Expanded(
           //   flex: 1,
           //   child: _cameraPreviewWidget(),
           // ),
            Align(
              alignment: Alignment.center,
              child: cameraPreview(),
            ),
            Align(
              alignment: Alignment.center,
              child:
              Container(
                  // height: MediaQuery.of(context).size.height,
                  // width: MediaQuery.of(context).size.width,
                  height: 0.8*MediaQuery.of(context).size.height,
                  width: 0.8*MediaQuery.of(context).size.width,
                  decoration: new BoxDecoration(
                      image: new DecorationImage(
                          image: new NetworkImage(
                            widget.objectUrl
                            // 'https://pngquant.org/Ducati_side_shadow-fs8.png'
                          ),
                          fit: BoxFit.contain
                      )
                  )
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child:
              Container(
                height: 120,
                width: double.infinity,
                padding: EdgeInsets.all(15),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    cameraToggle(),
                    cameraControl(context),
                    Spacer(),
                  ],
                ),
              ),
            ),
          ],
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

  getCameraLensIcons(lensDirection) {
    switch (lensDirection) {
      case CameraLensDirection.back:
        return CupertinoIcons.switch_camera;
      case CameraLensDirection.front:
        return CupertinoIcons.switch_camera_solid;
      case CameraLensDirection.external:
        return CupertinoIcons.photo_camera;
      default:
        return Icons.device_unknown;
    }
  }
  onSwitchCamera() {
    selectedCameraIndex =
    selectedCameraIndex < cameras.length - 1 ? selectedCameraIndex + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    initCamera(selectedCamera);
  }
  showCameraException(e) {
    String errorText = 'Error ${e.code} \nError message: ${e.description}';
  }
}