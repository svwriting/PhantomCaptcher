#server.py 
import io
import socket 
import tempfile
from PIL import Image
from PIL import ImageGrab
import cv2
from numpy.core.fromnumeric import resize
import screenpoint
import requests
import numpy as np

class PCSocketServer():
    host = ''
    port = 1278
    def __init__(self):
        pass

    def getipaddrs(self,hostname):#只是為了顯示IP,僅僅測試一下 
        result = socket.getaddrinfo(hostname, None, 0, socket.SOCK_STREAM) 
        return [x[4][0] for x in result] 

    def run(self,host=host,port=port):
        # hostname = socket.gethostname() 
        # hostip = self.getipaddrs(hostname)
        # print(f"{hostname}:{hostip}")
        print('Server has started: ',port)
        print('Server is ready to accept requests......')

        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 
        s.bind((host, port)) 
        s.listen(10) 

        while True: 
            conn, addr = s.accept() 
            print('Connected by', addr)


            snap_url = conn.recv(1024).decode("utf-8")
            print('Received\t:', snap_url)

            screen_=ImageGrab.grab()
 
            buffer = tempfile.SpooledTemporaryFile()
            print('Receiving (photo)......',end='')
            photo_data = conn.recv(1024)
            while photo_data.endswith(bytes('XXX','utf8'))==False:
                buffer.write(photo_data)
                photo_data=conn.recv(1024)
                # print(photo_data,end='')
                # print(photo_data)
            else:
                photo_data=photo_data[:-3]
                buffer.write(photo_data)
                # print(photo_data)
            print('done.')
            buffer.seek(0)
            view_ = Image.open(io.BytesIO(buffer.read()))
            buffer.close()

            sizeof_view=view_.size

            object_url=snap_url.replace('/img_snap/','/img_object/')
            mask_url=snap_url.replace('/img_snap/','/img_mask/')
            # object_=Image.open(requests.get(object_url, stream=True).raw)
            # mask_=Image.open(requests.get(mask_url, stream=True).raw)
            # sizeof_object = object_.size
            snap_=Image.open(requests.get(snap_url, stream=True).raw)
            sizeof_object = snap_.size
            
            object_WHrate=sizeof_object[0]/sizeof_object[1]
            if object_WHrate>=1:
                nW=sizeof_view[0]//2
                nH=nW//object_WHrate
            else:
                nH=sizeof_view[1]//2
                nW=nH*object_WHrate
            sizeof_object=(nW,nH)

            # print("sizeof_view:\t",sizeof_view)
            # print("sizeof_object:\t",sizeof_object)


            screen_.save('temp_screen.png')
            screen_=cv2.imread('temp_screen.png')
            view_.save('temp_view.png')
            view_=cv2.imread('temp_view.png')
            
            view_p_c=((sizeof_view[0]-1)//2,(sizeof_view[1]-1)//2)
            view_p_1=( view_p_c[0]-(nW//2), view_p_c[1]-(nH//2))
            view_p_2=( view_p_c[0]-(nW//2), view_p_c[1]+(nH//2))
            view_p_3=( view_p_c[0]+(nW//2), view_p_c[1]+(nH//2))
            view_p_4=( view_p_c[0]+(nW//2), view_p_c[1]-(nH//2))
            center_ = screenpoint.project(view_, screen_)
            p_1 = screenpoint.project(view_, screen_, view_p_1)
            p_2 = screenpoint.project(view_, screen_, view_p_2)
            p_3 = screenpoint.project(view_, screen_, view_p_3)
            p_4 = screenpoint.project(view_, screen_, view_p_4)
            print("view_center\t:", view_p_c,"\t=>\t","center\t:", center_)
            print("view_p_1\t:", view_p_1,"\t=>\t","p_1\t:", p_1)
            print("view_p_2\t:", view_p_2,"\t=>\t","p_2\t:", p_2)
            print("view_p_3\t:", view_p_3,"\t=>\t","p_3\t:", p_3)
            print("view_p_4\t:", view_p_4,"\t=>\t","p_4\t:", p_4)


            points_ = np.array(
                [
                    p_1,
                    p_2,
                    p_3,
                    p_4,
                ], 
                np.int32
            )
            points_ = points_.reshape((-1,1,2))
            temp_= screen_.copy()
            cv2.polylines(
                img= temp_,
                pts= [points_],
                isClosed= True,
                color= (0,0,255),
                thickness= 3
            )
            cv2.imwrite("C:\\Users\\svwriting\\Desktop\\temp.jpg", temp_)       
            # cv2.imshow("image",
            #     temp_
            # )
            # cv2.waitKey(0)
            # cv2.destroyAllWindows()



            # with PhotoshopConnection(password='123456') as conn:




            conn.sendall(bytes("DONE -recv_data",'utf8'))
            conn.close()
            print('======== round end ========',end='\n\n')
