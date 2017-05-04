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