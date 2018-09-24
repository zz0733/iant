local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_string = require "util.string"
local util_context = require "util.context"
local ssdb_client = require "ssdb.client"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 2)
_M._VERSION = '0.02'

local KEY_PREFIX = "T_"
local ORIGIN_KEY_START = string.len(KEY_PREFIX)  + 1

local levelArr = {}
table.insert(levelArr, 2)
table.insert(levelArr, 1)
table.insert(levelArr, 0)

function _M:open( )
   local client,err = ssdb_client:newClient();
   if err then
      return nil, err
   end
   return client
end
function _M:close( client )
   if not client then
      return
   end
   local ok, err = client:set_keepalive(0, 20)
   if err then
      log(ERR,"failed to set keepalive:", err)
   end
end

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
   local tasks = {...}
   for ti,task_val in ipairs(tasks) do
      if util_table.is_table(task_val) then
        task_val =  cjson_safe.encode(task_val)
        tasks[ti] = task_val
      end
   end
   local client =  self:open();
   local ret, err = client:qpush_back(self:toSSDBKey(level), unpack(tasks))
   self:close(client)
   return ret, err
end

function _M:qretry(level, task_val)
   level = level or 1
   if util_table.is_table(task_val) then
     task_val =  cjson_safe.encode(task_val)
   end
   local ssdbKey = self:toSSDBKey(level)
   local client =  self:open();
   local count = client:qsize(ssdbKey)
   local ret, err
   if count > 10 then
     local index = math.modf(count / 2) + 1
     local indexVal, err = client:qget(ssdbKey, index)
     if indexVal then
       client:qset(ssdbKey, index, task_val)
       ret, err = client:qpush_front(ssdbKey, indexVal)
     end
   end
   self:close(client)
   return ret, err
end

function _M:qpop(size)
   size = size or 1
   local client =  self:open();
   local assignArr = {}
   local count = size
   for _, level in ipairs(levelArr) do
      local ssdbKey = self:toSSDBKey(level)
      local ret, err = client:qpop_front(ssdbKey, count)
      if not util_table.isNull(ret) then
        if  type(ret) == "string" then
          local task = self:toBean(ret)
          table.insert(assignArr, task)
        else
          for _,tv in ipairs(ret) do
             local task = self:toBean(tv)
             table.insert(assignArr, task)
          end
        end
      end
      count = size - #assignArr
      if count < 1 then
        break
      end
   end
   self:close(client)
   -- log(ERR,"assignArr:" .. cjson_safe.encode(assignArr))
   return assignArr
end

return _M