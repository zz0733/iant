local util_table = require "util.table"
local _M = util_table.new_table(0, 2)
_M._VERSION = '0.01'

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local match = ngx.re.match
local utf8 = require("3th.utf8")
local utf8sub = utf8.sub
local utf8len = utf8.len

local cn_maps = {
    ["一"] = 1,   
    ["二"] = 2,   
    ["三"] = 3,   
    ["四"] = 4,   
    ["五"] = 5,   
    ["六"] = 6,   
    ["七"] = 7,   
    ["八"] = 8,   
    ["九"] = 9,   
    ["十"] = 10,   
 }
 local STR_NUM_REG = [["0-9一二三四五六七八九十"]]


 local convert_number = function ( name )
     if not name then
         return 
     end
     local dest = ""
     local len = utf8len(name)
     for i=1,len do
         local unit = utf8sub(name,i,i)
         local num_val = cn_maps[unit]
         dest = dest .. (num_val or unit)
     end
     return tonumber(dest)
 end

function _M.find_season(title)
    if not title then
        return
    end
    local m = match(title, "第(?<snum>["..STR_NUM_REG.."]+)(部|季)","joi")
    if m and m.snum then
        return convert_number(m.snum)
    end
    local mmm = match(title, "[^a-z]S(?<snum>[0-9]+)E[0-9]+","joi")
    if mmm and mmm.snum then
        return convert_number(mmm.snum)
    end
end

function _M.find_episode(title)
    if not title then
        return
    end
    local m = match(title, "(更新至|连载至|EP)(?<enum>["..STR_NUM_REG.."]+)[集]?","joi")
    if m and m.enum then
        return convert_number(m.enum)
    end
    local mm = match(title, "(?<enum>["..STR_NUM_REG.."]+)\\.[a-zA-Z0-9]{1,4}$","joi")
    if mm and mm.enum then
        return convert_number(mm.enum)
    end  
    local mmm = match(title, "[^a-z]S[0-9]+E(?<enum>[0-9]+)","joi")
    if mmm and mmm.enum then
        return convert_number(mmm.enum)
    end
end

return _M