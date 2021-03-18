
######################### prepare #########################
from flask import Flask
from flask_ngrok import run_with_ngrok
#  9. 設定Server啟用細節
appname='pcserver_test'
app = Flask(
    __name__,
    static_url_path = f"/{appname}" , 
    static_folder = f"./{appname}/"
)
run_with_ngrok(app)


#==============================================================================================================

import io
import os
from flask import Flask, request, jsonify, send_file
from flask import Response
# from flask_cors import CORS
from PIL import Image
from PIL import ImageOps
from PIL import ImageChops
import numpy as np
import time
# import screenpoint
from datetime import datetime
# import pyscreenshot
import requests
# import argparse
import DBcontrol

import tempfile
import base64

# import ps
# import tempfile
#----------------------------------------------------------
# import GeneMaskNet
# import GeneCompressedNet
#----------------------------------------------------------

#================================================
# from google.cloud import storage
# storage_client = storage.Client.from_service_account_json('phantomcaptcher-gcskey.json')
# import cloudstorage as gcs
# gcs


#================================================
# args=args(
#     photoshop_password='123456'
# )
# args={
#     'photoshop_password':'123456'
# }


#================================================
def autoCrop(image,backgroundColor=None):
  if backgroundColor==None:
    bbox=image.split()[list(image.getbands()).index('A')].getbbox()
  else:
    bg = Image.new( 
        image.getbands()[0], 
        image.size, 
        backgroundColor)
    bg = Image.new("L", image.size, backgroundColor)
    diff = ImageChops.difference(image, bg)
    bbox = diff.getbbox()
  return image.crop(bbox)

# def GenePNGMask(png_):
#     mask_=Image.fromarray(
#     (
#         (
#             np.array(
#                 png_
#               )[:,:,3]>1  
#           )*255
#       ).astype(np.uint8)
#     )
#     return mask_
# def GeneMask(img_):
#     mask_ = GeneMaskNet.run(np.array(img_))
#     return mask_
# def GeneCompressed(img_,mask_):
#     compressed_ = GeneCompressedNet.run(img_,mask_)
#     return compressed_


#================================================
# app = Flask(__name__)
# CORS(app)
#------------------------------------------------
@app.route('/')
def go_Hello():
    print('##### /')
    return 'PhantomCaptcher / PhatomCapture\n'
# @app.route('/ObjectCaptureProcess', methods=['POST'])
# def go_ObjectCaptureProcess():
#     print('##### /ObjectCaptureProcess')
#     data = request.files['data'].read()
#     img_ = Image.open(io.BytesIO(data))
#     mask_=GeneMask(img_)
#     mask_ = mask_.convert("L").resize(img_.size)
#     img_ = Image.composite(img_, Image.new("RGBA",img_.size,0), mask_)
#     user_id=request.values.get('user_id')
#     if user_id=='user_id in here':
#       user_id='user_test'
#     time_=datetime.now().strftime("%Y%m%d-%H%M%S-%f")
#     img_id=f'{user_id}-{time_}'
# 
#     img_=autoCrop(img_)
#     mask_=autoCrop(mask_,backgroundColor=0)
#     snap_=img_.copy()
#     snap_.thumbnail((256,256))
# 
#     object_url=DBcontrol.SaveImgAsObject(img_,img_id)
#     mask_url=DBcontrol.SaveImgAsMask(mask_,img_id)
#     snap_url=DBcontrol.SaveImgAsSnap(snap_,img_id)
# 
#     print('### SaveInfoSuccess?',DBcontrol.SaveImgInfo(img_id,user_id,object_url,mask_url,snap_url)==0)
#     return object_url
@app.route('/CreateAccount', methods=['POST'])
def go_CreateAccount():
    print('##### /CreateAccount')
    data = request.files['data'].read()
    user_pic = Image.open(io.BytesIO(data))
    user_pic.thumbnail((256,256))
    user_id=request.values.get('user_id')
    user_password=request.values.get('user_password')
    user_pic_url=DBcontrol.SaveUserpic(user_pic,user_id)
    ifSuccess=DBcontrol.CreateAccount(user_id,user_password,user_pic_url)==0
    print(user_pic_url)
    if ifSuccess:
      return user_pic_url
    else:
      return 'DECLINE'
@app.route('/ifPass', methods=['POST'])
def go_ifPass():
    print('##### /ifPass')
    user_id=request.values.get('user_id')
    user_password=request.values.get('user_password')
    accountInfos=DBcontrol.GetAccountInfo(user_id,user_password)
    print(accountInfos)
    if len(accountInfos)>=1:
      return accountInfos[0][2]
    else:
      return 'DECLINE'
