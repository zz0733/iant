local util_table = require "util.table"
local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local script_dao = require("dao.script_dao")
local cjson_safe = require("cjson.safe")


local shared_dict = ngx.shared.shared_dict
local scrip_type_key = "scrip_types"


 function _M.load_types()
     local start = ngx.now()
     local resp,status = script_dao:search_all_ids()
     ngx.update_time()
     local cost = (ngx.now() - start)
     cost = tonumber(string.format("%.3f", cost))
     local count = nil
     if resp then
        local hits  = resp.hits.hits
        local total  = resp.hits.total
        log(ERR,"script,load,total:" .. total ..",cost:" .. cost)
        local types = {}
        if total > 0 then
            for _,v in ipairs(hits) do
                types[#types + 1] = v._id
            end
        else
            types = cjson.empty_array
        end
        local types_val = cjson_safe.encode(types)
        local ok, err = shared_dict:set(scrip_type_key, types_val )
        if err then
            log(CRIT,"fail.script.set,types:" .. types_val .. ",count:" .. #types ..",total:" ..total .. ",cause:", err)
            status = err
        else 
            log(ERR,"script.set,types:" .. types_val .. ",count:" .. #types ..",total:" ..total)
            count = total
        end
     else
        log(CRIT,"fail.script,load,cost:" .. cost .. ",cause:", status)
     end
     return count, status
 end

return _M