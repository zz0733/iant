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

local KEY_PREFIX = "T_"
local ORIGIN_KEY_START = string.len(KEY_PREFIX)  + 1

local levelArr = {}
table.insert(levelArr, 2)
table.insert(levelArr, 1)
table.insert(levelArr, 0)

local CAN_MIXED_COUNT = 10
local RANDOM_MIXED_INDEX = math.modf(CAN_MIXED_COUNT / 2) - 1

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


function _M:taskUUID( )
   local taskId = 1 ngx.re.gsub(uuid(), "-", "")
   taskId = string.sub(taskId, -8)
   return taskId
end

function _M:qpush(level, ...)
   level = level or 1
   local tasks = {...}
   local mixArr = {}
   local qpushArr = {}
   for ti,task_val in ipairs(tasks) do
      if util_table.is_table(task_val) then
        if task_val.params and util_table.is_table(task_val.params) then
           task_val.params = cjson_safe.encode(task_val.params)
        end
        task_val.id =  task_val.id or self:taskUUID()
        task_val =  cjson_safe.encode(task_val)
        log(ERR,"task_val:" .. tostring(task_val))
        tasks[ti] = task_val
      end
      -- mixed task type
      if math.random(5) == 5 then
        table.insert(mixArr, tasks[ti])
      else
        table.insert(qpushArr, tasks[ti])
      end
   end
   local ret = "empty", err
   if #qpushArr > 0 then
      local client =  ssdb_client:open();
      ret, err = client:qpush_back(self:toSSDBKey(level), unpack(qpushArr))
      ssdb_client:close(client)
   end
   for _,mtask in ipairs(mixArr) do
     self:qretry(level, mixArr)
   end
   return ret, err
end

function _M:qretry(level, task_val)
   level = level or 1
   if util_table.is_table(task_val) then
     if task_val.params and util_table.is_table(task_val.params) then
        task_val.params = cjson_safe.encode(task_val.params)
     end
     task_val =  cjson_safe.encode(task_val)
   end
   local ssdbKey = self:toSSDBKey(level)
   local client =  ssdb_client:open();
   local count = client:qsize(ssdbKey)
   local ret, err
   if count > CAN_MIXED_COUNT then
     local index = math.modf(count / 2) + math.random(RANDOM_MIXED_INDEX)
     local indexVal, err2 = client:qget(ssdbKey, index)
     ret, err = client:qset(ssdbKey, index, task_val)
     if indexVal then
       ret, err = client:qpush_front(ssdbKey, task_val)
     end
   else
     ret, err = client:qpush_back(ssdbKey, task_val)
   end
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
        log(ERR,"qpop_front.sret:" .. cjson_safe.encode(ret) .. ",ret:" .. tostring(ret))
        if  type(ret) == "string" then
          local task = self:toBean(ret)
          table.insert(assignArr, task)
        else
          for _,tv in ipairs(ret) do
                local task = self:toBean(tv)
                log(ERR,"tv.task:" .. cjson_safe.encode(tv) .. ",task:" .. tostring(task))
                table.insert(assignArr, task)
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