@app.route('/getUserImgs', methods=['POST'])
def go_getUserImgs():
    print('##### /getUserImgs')
    user_id=request.values.get('user_id')
    imgSnaps=DBcontrol.GetImgSnaps('img_userid',user_id)
    print(imgSnaps)
    return jsonify(imgSnaps)
@app.route('/delImgBySnap', methods=['POST'])
def go_delImgBySnap():
    print('##### /delImgBySnap')
    img_snap=request.values.get('img_snap')
    imgInfos=DBcontrol.GetImgIds('img_snap',img_snap)
    delresult="DoNothing"
    if len(imgInfos)>0:
      img_id=imgInfos[0][0]
      print(img_id)
      delresult="SUCCESS" if DBcontrol.DeleteImgInfo('img_snap',img_snap)==0 else "DECLINE"
      DBcontrol.DeleteImgsByID(img_id)
    print(delresult)
    return delresult
@app.route('/updateUserIP', methods=['POST'])
def go_updateUserIP():
    print('##### /updateUserIP')
    user_id=request.values.get('user_id')
    user_ip=request.values.get('user_ip')
    res_="SUCCESS" if DBcontrol.UpdateUserIP(user_id,user_ip)==0 else "DECLINE"
    print(user_id,user_ip)
    print(res_)
    return res_
@app.route('/getUserIP', methods=['POST'])
def go_getUserIP():
    print('##### /getUserIP')
    user_id=request.values.get('user_id')
    res_=DBcontrol.GetUserIP(user_id)
    ifGet="SUCCESS" if len(res_)>0 else "DECLINE"
    res_=res_[0][0]
    print(user_id,res_)
    print(ifGet)
    return res_

#------------------ for test ---------------------
# @app.route('/RemoveBg', methods=['POST'])
# def goRemoveBg():
#     # if 'data' not in request.files:
#     #     return jsonify({
#     #         'status': 'error',
#     #         'error': 'missing file param `data`'
#     #     }), 400
#     data = request.files['data'].read()
#     # if len(data) == 0:
#     #     return jsonify({'status:': 'error', 'error': 'empty image'}), 400
#     img_ = Image.open(io.BytesIO(data))
#     mask_=GeneMask(img_)
#     mask_ = mask_.convert("L").resize(img_.size)
#     img_ = Image.composite(img_, Image.new("RGBA",img_.size,0), mask_)
#     buffer = io.BytesIO()
#     img_.save(buffer, 'PNG')
#     return buffer.getvalue()
# @app.route('/RemoveBgMask', methods=['POST'])
# def goRemoveBgMask():
#     data = request.files['data'].read()
#     img_ = Image.open(io.BytesIO(data))
#     mask_=GeneMask(img_)
#     mask_ = mask_.convert("L").resize(img_.size)
#     buffer = io.BytesIO()
#     mask_.save(buffer, 'PNG')
#     return buffer.getvalue()
# @app.route('/OBCompress', methods=['POST'])
# def goOBCompress():
#     data = request.files['data1'].read()
#     img_ = Image.open(io.BytesIO(data))
#     data = request.files['data2'].read()
#     mask_= Image.open(io.BytesIO(data))
#     compressed_=GeneCompressed(img_,mask_)
#     mask_=ImageOps.invert(mask_)
#     compressed_= Image.composite(img_, compressed_, mask_)
#     buffer = io.BytesIO()
#     compressed_.save(buffer, 'PNG')
#     return buffer.getvalue()
# @app.route('/testsaveimg', methods=['POST'])
# def gotestsaveimg():
#     data = request.files['data'].read()
#     img_ = Image.open(io.BytesIO(data))
#     mask_=GeneMask(img_)
#     mask_ = mask_.convert("L").resize(img_.size)
#     img_ = Image.composite(img_, Image.new("RGBA",img_.size,0), mask_)

#     # user_id='user_test'
#     # time_=datetime.now().strftime("%Y%m%d-%H%M%S-%f")
#     # img_id=f'{user_id}-{time_}'
#     # object_url=DBcontrol.SaveImgAsObject(img_,img_id)
#     # mask_url=DBcontrol.SaveImgAsMask(mask_,img_id)

#     buffer = io.BytesIO()
#     img_.save(buffer, 'PNG')
#     return buffer.getvalue()


#================================================
# if __name__ == '__main__':
#     app.run(host='127.0.0.1', port=8080, debug=True)
app.run()
