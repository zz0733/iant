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