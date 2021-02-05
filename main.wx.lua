----------------------------------------------------------------------------
-- Lua code generated with wxFormBuilder (version May 29 2018)
-- http://www.wxformbuilder.org/
----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;./clibs/?.dll;;./clibs/?.so;../bin/?.so;../lib/?.so;../lib/vc_dll/?.dll;../clibs/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")
http = require("http")
json  = require("dkjson")
utf8 = require("utf8")


os.remove("login.log")

-- 以附加的方式打开只写文件
file = io.open("login.log", "a")
local function logMsg(msg)
  file:write(msg)
  print(msg)
end

local IDCounter = nil
local function NewID()
    if not IDCounter then IDCounter = wx.wxID_HIGHEST end
    IDCounter = IDCounter + 1
    return IDCounter
end

local wxID_CAM_TIMER =NewID()
local wxID_POLL_TIMER = NewID()

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

local camToImage = wx.wxFileName(currentWorkDirectory, "toimages.bat"):GetFullPath()
if not isWindow then
    camToImage = wx.wxFileName(currentWorkDirectory, "toimages.sh"):GetFullPath()
end


local screenToMediaServer = wx.wxFileName(currentWorkDirectory, "screenToMediaServer.bat"):GetFullPath()
if not isWindow then
    screenToMediaServer = wx.wxFileName(currentWorkDirectory, "screenToMediaServer.sh"):GetFullPath()
end

function readAll(file)
    local f = io.open(file, "r")
    local current = f:read("*a")
    return current
end

-- logMsg(screenToMediaServer)
-- screenToMediaServer = readAll(screenToMediaServer)
-- -- if screenToMediaServer == "" then
--    logMsg("screenToMediaServer is empty")
--    return
-- end
-- logMsg(screenToMediaServer)


function readImages()
    local foo = {}
    local imagefilename = wx.wxFileName(images, "image-*.jpg"):GetFullPath()
    local fi = wx.wxFindFirstFile(imagefilename, wx.wxFILE)
    while fi and #fi>0 do
        table.insert(foo, fi)
        fi = wx.wxFindNextFile()
    end
    return foo
end

function removeImages(foo, skipFile)
    for i, name in ipairs(foo) do
       if name ~= skipFile then
          os.remove(name);
       end
    end  
end

removeImages(readImages(), "")

local hostAddress
local connInfo = {
    ["list"] = {{
      ["id"] = 1,
      ["name"] = "接入点11111",
      ["auditDeviceId"]  = 1,
      ["hostName"] = "主机1",
      ["ip"] = "192.168.0.101",
      ["mask"] = "255.255.255.0",
      ["gateway"] = "192.168.0.1",
      ["status"] = 1,
      ["createTime"] = 1608246291000,
    }},
}
local connID
local accessPointID

function getCurrentAccessPoint() 
    for _, value in ipairs(connInfo["list"]) do
        if value["id"] == accessPointID then
          return true, value
        end
    end
   return false, nil
end

function connectServer(url) 
    local response = http.get(url)
    if not response.isOk then
        if not response.output or response.output == "" then
            response.output = "参数不正确"
        end
        logMsg("1\r\n")
        return false, response.output
    end
    local o, pos, err = json.decode(response.output)
    if not o then
        if not response.output then
           response.output = "返回的数据不正确"
        end
        logMsg("2\r\n")
        logMsg(pos.."\r\n")
        logMsg(err.."\r\n")
        logMsg(response.output.."\r\n")
        return false, response.output
    end

    hostAddress = UI.m_address:GetValue()
    connInfo = o
    return true, nil
end


function getAccessPointID()
    local txt = UI.m_endpoints:GetStringSelection()
    if not txt or txt == "" then
      return false, "请选择一个有效的接入点"
    end
   
    for _, value in ipairs(connInfo["list"]) do
        if value["name"] == txt then
          return true, value["id"]
        end
    end
   return false, txt
end

