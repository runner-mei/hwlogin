
function string:split(sSeparator, nMax, bRegexp)
    assert(sSeparator ~= "")
    assert(nMax == nil or nMax >= 1)
    local aRecord = {}
    if self:len() > 0 then
        local bPlain = not bRegexp
        nMax = nMax or -1
        local nField, nStart = 1, 1
        local nFirst, nLast = self:find(sSeparator, nStart, bPlain)
        while nFirst and nMax ~= 0 do
            aRecord[nField] = self:sub(nStart, nFirst - 1)
            nField = nField + 1
            nStart = nLast + 1
            nFirst, nLast = self:find(sSeparator, nStart, bPlain)
            nMax = nMax - 1
        end
        aRecord[nField] = self:sub(nStart)
    else
        aRecord[1] = ""
    end
    return aRecord
end

function io.readFile(file_path)
    local f = io.open(file_path, "rb")
    if f then
        local data = f:read("*a")
        f:close()
        return data
    end
    return nil
end

function io.appendFile(file_path, data)
    local f = io.open(file_path, "a+")
    if f then
        f:write(data)
        f:close()
        return true
    end
    return false
end