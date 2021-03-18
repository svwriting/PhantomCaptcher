import sqlite3
conn = sqlite3.connect('PCtestDB_sqlite.db',check_same_thread=False)
c = conn.cursor()

def CreateAccount(user_id,user_password,user_pic_url='https://www.nvda.org.tw/img/S783C.png'):
    try:
        c.execute('INSERT INTO users values (?, ?, ?)',(user_id,user_password,user_pic_url))
        conn.commit()
        c.execute('INSERT INTO ips (ips_userid) values (?)',(user_id))
        conn.commit()
        return 0 # OK
    except:
        return 1 # ERROR
def DeleteAccount(user_id):
    try:
        c.execute('DELETE FROM users WHERE user_id=(?)',[user_id])
        conn.commit()
        return 0 # OK
    except:
        return 1 # ERROR
def UpdateAccount(user_id,column,value):
    try:
        c.execute('UPDATE users SET '+column+'=(?) WHERE user_id=(?)',(value,user_id))
        conn.commit()
        return 0 # OK
    except:
        return 1 # ERROR
def UpdateUserIP(user_id,value):
    try:
        c.execute('UPDATE ips SET ips_ip=(?) WHERE ips_userid=(?)',(value,user_id))
        conn.commit()
        return 0 # OK
    except:
        return 1 # ERROR
def GetUserIP(user_id):
    try:
        c.execute('SELECT ips_ip FROM ips WHERE ips_userid=(?)',[user_id])
        return c.fetchall()
    except:
        return 1 # ERROR
def GetAccountInfo(user_id,user_password):
    try:
      c.execute('SELECT * FROM users WHERE user_id=? AND user_password=? ',(user_id,user_password))
      return c.fetchall()
    except:
      return 1
def GetAllAccount():
    try:
      c.execute('SELECT * FROM users')
      return c.fetchall()
    except:
      return 1

def SaveImgInfo(img_id,img_userid,img_object,img_mask,img_snap):
    try:
        c.execute('INSERT INTO imgs values (?, ?, ?, ?, ?)',(img_id,img_userid,img_object,img_mask,img_snap))
        conn.commit()
        return 0 # OK
    except:
        return 1 # ERROR
def DeleteImgInfo(column,value):
    try:
        c.execute('DELETE FROM imgs WHERE '+column+'=(?) ',[value])
        # print()
        conn.commit()
        return 0 # OK
    except:
        return 1 # ERROR
def GetImgSnaps(column,value):
    try:
      # c.execute('SELECT img_id,img_snap FROM imgs WHERE '+column+'=(?) ',[value])
      c.execute('SELECT img_snap FROM imgs WHERE '+column+'=(?) ',[value])
      return c.fetchall()
    except:
      return 1
def GetImgIds(column,value):
    try:
      # c.execute('SELECT img_id,img_snap FROM imgs WHERE '+column+'=(?) ',[value])
      c.execute('SELECT img_id FROM imgs WHERE '+column+'=(?) ',[value])
      return c.fetchall()
    except:
      return 1
def GetAllImgInfo():
    try:
      c.execute('SELECT * FROM imgs')
      return c.fetchall()
    except:
      return 1


from datetime import datetime
import tempfile
import io
from google.cloud import storage
storage_client = storage.Client.from_service_account_json(f'phantomcaptcher-gcskey.json')
bucket = storage_client.bucket('phantomcaptcher_bucket')

def SaveImg(img,filenamepath):
    blob = bucket.blob(filenamepath)
    imgByteArr=io.BytesIO()
    img.save(imgByteArr, format='PNG')
    with tempfile.NamedTemporaryFile('wb') as buffer_:
        buffer_.write(imgByteArr.getvalue())
        buffer_.flush()
        blob.upload_from_filename(buffer_.name)
        try:
          blob.make_public()
        except:
          pass
        imgpath_url= blob.public_url
    return imgpath_url
def DeleteImg(filenamepath):
    blob = bucket.blob(filenamepath)
    blob.delete()

def SaveImgAsObject(img,img_id):
    filenamepath=f'imgs/img_object/{img_id}.png'
    return SaveImg(img,filenamepath)
def SaveImgAsMask(img,img_id):
    filenamepath=f'imgs/img_mask/{img_id}.png'
    return SaveImg(img,filenamepath)
def SaveImgAsSnap(img,img_id):
    filenamepath=f'imgs/img_snap/{img_id}.png'
    return SaveImg(img,filenamepath)
def SaveUserpic(user_pic,user_id):
    filenamepath=f'user_pic/{user_id}.png'
    return SaveImg(user_pic,filenamepath)

def DeleteImgsByID(img_id):
    filenamepath=f'imgs/img_object/{img_id}.png'
    DeleteImg(filenamepath)
    filenamepath=f'imgs/img_mask/{img_id}.png'
    DeleteImg(filenamepath)
    filenamepath=f'imgs/img_snap/{img_id}.png'
    DeleteImg(filenamepath)


