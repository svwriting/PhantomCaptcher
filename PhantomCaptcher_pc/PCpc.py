import os
import wx
from wx import adv
from wx.core import Bitmap, MenuItem

from photoshop import PhotoshopConnection
from PCSocketServer import PCSocketServer
from PCpc_UIClasses import *

class TaskBarIcon(wx.adv.TaskBarIcon):
	TRAY_ICON_PSoff = None
	TRAY_ICON_PSon = None
	def __init__(self):
		super(TaskBarIcon, self).__init__()
		self.TRAY_ICON_PSoff = wx.Icon()
		self.TRAY_ICON_PSon = wx.Icon()
		self.TRAY_ICON_PSon.CopyFromBitmap(wx.Bitmap('icons_/icon_PSon.png'))
		self.TRAY_ICON_PSoff.CopyFromBitmap(wx.Bitmap('icons_/icon_PSoff.png'))
		self.SetIcon(self.TRAY_ICON_PSon, 'PhantomCaptcher')
		self.Bind(wx.adv.EVT_TASKBAR_LEFT_DOWN, self.on_left_down)
	def on_left_down(self, event):
		print('Tray icon was left-clicked.')

	def on_ABOUT(self, event):
		print('"ABOUT" was left-clicked.')
		wx.MessageBox("Phantom Captcher 幻影捕手","About",wx.OK | wx.ICON_INFORMATION)
	def on_ConnectPhotoshop(self, event):
		try: 
			with PhotoshopConnection(password='123456') as conn:
				pass
			self.SetIcon(self.TRAY_ICON_PSon,'PhantomCaptcher')
			wx.MessageBox("成功與Photoshop連線!","PS連線測試",wx.OK | wx.ICON_INFORMATION)
		except:
			self.SetIcon(self.TRAY_ICON_PSoff,'PhantomCaptcher')
			wx.MessageBox("與Photoshop連線失敗。","PS連線測試",wx.OK | wx.ICON_ERROR)
	def on_exit(self, event):
		wx.CallAfter(self.Destroy)
		os._exit(0)
		
	def create_menu_item(self,menu, label, func=None, ifClickable=True):
		item = wx.MenuItem(menu, -1, label)
		if ifClickable:
			item.SetBackgroundColour(wx.Colour(0,0,100))
			item.SetTextColour(wx.Colour(180,180,0))
		else:
			item.SetBackgroundColour(wx.Colour(0,0,64))
			item.SetTextColour(wx.Colour(250,250,0))
		menu.Bind(wx.EVT_MENU, func, id=item.GetId())
		menu.Append(item)
		return item
	def CreatePopupMenu(self):
		menu = wx.Menu()
		self.create_menu_item(menu,'Phantom Captcher',ifClickable=False)
		# menu.AppendSeparator()
		self.create_menu_item(menu, 'PS連線測試', self.on_ConnectPhotoshop)
		self.create_menu_item(menu, '檢視個人素材', self.on_ABOUT)
		# menu.AppendSeparator()
		self.create_menu_item(menu, 'Exit', self.on_exit)
		return menu
class TaskBarApp(wx.App):
    def OnInit(self):
        self.SetTopWindow(wx.Frame(None, -1))
        TaskBarIcon()
        return True

###########################################################################
threadDict_={}
###########################################################################
#- def runTaskBarApp() ------------------------------------------------
def runTaskBarApp():
	app = TaskBarApp()
	dialog=LoginDialog()
	result = dialog.ShowModal()
	print('login ## ',result)
	app.MainLoop()
threadDict_[runTaskBarApp]=True
#- def runSocketServer() --------------------------------------------------
def runSocketServer():
	PCSocketServer().run()
threadDict_[runSocketServer]=True

#￣￣ for test ￣￣ 
# threadDict_[runSocketServer]=False
# threadDict_[runTaskBarApp]=False
#＿＿ for test ＿＿

import threading

for func_ in threadDict_ :
	if threadDict_[func_]:
		threadDict_[func_] = threading.Thread(target = func_)
		threadDict_[func_].start()