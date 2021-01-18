----------------------------------------------------------------------------
-- Lua code generated with wxFormBuilder (version May 29 2018)
-- http://www.wxformbuilder.org/
----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../bin/?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

UI = {}
app = wx.wxGetApp()
stdpaths = wx.wxStandardPaths.Get()
osinfo = wx.wxPlatformInfo.Get()
isWindow = osinfo:GetOperatingSystemFamilyName() == "Windows"

local filename = wx.wxFileName(stdpaths:GetExecutablePath())  
local currentWorkDirectory = filename:GetPath(wx.wxPATH_GET_VOLUME or wx.wxPATH_GET_SEPARATOR)
local images = wx.wxFileName(currentWorkDirectory, "images"):GetFullPath()
local imagefile = "image-1.jpg"

if not wx.wxDirExists(images) then
  if not wx.wxMkdir(images) then    
    wx.wxMessageBox("创建 images 目录失败",
                        "错误",
                        wx.wxOK + wx.wxICON_INFORMATION)
    return
  end
end


-- create ConnectDialog
UI.ConnectDialog = wx.wxDialog (wx.NULL, wx.wxID_ANY, "连接到服务器...", wx.wxDefaultPosition, wx.wxSize( 438,101 ), wx.wxDEFAULT_DIALOG_STYLE )
	UI.ConnectDialog:SetSizeHints( wx.wxDefaultSize, wx.wxDefaultSize )
	
	UI.bSizer1 = wx.wxBoxSizer( wx.wxVERTICAL )
	
	UI.m_addressChoices = {}
	UI.m_address = wx.wxComboBox( UI.ConnectDialog, wx.wxID_ANY, "127.0.0.1:8000", wx.wxDefaultPosition, wx.wxDefaultSize, UI.m_addressChoices, 0 )
	UI.bSizer1:Add( UI.m_address, 0, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_sdbSizer1 = wx.wxStdDialogButtonSizer()
	UI.m_sdbSizer1OK = wx.wxButton( UI.ConnectDialog, wx.wxID_OK, "" )
	UI.m_sdbSizer1:AddButton( UI.m_sdbSizer1OK )
	UI.m_sdbSizer1Cancel = wx.wxButton( UI.ConnectDialog, wx.wxID_CANCEL, "" )
	UI.m_sdbSizer1:AddButton( UI.m_sdbSizer1Cancel )
	UI.m_sdbSizer1:Realize();
	
	UI.bSizer1:Add( UI.m_sdbSizer1, 0, wx.wxEXPAND, 5 )
	
	
	UI.ConnectDialog:SetSizer( UI.bSizer1 )
	UI.ConnectDialog:Layout()
	
	UI.ConnectDialog:Centre( wx.wxBOTH )

-- create LoginDialog
UI.LoginDialog = wx.wxDialog (wx.NULL, wx.wxID_ANY, "登录", wx.wxDefaultPosition, wx.wxSize( 848,452 ), wx.wxDEFAULT_FRAME_STYLE+wx.wxTAB_TRAVERSAL )
	UI.LoginDialog:SetSizeHints( wx.wxDefaultSize, wx.wxDefaultSize )
	
	UI.bSizer2 = wx.wxBoxSizer( wx.wxHORIZONTAL )
	
	UI.m_panel1 = wx.wxPanel( UI.LoginDialog, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL )
	UI.bSizer5 = wx.wxBoxSizer( wx.wxVERTICAL )
	
	UI.bSizer6 = wx.wxBoxSizer( wx.wxVERTICAL )
	
	UI.m_username = wx.wxTextCtrl( UI.m_panel1, wx.wxID_ANY, "请输入用户名", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer6:Add( UI.m_username, 0, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_cam_bitmap = wx.wxStaticBitmap( UI.m_panel1, wx.wxID_ANY, wx.wxBitmap( "none.jpg", wx.wxBITMAP_TYPE_ANY ), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer6:Add( UI.m_cam_bitmap, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	
	UI.bSizer5:Add( UI.bSizer6, 1, wx.wxEXPAND, 5 )
	
	
	UI.m_panel1:SetSizer( UI.bSizer5 )
	UI.m_panel1:Layout()
	UI.bSizer5:Fit( UI.m_panel1 )
	UI.bSizer2:Add( UI.m_panel1, 1, wx.wxEXPAND  + wx. wxALL, 5 )
	
	UI.bSizer3 = wx.wxBoxSizer( wx.wxVERTICAL )
	
	UI.m_staticText2 = wx.wxStaticText( UI.LoginDialog, wx.wxID_ANY, "请选择节点：", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticText2:Wrap( -1 )
	UI.bSizer3:Add( UI.m_staticText2, 0, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_endpointsChoices = { "sssssssssssssssssssssssssssssssssssssssssssssssss", "abc1", "abc", "abc2" }
	UI.m_endpoints = wx.wxListBox( UI.LoginDialog, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, UI.m_endpointsChoices, 0 )
	UI.bSizer3:Add( UI.m_endpoints, 0, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_sdbSizer2 = wx.wxStdDialogButtonSizer()
	UI.m_sdbSizer2OK = wx.wxButton( UI.LoginDialog, wx.wxID_OK, "" )
	UI.m_sdbSizer2:AddButton( UI.m_sdbSizer2OK )
	UI.m_sdbSizer2:Realize();
	
	UI.bSizer3:Add( UI.m_sdbSizer2, 0, wx.wxEXPAND, 5 )
	
	UI.m_staticText4 = wx.wxStaticText( UI.LoginDialog, wx.wxID_ANY, "\n  请对准摄像头，然后点确定。", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_staticText4:Wrap( -1 )
	UI.bSizer3:Add( UI.m_staticText4, 0, wx.wxALL, 5 )
	
	
	UI.bSizer2:Add( UI.bSizer3, 0, wx.wxEXPAND, 5 )
	
	
	UI.LoginDialog:SetSizer( UI.bSizer2 )
	UI.LoginDialog:Layout()
	UI.m_cam_timer = wx.wxTimer(UI.LoginDialog, wx.wxID_ANY)
	
	
	UI.LoginDialog:Centre( wx.wxBOTH )

-- create MainFrame
UI.MainFrame = wx.wxDialog (wx.NULL, wx.wxID_ANY, "已登录正在录屏中...", wx.wxDefaultPosition, wx.wxSize( 378,77 ), wx.wxDEFAULT_FRAME_STYLE+wx.wxTAB_TRAVERSAL )
	UI.MainFrame:SetSizeHints( wx.wxDefaultSize, wx.wxDefaultSize )
	
	UI.mainSizer = wx.wxBoxSizer( wx.wxHORIZONTAL )
	
	UI.m_bitmap2 = wx.wxStaticBitmap( UI.MainFrame, wx.wxID_ANY, wx.wxBitmap( "favicon.ico", wx.wxBITMAP_TYPE_ANY ), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.m_bitmap2:SetExtraStyle( wx.wxWS_EX_BLOCK_EVENTS + wx.wxWS_EX_PROCESS_IDLE + wx.wxWS_EX_PROCESS_UI_UPDATES + wx.wxWS_EX_TRANSIENT + wx.wxWS_EX_VALIDATE_RECURSIVELY )
	
	UI.mainSizer:Add( UI.m_bitmap2, 1, wx.wxALL + wx.wxEXPAND, 5 )
	
	UI.m_button2 = wx.wxButton( UI.MainFrame, wx.wxID_ANY, "断开", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.mainSizer:Add( UI.m_button2, 0, wx.wxALL + wx.wxALIGN_CENTER_VERTICAL, 5 )
	
	UI.m_sdbSizer3 = wx.wxStdDialogButtonSizer()
	UI.m_sdbSizer3OK = wx.wxButton( UI.MainFrame, wx.wxID_OK, "" )
	UI.m_sdbSizer3:AddButton( UI.m_sdbSizer3OK )
	UI.m_sdbSizer3:Realize();
	
	UI.mainSizer:Add( UI.m_sdbSizer3, 1, wx.wxEXPAND + wx.wxALIGN_CENTER_VERTICAL, 5 )
	
	
	UI.MainFrame:SetSizer( UI.mainSizer )
	UI.MainFrame:Layout()
	
	UI.MainFrame:Centre( wx.wxBOTH )



local isRunning = false

UI.LoginDialog:Connect(wx.wxEVT_TIMER, function(event)
--implements onTimer
    if isRunning then return end
    
    isRunning = true
    
    local proc = wx.wxProcess()
    proc:Redirect()
    proc:Connect(wx.wxEVT_END_PROCESS, function(event) 
        isRunning = false
    end)
    
    local toimage = wx.wxFileName(currentWorkDirectory, "toimages.bat"):GetFullPath()
    if not isWindow then
        toimage = wx.wxFileName(currentWorkDirectory, "toimages.sh"):GetFullPath()
    end
    
    local pid = wx.wxExecute(toimage, false, proc)
    
    
    if not pid or pid == -1 or pid == 0 then
        UI.m_cam_timer:Stop()
        
        wx.wxMessageBox(("Program unable to run as '%s'."):format(cmd),
                    "运行命令失败",
                    wx.wxOK + wx.wxICON_INFORMATION,
                    UI.LoginDialog)
        return
    end
    
    local imagefilename = wx.wxFileName(images, imagefile):GetFullPath()
    local image = wx.wxImage(imagefilename) 
    local size = UI.m_cam_bitmap:GetSize()
    image = image:Rescale(size:GetWidth(), size:GetHeight())    
    UI.m_cam_bitmap:SetBitmap(wx.wxBitmap(image))
    
end )

local result = UI.ConnectDialog:ShowModal()
if result ~= wx.wxID_OK and result ~= wx.wxID_YES then
    return
end


UI.m_cam_timer:Start(100)
-- show the frame window
result = UI.LoginDialog:ShowModal()
UI.m_cam_timer:Stop()

if result ~= wx.wxID_OK and result ~= wx.wxID_YES then
    return
end

local result = UI.MainFrame:ShowModal()
if result ~= wx.wxID_OK and result ~= wx.wxID_YES then
    wx.wxMessageBox('This is the "About" dialog of the MDI wxLua sample.\n'..
                        wxlua.wxLUA_VERSION_STRING.." built with "..result,
                        "About wxLua",
                        wx.wxOK + wx.wxICON_INFORMATION,
                        UI.MainFrame)
end

