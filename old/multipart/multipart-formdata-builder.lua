--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

-- multipart/form-data builder, with usage in the end
--

local _Builder = {}
_Builder.__index = _Builder

local _byte = string.byte
local _char = string.char

local _b0 = _byte("0")
local _ba = _byte("a")
local _bA = _byte("A")

-- [0 ~ bound]
local function _code(num)
    if num <= 10 then
        return _char(_b0 + num - 1)
    elseif num <= 36 then
        return _char(_ba + num - 11)
    else
        return _char(_bA + num - 37)
    end
end

-- return HTTP header 'Content-Type' value, with last '\r\n'
function _Builder:contentType()
    if not self._boundary then
        self._boundary = "----mBuildFormBoundary"
        local tbl = {}
        for i = 1, 16, 1 do
            tbl[#tbl + 1] = _code(math.random(62)) -- 62 stands 10 + 26 + 26
        end
        self._boundary = self._boundary .. table.concat(tbl)
        self._count = 0
    end
    return "multipart/form-data; boundary=" .. self._boundary .. "\r\n"
end

--[[ run contentType() first
------WebKitFormBoundaryDUFCCIKgwbWP5UT3
Content-Disposition: form-data; name="name"; filename="filename"
Content-Type: text/plain
]]
function _Builder:disposition(content_type, name, filename)
    if content_type and name and filename and self._boundary then
        self._count = self._count + 1
        local tbl = {"--" .. self._boundary}
        tbl[#tbl + 1] = string.format('Content-Disposition: form-data; name="%s"; filename="%s"', name, filename)
        tbl[#tbl + 1] = "Content-Type: " .. content_type
        return table.concat(tbl, "\r\n") .. "\r\n\r\n"
    end
    return ""
end

-- run contentType() and disposition() first, with last '\r\n\r\n'
function _Builder:finishDisposition()
    if self._boundary and self._count > 0 then
        return "\r\n--" .. self._boundary .. "--\r\n"
    end
    return ""
end

--[[
    usage:
    1. contentType()
    2. disposition()
    3. [ file_1_data ]
    4. disposition()
    5. [ file_2_data ]
    ...
    6. finishDisposition()
]]
return {
    newBuilder = function()
        return setmetatable({}, _Builder)
    end
}
