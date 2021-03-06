
xstr = require("xstr")
url = require("neturl")
require("wx")


local mp = require("multipart")


local arg_filename = ...
if arg_filename == nil then
    print("Usage: lua run_test.lua TEST_TABLE_LUA")
    os.exit(0)
end



stdpaths = wx.wxStandardPaths.Get()
osinfo = wx.wxPlatformInfo.Get()
isWindow = osinfo:GetOperatingSystemFamilyName() == "Windows"
local currentWorkDirectory = wx.wxFileName(stdpaths:GetExecutablePath()):GetPath(wx.wxPATH_GET_VOLUME or wx.wxPATH_GET_SEPARATOR)
local curl = wx.wxFileName(currentWorkDirectory, "curl.exe"):GetFullPath()
if not isWindow then
  curl = "/usr/bin/curl"
end


function log(msg) 
  print(msg)
end 

function join(baseURL, pa) 
  if xstr:endswith(baseURL, "/") then
    if xstr:startswith(pa, "/") then
      return string.sub(baseURL, 0, string.len(baseURL)-1) .. pa
    else
      return baseURL .. pa
    end
  else
    if xstr:startswith(pa, "/") then
      return baseURL .. pa
    else
      return baseURL .. "/" .. pa
    end
  end
end

function dump(o)
 if type(o) == "table" then
    for k, v in pairs(o) do
      log(k)
      log(v)
    end
    for i, v in ipairs(o) do
      log(k)
      log(v)
    end
  else
    log(o)
  end
end

local testCases = {
   {
     a= "a",
     b= "b",
     result = "a/b",
   },
   {
     a= "a/",
     b= "b",
     result = "a/b",
   },
   {
     a= "a/",
     b= "/b",
     result = "a/b",
   },
   {
     a= "a",
     b= "/b",
     result = "a/b",
   }
}

for _, a in ipairs(testCases) do 
  local actual = join(a.a, a.b)
  if actual ~= a.result then
    log("ERROR: a=" ..a.a .. ", b=" ..a.b .. ", result=" ..a.result)
  else
    log("   OK: a=" ..a.a .. ", b=" ..a.b .. ", result=" ..a.result)
  end
end

function get(pa)
  local u = url.parse(pa)
  if not u.host then
    return {
      isOk = false,
      status = 500,
      error = "host 参数不正确 - '".. pa .."'",
      }
  end
  
  
  local address = wx.wxIPV4address()
  address:Hostname( u.host )  
  if u.port then
    address:Service( u.port ) -- irc port
  else
    address:Service( 80 ) -- irc port
  end
  
  local http = wx.wxHTTP()
  http:Connect( address )
  local rpath = u.path
  if u.query and #(u.query) > 0 then
   rpath = u.path .. "?" .. url.buildQuery(u.query)
  end

  
  local response = http:GetInputStream(rpath)
  if not response then
    return {
      isOk = false,
      status = 500,
      output = rpath,
      }
  end
  local output = response:Read(100)
  while (not response:Eof()) do
    output = output..response:Read(100)
  end
  local statusCode = http:GetResponse()
  
  return {
  isOk = true,
  status = statusCode,
  output = wx.wxString.FromUTF8(output),
  }
end

function postOld(pa, contentType, body)
  local u = url.parse(pa)
  if not u.host then
    return {
      isOk = false,
      status = 500,
      error = "host 参数不正确 - '".. pa .."'",
      }
  end
  
  local address = wx.wxIPV4address()
  if pcall(address:Hostname( u.host ), -1) == -1 then
    return 
  end
  if u.port then
    address:Service( u.port ) -- irc port
  else
    address:Service( 80 ) -- irc port
  end
  
  local http = wx.wxHTTP()
  http:Connect( address )
  local rpath = u.path
  if u.query and #(u.query) > 0 then
   rpath = u.path .. "?" .. url.buildQuery(u.query)
  end

  http:SetMethod("POST")
  http:SetHeader("Content-Type", contentType)

  http:SetPostText(contentType, body)
  print(contentType)
  print(data)
  local response = http:GetInputStream(rpath)

  local output = ""
  if response then
    output = response:Read(100)
    while (not response:Eof()) do
      output = output..response:Read(100)
    end
    print(output)
  else
    print("empty")
  end

  local statusCode = http:GetResponse()
  print(statusCode)
  return {
  isOk = true,
  status = statusCode,
  output = wx.wxString.FromUTF8(output),
  }
