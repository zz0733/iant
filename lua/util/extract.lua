local util_table = require "util.table"
local _M = util_table.new_table(0, 2)
_M._VERSION = '0.01'

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local match = ngx.re.match
local gmatch = ngx.re.gmatch
local utf8 = require("3th.utf8")
local utf8sub = utf8.sub
local utf8len = utf8.len

local cjson_safe = require("cjson.safe")


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

 function convert_number_safe( name )
    local ok, t = pcall(convert_number, name)
    if not ok then
      return nil
    end

    return t
end

function iterator_numbers( iterator, max_num )
    local numbers = {}
    if not iterator then
        return numbers
    end
    while true do
      local m, err = iterator()
      log(ERR,"m:",cjson_safe.encode(m))
      if not m or err then
         break
      else
         local num = m.num or m[0]
         num = convert_number_safe(num)
         if num then
             if max_num then
                if num <= max_num then
                    table.insert(numbers,num)
                end
             else
                table.insert(numbers,num)
             end
         end
      end
    end
    return numbers
end

function max_number( numbers, max )
    if #numbers < 1 then
        return nil
    end
    table.sort( numbers )
    return numbers[#numbers]
end

function _M.find_season(title)
    if not title then
        return
    end
    local m = match(title, "第(?<snum>["..STR_NUM_REG.."]+)(部|季)","joi")
    if m and m.snum then
        return convert_number_safe(m.snum)
    end
    local mmm = match(title, "[^a-z]S(?<snum>[0-9]+)E[0-9]+","joi")
    if mmm and mmm.snum then
        return convert_number_safe(mmm.snum)
    end
end

function _M.find_episode(title)
    if not title then
        return
    end
    local max_num = 1000
    local it = gmatch(title, "(更新至|连载至|EP|第)(?<num>["..STR_NUM_REG.."]+)[集话]?","joi")
    local numbers = iterator_numbers(it,max_num)
    if #numbers > 0 then
        return max_number(numbers)
    end

    local it = gmatch(title, "(?<num>["..STR_NUM_REG.."]+)\\.[a-zA-Z0-9]{1,4}$","joi")
    local numbers = iterator_numbers(it,max_num)
    if #numbers > 0 then
        return max_number(numbers)
    end
    local it = gmatch(title, "[\\(（\\[【](?<num>["..STR_NUM_REG.."]+)[\\)）\\]】][\\W]*$","joi")
    local numbers = iterator_numbers(it,max_num)
    if #numbers > 0 then
        return max_number(numbers)
    end
    local it = gmatch(title, "[^a-z]S[0-9]+E(?<num>[0-9]+)","joi")
    local numbers = iterator_numbers(it,max_num)
    if #numbers > 0 then
        return max_number(numbers)
    end
    local it = gmatch(title, "(?<num>[0-9]+)","joi")
    local numbers = iterator_numbers(it,max_num)
    if #numbers > 0 then
        return max_number(numbers)
    end
end

return _M