function sendLoginRequest()
    local isOk, idOrMsg = getAccessPointID()
    if not isOk then
       return isOk, idOrMsg
    end
    local username = UI.m_username:GetValue()
    local response = http.postWithFiles(http.join(hostAddress, "/api/link/apply"),
      {
        name = username,
        accessPointId = idOrMsg,
      },{
        image = wx.wxFileName(images, imagefile):GetFullPath(),
      })
    if not response.isOk then
        if not response.output or response.output == "" then
            response.output = "参数不正确"
        end
        return false, response.output
    end
    
    local o, pos, err = json.decode(response.output)
    if not o then
        if not response.output then
            response.output = "返回的数据不正确"
        end
        return false, response.output
    end
    
    if not o.id then       
        logMsg(response.output.."\r\n")
        return false, "响应中没有找到 id -- " .. response.output
    end
    
    connID = o.id
    accessPointID = idOrMsg
    return true, nil
end


function pollLoginStatus()
    if not connID then
        return true, "fail", "参数不正确, session 为空"
    end
    local response = http.get(http.join(http.join(hostAddress, "/api/link/"),connID))
    if not response.isOk then
        if not response.output or response.output == "" then
            response.output = "参数不正确"
        end
        return false, nil, response.output
    end
    
    local o, pos, err = json.decode(response.output)
    if not o then
        if not response.output then
            response.output = "返回的数据不正确"
        end
        return false, nil, response.output
    end
    
    if not o.status then       
        return false, "响应中没有找到 status -- " .. response.output
    end
    
    return true, o.status, o.msg
end

function disconnect()
    if not connID then
        return true, "fail", "参数不正确, session 为空"
    end
    local response = http.delete(http.join(http.join(hostAddress, "/api/link/"),connID), "application/json", "{}")
    if not response.isOk then
        if not response.output or response.output == "" then
            response.output = "参数不正确"
        end
        return false, response.output
    end
    
    return true, nil
end