end

function postWithFilesOld(pa, body, files)
  local openFiles = {}


  local multipart = mp.new()
  for k, v in pairs(body) do
    if type(v) == "number" then
      multipart:addField(k, ""..v)
    else
      multipart:addField(k, v)
    end
  end
  for k, v in pairs(files) do
    multipart:addFile(key, v, "image/jpeg", key)
  end

   
  local data, boundary = mp.encode(body)
  -- for i, file in ipairs(openFiles) do
  --  file:close()
  -- end

  print("=====boundary")
  print(multipart.boundary)
  print("=====data")
  print(multipart.getBody())
  print("=====")
  return postOld(pa, "multipart/form-data; boundary="..multipart.boundary, multipart.getBody())
end

function concat(o, delm) 
  local result = ""
  for k, v in ipairs(o) do
    if result == "" then
      result = v
    end
    result = result .. delm .. v
  end
  return result
end

function doHttp(command)
    log(command)
    local a, out, err = wx.wxExecuteStdoutStderr(command, wx.wxEXEC_SYNC)
    if not a or a ~= 0 then        
        return {
          command = command,
          isOk = false,
          status = 500,
          output =  wx.wxString.FromUTF8(concat(err, "\r\n")),
        }
    end
    
    return {
      isOk = true,
      status = 200,
      output = wx.wxString.FromUTF8(concat(out, "\r\n")),
    }
end

function postWithFiles(pa, body, files) 
   local command = curl .. " -X POST -s -S "
   for k, v in pairs(body) do
     command = command .. " -F \"" .. k .. "=" .. string.gsub(v, "\"", "\\\"") .. "\" "
   end
   for k, v in pairs(files) do
     command = command .. " -F \"" .. k .. "=@" .. v .. "\" "
   end
   
   command = command .. " " .. pa 
   return doHttp(command)
end

function post(pa, contentType, body)
  local command = curl .. " -X POST -s -S -H \"Content-Type: "..contentType .. "\""
   
  if type(body) == "string" then
   command = command .. " -d \"" .. string.gsub(body, "\"", "\\\"") .. "\" "
  else
    for k, v in pairs(body) do
      command = command .. " -F \"" .. k .. "=" .. string.gsub(v, "\"", "\\\"") .. "\" "
    end
  end

  command = command .. " " .. pa
  return doHttp(command)
end


function delete(pa, contentType, body)
  local command = curl .. " -X DELETE -s -S -H \"Content-Type: "..contentType .. "\""
   
  if type(body) == "string" then
   command = command .. " -d \"" .. string.gsub(body, "\"", "\\\"") .. "\" "
  else
    for k, v in pairs(body) do
      command = command .. " -F \"" .. k .. "=" .. string.gsub(v, "\"", "\\\"") .. "\" "
    end
  end
   
  command = command .. " " .. pa
  return doHttp(command)
end

-- local response = get("http://127.0.0.1/hengwei/home")
-- dump(response) 

    
-- local response = postOld("http://127.0.0.1/hengwei/sessions/login", "application/json", {a="\"b"})
-- dump(response)


local response = postOld("http://127.0.0.1/hengwei/sessions/login", "application/json", "{\"a\":\"b\"}")
dump(response) 


return {
  get = get,
  post = post,
  postWithFiles = postWithFilesOld,
  -- postWithFiles = postWithFiles,
  delete = delete,
  join = join,
}