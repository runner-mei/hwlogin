--
-- Copyright (c) 2020 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

require("multipart.utils")
local Parser = require("multipart.formdata-parser")
local Builder = require("multipart.formdata-builder")

local arg_filename = ...
if arg_filename == nil then
    print("Usage: lua run_test.lua TEST_TABLE_LUA")
    os.exit(0)
end

-- run test interface
--

local _M = {}
_M.__index = {}

function _M:readHeader(content)
    local s, e = content:find("\r\n\r\n")
    local substr = content:sub(1, s + 2)
    local tbl = {}
    for i, line in ipairs(substr:split("\r\n")) do
        if i > 1 and line:len() > 0 then
            local kv = line:split(": ")
            tbl[kv[1]] = kv[2]
        end
    end
    return tbl, content:sub(e + 1)
end

function _M:runTestCase(filepath, callback)
    local content = io.readFile(filepath)
    local header_tbl, body = self:readHeader(content)
    local fd_tbl = {} -- context
    local buf_size = 8192
    if Parser.isMultiPartFormData(fd_tbl, "POST", header_tbl) then
        repeat
            local len = math.min(buf_size, body:len())
            local data = body:sub(1, len)
            body = (body:len() > len) and body:sub(len + 1) or ""
            Parser.multiPartReadBody(fd_tbl, data, callback)
        until body:len() <= 0
    end
end

--[[ result tbl would be
    {
        case_name = "",
        result = {
            [1] = {
                name = "",
                content_type = ""
            },
            [2] = ...
        },
    },
]]
function _M:runTestCaseCompare(case_name, path, result_tbl)
    local idx = 1
    local success_count = 0
    local failed_count = 0
    self:runTestCase(
        path,
        function(name, content_type, data)
            if data ~= nil then
                return
            end
            local rtbl = result_tbl[idx]
            if name == rtbl.name and content_type == rtbl.content_type then
                success_count = success_count + 1
            else
                failed_count = failed_count + 1
            end
            idx = idx + 1
        end
    )
    io.write(string.format("(s:%d f:%d)  ", success_count, failed_count))
    if success_count + failed_count == #result_tbl then
        if failed_count > 0 then
            print(case_name .. "\t FAILED !!!")
        else
            print(case_name .. "\t PASSED")
        end
    else
        print(case_name .. "\t PASSED")
    end
end

--[[
    test_case_tbl would be
    {
        [1] = {
            case_name = "",
            result = {
                [1] = {
                        name = "",
                        content_type = ""
                },
                [2] = ...
            },
        },
        [2] = ...
    }
]]
function _M:runTestCaseFile(filename)
    print("-- parser test case")
    local tbl = dofile(filename)
    for _, test_case in ipairs(tbl) do
        local case_name = test_case.case_name
        local path = "testcase/" .. case_name
        local result_tbl = test_case.result
        self:runTestCaseCompare(case_name, path, result_tbl)
    end
end

-- Builder test case
--

local function _writeFile(path, content)
    local fp = io.open(path, "wb")
    if fp then
        fp:write(content)
        fp:close()
    end
end

function _M:runTestCaseBuilder()
    print("-- builder test case")
    do
        -- 00
        local b00 = Builder.newBuilder()
        local c00 = "POST /playground HTTP/1.1\r\n"
        c00 = c00 .. "Content-Type: " .. b00:contentType() .. "\r\n"
        c00 = c00 .. b00:disposition("text/plain", "file1", "fname")
        c00 = c00 .. "any content" .. "\r\n"
        --
        c00 = c00 .. b00:finishDisposition()
        --
        local case_name = "build_case_00.txt"
        local path = "testcase/" .. case_name
        _writeFile(path, c00)
        local result_tbl = {
            {
                name = "fname",
                content_type = "text/plain"
            }
        }
        self:runTestCaseCompare(case_name, path, result_tbl)
    end
    do
        -- 11
        local b01 = Builder.newBuilder()
        local c01 = "POST /playground HTTP/1.1\r\n"
        c01 = c01 .. "Content-Type: " .. b01:contentType() .. "\r\n"
        c01 = c01 .. b01:disposition("text/plain", "file1", "f1name")
        c01 = c01 .. "1st content" .. "\r\n"
        --
        c01 = c01 .. b01:disposition("text/plain", "file2", "f2name")
        c01 = c01 .. "2nd content" .. "\r\n"
        --
        c01 = c01 .. b01:finishDisposition()
        --
        local case_name = "build_case_01.txt"
        local path = "testcase/" .. case_name
        _writeFile(path, c01)
        local result_tbl = {
            {
                name = "f1name",
                content_type = "text/plain"
            },
            {
                name = "f2name",
                content_type = "text/plain"
            }
        }
        self:runTestCaseCompare(case_name, path, result_tbl)
    end
end

math.randomseed(os.time())
_M:runTestCaseFile(arg_filename)
_M:runTestCaseBuilder()