-- create ConnectDialog
UI.ConnectDialog = wx.wxDialog (wx.NULL, wx.wxID_ANY, "连接到服务器...", wx.wxDefaultPosition, wx.wxSize( 438,101 ), wx.wxDEFAULT_DIALOG_STYLE )
    UI.ConnectDialog:SetSizeHints( wx.wxDefaultSize, wx.wxDefaultSize )
    
    UI.bSizer1 = wx.wxBoxSizer( wx.wxVERTICAL )
    
    UI.m_addressChoices = {}
    
    UI.m_addressChoices = { "http://168.100.2.8:8083",  "http://127.0.0.1:8000"}
    UI.m_address = wx.wxComboBox( UI.ConnectDialog, wx.wxID_ANY, "http://127.0.0.1:8000", wx.wxDefaultPosition, wx.wxDefaultSize, UI.m_addressChoices, 0 )
    UI.bSizer1:Add( UI.m_address, 0, wx.wxALL + wx.wxEXPAND, 5 )
    
    UI.m_connectbar = wx.wxStdDialogButtonSizer()
    UI.m_connectbarOK = wx.wxButton( UI.ConnectDialog, wx.wxID_OK, "" )
    UI.m_connectbar:AddButton( UI.m_connectbarOK )
    UI.m_connectbarCancel = wx.wxButton( UI.ConnectDialog, wx.wxID_CANCEL, "" )
    UI.m_connectbar:AddButton( UI.m_connectbarCancel )
    UI.m_connectbar:Realize();
    
    UI.bSizer1:Add( UI.m_connectbar, 0, wx.wxEXPAND, 5 )
    
    
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
    
    UI.m_endpointsChoices = { "abc1", "abc2" }
    UI.m_endpoints = wx.wxListBox( UI.LoginDialog, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, UI.m_endpointsChoices, 0 )
    UI.bSizer3:Add( UI.m_endpoints, 0, wx.wxALL + wx.wxEXPAND, 5 )
    
    UI.m_loginbar = wx.wxStdDialogButtonSizer()
    UI.m_loginbarOK = wx.wxButton( UI.LoginDialog, wx.wxID_OK, "" )
    UI.m_loginbar:AddButton( UI.m_loginbarOK )
    UI.m_loginbar:Realize();
    
    UI.bSizer3:Add( UI.m_loginbar, 0, wx.wxEXPAND, 5 )
    
    UI.m_staticText4 = wx.wxStaticText( UI.LoginDialog, wx.wxID_ANY, "\n  请对准摄像头，然后点确定。", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    UI.m_staticText4:Wrap( -1 )
    UI.bSizer3:Add( UI.m_staticText4, 0, wx.wxALL, 5 )
    
    
    UI.bSizer2:Add( UI.bSizer3, 0, wx.wxEXPAND, 5 )
    
    
    UI.LoginDialog:SetSizer( UI.bSizer2 )
    UI.LoginDialog:Layout()
    UI.m_cam_timer = wx.wxTimer(UI.LoginDialog, wxID_CAM_TIMER)
    
    UI.m_poll_timer = wx.wxTimer(UI.LoginDialog, wxID_POLL_TIMER)
    
    
    UI.LoginDialog:Centre( wx.wxBOTH )

-- create MainFrame
UI.MainFrame = wx.wxDialog (wx.NULL, wx.wxID_ANY, "已登录正在录屏中...", wx.wxDefaultPosition, wx.wxSize( 378,77 ), wx.wxDEFAULT_FRAME_STYLE+wx.wxTAB_TRAVERSAL )
    UI.MainFrame:SetSizeHints( wx.wxDefaultSize, wx.wxDefaultSize )
    
    UI.mainSizer = wx.wxBoxSizer( wx.wxHORIZONTAL )
    
    UI.m_bitmap2 = wx.wxStaticBitmap( UI.MainFrame, wx.wxID_ANY, wx.wxBitmap( "green.jpg", wx.wxBITMAP_TYPE_ANY ), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    UI.m_bitmap2:SetExtraStyle( wx.wxWS_EX_BLOCK_EVENTS + wx.wxWS_EX_PROCESS_IDLE + wx.wxWS_EX_PROCESS_UI_UPDATES + wx.wxWS_EX_TRANSIENT + wx.wxWS_EX_VALIDATE_RECURSIVELY )
    
    UI.mainSizer:Add( UI.m_bitmap2, 1, wx.wxALL + wx.wxEXPAND, 5 )
    
    UI.m_screenbar = wx.wxStdDialogButtonSizer()
    UI.m_screenbarOK = wx.wxButton( UI.MainFrame, wx.wxID_OK, "" )
    UI.m_screenbar:AddButton( UI.m_screenbarOK )
    -- UI.m_screenbarCancel = wx.wxButton( UI.MainFrame, wx.wxID_CANCEL, "" )
    -- UI.m_screenbar:AddButton( UI.m_screenbarCancel )
    UI.m_screenbar:Realize();
    
    UI.mainSizer:Add( UI.m_screenbar, 1, wx.wxEXPAND + wx.wxALIGN_CENTER_VERTICAL, 5 )
    
    
    UI.MainFrame:SetSizer( UI.mainSizer )
    UI.MainFrame:Layout()
    UI.m_check_timer = wx.wxTimer(UI.MainFrame, wx.wxID_ANY)
    
    UI.MainFrame:Centre( wx.wxBOTH )
    
    

UI.m_connectbarOK:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)   
    local isOk, errMsg = connectServer(http.join(UI.m_address:GetValue(), "/api/accessPointList"))
    if isOk then
        UI.ConnectDialog:Destroy()
        logMsg("ConnectDialog:Destroy()\r\n")
        startLoginDialog()
        return
    end
   
    wx.wxMessageBox(errMsg,
                "连接服务器失败",
                wx.wxOK + wx.wxICON_INFORMATION)
end)


UI.m_connectbarCancel:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function (event)
        logMsg("connect cannel")
        UI.ConnectDialog:Destroy()
        logMsg("ConnectDialog:Destroy()")
        event:Skip()
        logMsg("connect cannel")
    end)

UI.ConnectDialog:Connect(wx.wxEVT_CLOSE_WINDOW,
    function (event)
        UI.ConnectDialog:Destroy()
        logMsg("ConnectDialog:Destroy()")
        event:Skip()
    end)
    



local counter = 0

local camProc
local camPid
local startAt

