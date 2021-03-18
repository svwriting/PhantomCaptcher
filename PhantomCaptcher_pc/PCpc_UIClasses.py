# -*- coding: utf-8 -*-

###########################################################################
## Python code generated with wxFormBuilder (version Oct 26 2018)
## http://www.wxformbuilder.org/
##
## PLEASE DO *NOT* EDIT THIS FILE!
###########################################################################

import wx
import wx.xrc
import requests
import os
import socket 

BackEndUrl="http://aa79d1b16f5f.ngrok.io/"


if "2.8" in wx.version():
    import wx.lib.pubsub.setupkwargs
    from pubsub import pub
else:
    from pubsub import pub


########################################################################
class LoginDialog(wx.Dialog):
    """
    Class to define login dialog
    """

    #----------------------------------------------------------------------
    def __init__(self):
        """Constructor"""
        wx.Dialog.__init__(self, None, title="Phantom Captcher - Login", size = wx.Size( 210,160))
        self.Centre()
        
        # user info
        user_sizer = wx.BoxSizer(wx.HORIZONTAL)
        
        user_lbl = wx.StaticText(self, label="Username:")
        user_sizer.Add(user_lbl, 0, wx.ALL|wx.CENTER, 5)
        self.user = wx.TextCtrl(self)
        user_sizer.Add(self.user, 0, wx.ALL, 1)
        
        # pass info
        p_sizer = wx.BoxSizer(wx.HORIZONTAL)
        
        p_lbl = wx.StaticText(self, label="Password:")
        p_sizer.Add(p_lbl, 0, wx.ALL|wx.CENTER, 5)
        self.password = wx.TextCtrl(self, style=wx.TE_PASSWORD|wx.TE_PROCESS_ENTER)
        p_sizer.Add(self.password, 0, wx.ALL, 5)
        
        main_sizer = wx.BoxSizer(wx.VERTICAL)
        main_sizer.Add(user_sizer, 0, wx.ALL, 5)
        main_sizer.Add(p_sizer, 0, wx.ALL, 5)
        
        btn = wx.Button(self, label="Login")
        btn.Bind(wx.EVT_BUTTON, self.onLogin)
        main_sizer.Add(btn, 0, wx.ALL|wx.CENTER, 5)
        
        self.SetSizer(main_sizer)

        self.Bind(wx.EVT_CLOSE,self.onClose)




    def onClose( self,event ):
        os._exit(0)
        pass

    #----------------------------------------------------------------------
    def onLogin(self, event):
        """
        Check credentials and login
        """
        user_id = self.user.GetValue()
        user_password = self.password.GetValue()
        url_=f"{BackEndUrl}/ifPass"
        r_=requests.post(url_,
            data = {'user_id':user_id,'user_password':user_password}
        )
        r_.encoding="rtf-8"
        # print(r_.text)
        if r_.text=='DECLINE':
            wx.MessageDialog(None, "Username or password is incorrect.", 'Decline', wx.ICON_ERROR | wx.ICON_INFORMATION).ShowModal()
        else:
            # print(r_.text)
            hostname = socket.gethostname()
            local_ip = socket.gethostbyname(hostname)
            url_=f"{BackEndUrl}/updateUserIP"
            r_=requests.post(url_,
                data = {'user_id':user_id,'user_ip':local_ip}
            )
            r_.encoding="rtf-8"
            # print(r_.text)
            if r_.text=='DECLINE':
                wx.MessageDialog(None, "Something went wrong.", 'Decline', wx.ICON_ERROR | wx.ICON_INFORMATION).ShowModal()
            else:
                wx.MessageDialog(None, 'You are now logged in.', 'Success', wx.OK | wx.ICON_INFORMATION).ShowModal()
                self.EndModal(0)