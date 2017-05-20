local util_table = require "util.table"
local handlers = require "handler.handlers"
local cjson_safe = require("cjson.safe")

local collect_dao = require "dao.collect_dao"

local delay = 10  -- in seconds
local new_timer = ngx.timer.at

local log = ngx.log
local ERR = ngx.ERR
local INFO = ngx.ERR
local CRIT = ngx.CRIT
local commands = handlers.commands
local str_handlers = cjson_safe.encode(commands)
local from = 0
local size = 100

local check

 check = function(premature)
     if not premature then
         -- do the health check or other routine work
         local start = ngx.now()
         local resp, status = collect_dao:load_by_handlers(from, size, commands)
         ngx.update_time()
         local cost = (ngx.now() - start)
         cost = tonumber(string.format("%.3f", cost))
         if resp then
            local total  = resp.hits.total
            log(INFO,"collect,load[" .. str_handlers .. "],limit:" .. size 
                ..",count:" .. total .. ",cost:" .. cost)
            if total > 0 then
                local hits  = resp.hits.hits
                for _,v in ipairs(hits) do
                   local source = v._source
                   local cur_handlers = source.handlers
                   for _, cmd in ipairs(cur_handlers) do
                        if util_table.contains(commands, cmd) then
                            local resp,status = handlers.execute(cmd, v._id, source)
                            if not resp then
                                log(CRIT,"handlers[" .. cmd .."],id:" .. tostring(v._id) .. ",status:" .. tostring(status) )
                            end
                        end
                   end
                end
            end
         else
            log(CRIT,"collect,load[" .. str_handlers .. "],limit:" .. size
                        ..",cost:" .. cost .. ",cause:", status)
         end
         
         local ok, err = new_timer(delay, check)
         if not ok then
             log(ERR, "failed to create timer: ", err)
             return
         end
     end
 end

 if 0 == ngx.worker.id() then
     log(ERR, "handle_collect_timer start")
     local ok, err = new_timer(delay, check)
     if not ok then
         log(ERR, "handle_collect_timer fail to run: ", err)
         return
     end
 end