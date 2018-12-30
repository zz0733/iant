local util_table = require "util.table"
local cjson_safe = require "cjson.safe"
local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


function _M.sub(array, offset, limit )
    if not array then
       return
    end
    local arr_len = #array
    offset = tonumber(offset) or 1
    limit = tonumber(limit) or arr_len
    local to_index = math.min(offset + limit, arr_len)
    local sub_arr = {}
    for i=offset,to_index do
       sub_arr[#sub_arr + 1] = array[i]
    end
    return sub_arr
end

function _M.byte2string(bytes)
  local s = ""
  for _,v in ipairs(bytes) do
      s = s .. string.char(v)
  end
  return s
end

function _M.swap(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
end

function _M.shuffle(array)
    local counter = #array
    while counter > 1 do
        -- math.randomseed(tostring(os.time()):reverse():sub(1, 6))
        local index = math.random(counter)
        _M.swap(array, index, counter)
        counter = counter - 1
    end
end

function _M.emptyArray(inObj, ... )
   if not inObj then
    return 
  end
  local fields = {...}
  for _,key in ipairs(fields) do
    local val_obj = inObj[key]
    if val_obj and util_table.is_empty_table(val_obj) then
       inObj[key] = cjson_safe.empty_array
    end
  end
end

return _M