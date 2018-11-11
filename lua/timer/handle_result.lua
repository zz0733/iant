local util_table = require "util.table"
local handlers = require "handler.handlers"
local cjson_safe = require("cjson.safe")

local collect_dao = require "dao.collect_dao"
local ssdb_result = require "ssdb.result"

local max_delay = 30
local min_delay = 1
local delay = min_delay  -- in seconds
local new_timer = ngx.timer.at

local log = ngx.log
local ERR = ngx.ERR
local INFO = ngx.ERR
local CRIT = ngx.CRIT
local commands = handlers.commands
local str_handlers = cjson_safe.encode(commands)
local from = 0
local size = 2
local MAX_GC_MEM = 6000


local check

 check = function(premature)
     if not premature then
         -- do the health check or other routine work
         local gcMem = gcinfo()
         if gcMem < MAX_GC_MEM then
             local start = ngx.now()
             local resultArr = ssdb_result:qpop(size)
             for _,ret in ipairs(resultArr) do
                 -- log(ERR,"handle_result,ret:" .. cjson_safe.encode(ret) )
                 if not util_table.isNull(ret) and not util_table.isNull(ret.data)then
                     local task = ret.task
                     local data = ret.data
                     local cur_handlers = data.handlers
                     task.id = task.id or  ("0" .. task.type)
                     for _, cmd in ipairs(cur_handlers) do
                          local resp, estatus = handlers.execute(cmd, task.id, ret)
                          if estatus ~= 200 then
                              log(ERR,"handle_" .. cmd ..",id:" .. tostring(task.id) .. ",type:".. tostring(task.type) 
                                 ..",status:" .. cjson_safe.encode(estatus) ..",resp:"..cjson_safe.encode(resp))
                          end
                     end
                 end
             end
             if #resultArr < 1 then
                 delay = delay + 1
                 delay = math.min(delay, max_delay)
             else
                 delay = min_delay
             end
             ngx.update_time()
             local cost = (ngx.now() - start)
             cost = tonumber(string.format("%.3f", cost))
             log(ERR,"ssdb_result_keys,limit:" .. size ..",data:" .. #resultArr ..",cost:" .. cost ..",gc:" .. gcMem)
         else 
            delay = max_delay
            log(ERR,"ssdb_result_keys,wait_for_idle,gc:" .. gcMem)
         end
         log(ERR, "handle_result_timer start,delay:" .. delay)
         local ok, err = new_timer(delay, check)
         if not ok then
             log(ERR, "failed to create timer: ", err)
             return
         end
     end
 end

 if 0 == ngx.worker.id() then
     log(ERR, "handle_result_timer start,delay:" .. delay)
     local ok, err = new_timer(delay, check)
     if not ok then
         log(ERR, "handle_result_timer fail to run: ", err)
         return
     end
 end