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

string.encodeURI = function(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

string.decodeURI = function(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
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