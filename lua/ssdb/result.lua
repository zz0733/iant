local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_string = require "util.string"
local util_context = require "util.context"
local ssdb_client = require "ssdb.client"

local uuid = require 'resty.jit-uuid'
uuid.seed()        ---> automatic seeding with os.time(), LuaSocket, or ngx.time()

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 2)
_M._VERSION = '0.02'

local KEY_PREFIX = "R_"
local ORIGIN_KEY_START = string.len(KEY_PREFIX)  + 1

local levelArr = {}
table.insert(levelArr, 2)
table.insert(levelArr, 1)
table.insert(levelArr, 0)


function _M:toSSDBKey( key )
  return KEY_PREFIX .. tostring(key)
end

function _M:toBean( sVal )
   if not sVal then
      return nil
   end
   local jsonVal =  cjson_safe.decode(sVal)
   if jsonVal and not util_table.is_table(jsonVal) then
      jsonVal = nil
   end
   return jsonVal
end



function _M:qpush(level, ...)
   level = level or 1
   local resultArr = {...}
   for ti,result_val in ipairs(resultArr) do
      if util_table.is_table(result_val) then
        result_val =  cjson_safe.encode(result_val)
        resultArr[ti] = result_val
      end
   end
   local client =  ssdb_client:open();
   local ret, err = client:qpush_back(self:toSSDBKey(level), unpack(resultArr))
   ssdb_client:close(client)
   return ret, err
end


function _M:qpop(size)
   size = size or 1
   local client =  ssdb_client:open();
   local assignArr = {}
   local count = size
   for _, level in ipairs(levelArr) do
      local ssdbKey = self:toSSDBKey(level)
      local ret, err = client:qpop_front(ssdbKey, count)
      if not util_table.isNull(ret) then
          for _,tv in ipairs(ret) do
                local tvObj = self:toBean(tv)
                if not tvObj.task then
                  for _, result in ipairs(tvObj) do
                    if  type(result) == "string" then
                      result = self:toBean(result)
                    end
                    table.insert(assignArr, result)
                  end
                else
                  table.insert(assignArr, tvObj)
                end
          end
      end
      count = size - #assignArr
      if count < 1 then
        break
      end
   end
   ssdb_client:close(client)
   -- log(ERR,"assignArr:" .. cjson_safe.encode(assignArr))
   return assignArr
end

return _M