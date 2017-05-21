local util_table = require "util.table"
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


return _M