local bit = require("bit")
local cjson_safe = require("cjson.safe")

string.split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

string.startsWith = function(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

string.endsWith = function(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

string.contains = function (String, source )
    return string.find(String, source) ~= nil
end

string.encodeURI = function(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

-- Encodes a character as a percent encoded string
local function char_to_pchar(c)
    return string.format("%%%02X", c:byte(1,1))
end

-- encodeURI replaces all characters except the following with the appropriate UTF-8 escape sequences:
-- ; , / ? : @ & = + $
-- alphabetic, decimal digits, - _ . ! ~ * ' ( )
-- #
string.encodeURI = function (str)
    return (str:gsub("[^%;%,%/%?%:%@%&%=%+%$%w%-%_%.%!%~%*%'%(%)%#]", char_to_pchar))
end

-- encodeURIComponent escapes all characters except the following: alphabetic, decimal digits, - _ . ! ~ * ' ( )
string.encodeURIComponent = function(str)
    return (str:gsub("[^%w%-_%.%!%~%*%'%(%)]", char_to_pchar))
end

string.random = function(length)
    -- A-Z,065-090
    -- a-z,097-122
    -- 0-9,048-057
    math.randomseed(ngx.time())  
    local base = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    local len = string.len(base)
    local str = "";
    for i = 1, length do
        local index = math.random(1, len)
        str = str..string.sub(base,index,index);
    end
    return str;
end

string.isString = function(src)
    return type(src) == "string";
end

string.escape = function(src)
    return string.gsub(src,"([^\\])%-","%1%%%-")
end

string.suffixIfAbsent = function(source, suffix)
    if suffix and not string.contains(source,  tostring(suffix) ) then
        source = source .. suffix
    end
    return source
end

string.toHashCode = function (source)
    local hash = 0
    if not source then
        return hash
    end
    for i=1,#source do
        local chr = source:byte(i)
        hash = (bit.lshift(hash, 5) - hash) + chr
        hash = bit.bor(hash)
    end
    return hash
end

string.toUnsignHashCode = function (source)
    local hash = string.toHashCode(source)
    local sCode = tostring(hash)
    sCode = sCode:gsub("^-","0")
    return sCode
end

string.error = function (...)
    local args = {... }
    ngx.log(ngx.ERR, cjson_safe.encode(args))
end



return string