UI.LoginDialog:Connect(wx.wxEVT_TIMER, function(event)
    
    local eventID = event:GetId()
    if eventID == wxID_POLL_TIMER then
        event:Skip()
    
        local ok, status, msg = pollLoginStatus()
        if not ok then
            wx.wxMessageBox(msg,
                msg,
                wx.wxOK + wx.wxICON_INFORMATION)
        elseif status == "pending" then
            local elapsed = os.difftime(os.time(), startAt)
            local maxtimeout = 1 * 60
            local reqValue = connInfo.request_timeout
            
            if not reqValue then
                if type(reqValue) == "string" and reqValue ~= "" then
                  reqValue = tonumber(reqValue)
                  if reqValue> 0 then
                    interval = reqValue * 1000
                  end
                elseif type(reqValue) == "number" and reqValue > 0 then
                  interval = reqValue * 1000
                end
            end
            
            logMsg("elapsed="..elapsed .. ", timeout="..maxtimeout .. "\r\n")
            if elapsed > maxtimeout then
                if UI.m_poll_timer:IsRunning() then
                  UI.m_poll_timer:Stop()
                  counter = counter - 1
                end
                UI.m_loginbarOK:Enable(true)
                UI.m_loginbarOK:SetLabel("确定")
                
                wx.wxMessageBox("超时",
                    "超时",
                    wx.wxOK + wx.wxICON_INFORMATION)
                
                disconnect()
            else
                return
            end
        elseif status == "ok" then
			if UI.m_poll_timer:IsRunning() then
                UI.m_poll_timer:Stop()
                counter = counter - 1
            end
            UI.LoginDialog:Destroy()
            logMsg("LoginDialog:Destroy()")
            startMainFrame()
            return
        elseif status == "fail" or status == "deny" then
            wx.wxMessageBox(msg,
                msg,
                wx.wxOK + wx.wxICON_INFORMATION)
        end
        
	    if UI.m_poll_timer:IsRunning() then
           UI.m_poll_timer:Stop()
           counter = counter - 1
        end
        
        UI.m_loginbarOK:Enable(true)
        UI.m_loginbarOK:SetLabel("确定")
        return
    end
    
    if camProc ~= nil then
        local foo = readImages()
        if #foo > 0 then
            local lastFile = foo[#foo]
            if #foo >= 2 then
                lastFile = foo[#foo-1]
            end
            -- logMsg(lastFile)
            
            -- local imagefilename = wx.wxFileName(images, lastFile):GetFullPath()
            local image = wx.wxImage(lastFile)
            local size = UI.m_cam_bitmap:GetSize()
            image = image:Rescale(size:GetWidth(), size:GetHeight())    
            UI.m_cam_bitmap:SetBitmap(wx.wxBitmap(image))
            imagefile = lastFile
            
            removeImages(foo, lastFile)
        end
    
       local input = camProc:GetInputStream () 
       local data = ""
       while input:CanRead () do
         data = data .. input:Read(100)
       end
       logMsg(data)
       
       input = camProc:GetErrorStream () 
       local data = ""
       while input:CanRead () do
         data = data .. input:Read(100)
       end
       logMsg(data)
       
       
       event:Skip()
       return
    end
    
    camProc = wx.wxProcess()
    camProc:Redirect()
    camProc:Connect(wx.wxEVT_END_PROCESS, function(event) 
        camProc = nil
        camPid = nil
    end)
    
    logMsg("run " .. camToImage)
    local pid = wx.wxExecute(camToImage, wx.wxEXEC_ASYNC, camProc)
    if not pid or pid == -1 or pid == 0 then
        camProc = nil
        camPid = nil
        UI.m_cam_timer:Stop()
        counter = counter - 1
        
        wx.wxMessageBox(("Program unable to run as '%s'."):format(cmd),
                    "运行命令失败",
                    wx.wxOK + wx.wxICON_INFORMATION,
                    UI.LoginDialog)
        return
    end
    camPid = pid
    event:Skip()
end)

UI.m_loginbarOK:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
    UI.m_cam_timer:Stop()
    counter = counter - 1
    if camPid ~= nil then
        wx.wxKill(camPid, wx.wxSIGINT)
        camProc = nil
        camPid = nil
    end
   
    local isOk,errMsg = sendLoginRequest()
    if isOk then
      interval = 5000
      if not connInfo.request_poll_interval then
        local value = connInfo.request_poll_interval
        if type(value) == "string" and value ~= "" then
          value = tonumber(value)
          if value > 0 then
            interval = value * 1000
          end
        elseif type(value) == "number" and value > 0 then
          interval = value * 1000
        end
      end
      UI.m_loginbarOK:SetLabel("申请中...")
      UI.m_loginbarOK:Disable()
      UI.m_poll_timer:Start(interval)
      counter = counter + 1
      startAt = os.time()
      
      local foo = readImages()
      removeImages(foo, "")
      return
    end
   
    wx.wxMessageBox(errMsg,
                "申请接入失败",
                wx.wxOK + wx.wxICON_INFORMATION)
   
    local foo = readImages()
    removeImages(foo, "")
    UI.m_cam_timer:Start(50)
    counter = counter + 1
end)


function startLoginDialog() 
    logMsg("=====begin\r\n")
    UI.m_endpoints:Clear()
    for _, value in ipairs(connInfo.list) do
        logMsg(value["name"].."\r\n")
        UI.m_endpoints:Append(value["name"])
    end
    logMsg("=====end\r\n")

    UI.m_cam_timer:Start(50)
    counter = counter + 1
    -- show the frame window
    result = UI.LoginDialog:Show(true)
end


UI.LoginDialog:Connect(wx.wxEVT_CLOSE_WINDOW,
    function (event)
        
        UI.LoginDialog:Destroy()
        logMsg("LoginDialog:Destroy() at Close\r\n")
        event:Skip()
        
        UI.m_cam_timer:Stop()
        counter = counter - 1
        logMsg("counter=" .. counter.."\r\n")
        if camPid ~= nil then
            wx.wxKill(camPid, wx.wxSIGINT)
            camProc = nil
            camPid = nil

            removeImages(readImages(), "")
        end
        
        os.exit(1)
    end)

local screenProc
local screenPid
local pingProc
local pingPid
local pingOK = true
UI.MainFrame:Connect(wx.wxEVT_TIMER, function(event)
    event:Skip()
    
    if screenProc then
       logMsg("111\r\n")
       local input = screenProc:GetInputStream () 
       local data = ""
       while input:CanRead () do
         data = data .. input:Read(100)
       end
       logMsg(data)
       
       input = screenProc:GetErrorStream () 
       local data = ""
       while input:CanRead () do
         data = data .. input:Read(100)
       end
       logMsg(data)
    end
    
    if pingProc ~= nil then
       return
    end

    
    local ok, point = getCurrentAccessPoint()
    if not ok then
        wx.wxMessageBox("访问点的 IP 为空, 将无法判断网络是否断开",
                "运行命令失败",
                wx.wxOK + wx.wxICON_INFORMATION)
        UI.m_check_timer:Stop()
        counter = counter - 1
        return
    end
    if point.ip == nil or point.ip == "" then
        wx.wxMessageBox("访问点的 IP 为空, 将无法判断网络是否断开",
                "运行命令失败",
                wx.wxOK + wx.wxICON_INFORMATION)
        UI.m_check_timer:Stop()
        counter = counter - 1
        return
    end
    
    local command = "ping ".. point.ip .. "-c 4"
    if isWindow then
       command = "ping ".. point.ip
    end
    
    logMsg("run " .. command.."\r\n")
    pingProc = wx.wxProcess()
    pingProc:Redirect()
    pingProc:Connect(wx.wxEVT_END_PROCESS, function(event)
        event:Skip()
        
        local inputStream = pingProc:GetInputStream ()
        pingProc = nil
        pingPid = nil

        local out = inputStream:Read(100)
        while not inputStream:Eof() do
            out = out .. inputStream:Read(100)
        end
        logMsg(out)

        local found = string.find(out, "100%% 丢失")
        if found then
            if pingOK then
				pingOK = false
				local image = wx.wxImage("red.jpg")
				local size = UI.m_bitmap2:GetSize()
				image = image:Rescale(40, 40)
				UI.m_bitmap2:SetBitmap(wx.wxBitmap(image))
				logMsg("连接已断开\r\n")
            end
        else
            if not pingOK then
				pingOK = true
				local image = wx.wxImage("green.jpg")
				local size = UI.m_bitmap2:GetSize()
				image = image:Rescale(40, 40)
				UI.m_bitmap2:SetBitmap(wx.wxBitmap(image))
				logMsg("连接已断开\r\n")
            end
        end
        logMsg("ping exit\r\n")
        
		UI.MainFrame:ProcessEvent(wx.wxCommandEvent(wx.wxEVT_CLOSE_WINDOW, UI.MainFrame:GetId()))
    end)
    
    pingPid = wx.wxExecute(command, wx.wxEXEC_ASYNC, pingProc)
    if not pingPid or pingPid == -1 or pingPid == 0 then
        pingProc = nil
        return
    end
end)

function startMainFrame()
    UI.MainFrame:Show(true)
   
    screenProc = wx.wxProcess()
    -- 加了下面一行后，视频流一会会断开
    -- 后面发现好像定时从重定向流中读出输出就好了
    screenProc:Redirect()
    screenProc:Connect(wx.wxEVT_END_PROCESS, function(event)
        screenProc = nil
        screenPid = nil
        
        wx.wxMessageBox("推流失败",
                    "推流失败",
                    wx.wxOK + wx.wxICON_INFORMATION)

        event:Skip()
        logMsg("screen exit\r\n")
        
		UI.MainFrame:ProcessEvent(wx.wxCommandEvent(wx.wxEVT_CLOSE_WINDOW, UI.MainFrame:GetId()))
    end)

    local command = screenToMediaServer .. "  \"" .. connInfo.media_server .. connID .. "\""
    logMsg("run " ..command.."\r\n")
    screenPid = wx.wxExecute(command , wx.wxEXEC_ASYNC, screenProc)
    if not screenPid or screenPid == -1 or screenPid == 0 then
        screenProc = nil
        wx.wxMessageBox(("Program unable to run as '%s'."):format(command),
                    "运行命令失败",
                    wx.wxOK + wx.wxICON_INFORMATION)
        return
    end
    UI.m_check_timer:Start(1000)
    counter = counter + 1
    UI.MainFrame:Show(true)
end



local exited = false
function stopScreen()
        logMsg("0\r\n")
        
        if not exited then
            if UI.m_check_timer:IsRunning() then
               UI.m_check_timer:Stop()
               counter = counter - 1
            end
            disconnect()
        end
        
        if pingPid and pingPid > 0 then
            logMsg("kill ping\r\n")
            
            local killResult = wx.wxKill(pingPid, wx.wxSIGINT)
            if killResult ~= wx.wxKILL_OK and killResult ~= wx.wxKILL_NO_PROCESS then
                killResult = wx.wxKill(pingPid, wx.wxSIGKILL)
                if killResult ~= wx.wxKILL_OK and killResult ~= wx.wxKILL_NO_PROCESS then
                    wx.wxMessageBox(("Program unable to run as '%s'."):format(killResult),
                                "停止 ping 命令失败",
                                wx.wxOK + wx.wxICON_INFORMATION)
                end
            end
            return
        end
        
        if screenPid and screenPid > 0 then
            logMsg("kill screen\r\n")
            local killResult = wx.wxKill(screenPid, wx.wxSIGINT)
            if killResult ~= wx.wxKILL_OK and killResult ~= wx.wxKILL_NO_PROCESS then
                killResult = wx.wxKill(screenPid, wx.wxSIGKILL)
                if killResult ~= wx.wxKILL_OK and killResult ~= wx.wxKILL_NO_PROCESS then
                    wx.wxMessageBox(("Program unable to run as '%s'."):format(killResult),
                                "停止截屏命令失败",
                                wx.wxOK + wx.wxICON_INFORMATION)
                end
            end
            return
        end
        
        logMsg("1")
        if not exited then
            exited = true

            logMsg("2")
            UI.MainFrame:Destroy()
            logMsg("MainFrame:Destroy()\r\n")
            logMsg("counter=" .. counter.."\r\n")
            
            os.exit(1)
        end
        
        logMsg("3\r\n")
    end

UI.MainFrame:Connect(wx.wxEVT_CLOSE_WINDOW, function(event)
        event:Skip()
        stopScreen()
        end)
UI.m_screenbarOK:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
        event:Skip()
        stopScreen()
        end)

UI.ConnectDialog:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
