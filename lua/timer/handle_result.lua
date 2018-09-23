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
local size = 1


local check

 check = function(premature)
     if not premature then
         -- do the health check or other routine work
         local gcMem = gcinfo()
         if gcMem < 4000 then
             local start = ngx.now()
             local keyArr, err = ssdb_result:keys(size)
             ngx.update_time()
             local cost = (ngx.now() - start)
             cost = tonumber(string.format("%.3f", cost))
             if not err and keyArr then
                for _,vv in ipairs(keyArr) do
                    local ret, rerr = ssdb_result:get(vv)
                    ssdb_result:remove(vv)
                    -- log(ERR,"handlers,id:" .. tostring(vv) .. ",ret:" .. cjson_safe.encode(ret) )
                    if not util_table.isNull(ret) then
                        local task = ret.task
                        local data = ret.data
                        local cur_handlers = data.handlers
                        for _, cmd in ipairs(cur_handlers) do
                             local resp, estatus = handlers.execute(cmd, task.id, ret)
                             if not resp then
                                 log(ERR,"handling_" .. cmd ..",id:" .. tostring(task.id) .. ",status:" .. tostring(estatus) )
                             end
                        end
                    end
                end
                if #keyArr < 1 then
                    delay = delay + 1
                    delay = math.min(delay, max_delay)
                else
                    delay = delay - 1
                    delay = math.max(delay, min_delay)
                end
                log(ERR,"ssdb_result_keys,limit:" .. size ..",data:" .. #keyArr ..",cost:" .. cost ..",gc:" .. gcMem)
             else
                log(ERR,"ssdb_result_keys,limit:" .. size ..",cost:" .. cost .. ",cause:", err)
             end
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