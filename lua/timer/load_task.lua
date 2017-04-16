-- init_worker_by_lua
local task_dao = require("dao.task_dao")
local cjson_safe = require("cjson.safe")
local delay = 5  -- in seconds
local new_timer = ngx.timer.at
local log = ngx.log
local ERR = ngx.ERR
local INFO = ngx.ERR
local CRIT = ngx.CRIT
local shared_dict = ngx.shared.shared_dict
local task_queue_key = "task_queue"
local size_count = 10
local max_count = 13
local task_index = "task"
local task_type = "table"
local task_level_size = {2,4,10}
local check

 check = function(premature)
     if not premature then
         -- do the health check or other routine work
         local has_count ,err = shared_dict:llen(task_queue_key)
         local need_count = max_count - has_count
         log(INFO,'task,cache:' .. tostring(has_count) .. ",need:" .. tostring(need_count))
         if has_count < max_count then
             local params = {
                from = 0,
                status = 0
             }
             local level = #task_level_size
             for i = level, 1, -1 do
                 level = i -1
                 params.level = level
                 params.size = task_level_size[i]
                 local start = ngx.now()
                 local resp,status = task_dao.load_by_level_status(task_index, task_type, params)
                 ngx.update_time()
                 local cost = (ngx.now() - start)
                 cost = tonumber(string.format("%.3f", cost))
                 if resp then
                    local total  = resp.hits.total
                    log(INFO,"task,load[" .. level .. "],limit:" .. params.size 
                        ..",count:" .. total .. ",cost:" .. cost)
                    if total > 0 then
                        local hits  = resp.hits.hits
                        for _,v in ipairs(hits) do
                            local source = v._source
                            local task = {}
                            task.id = v._id
                            task.type = source.type
                            task.url = source.url
                            task.ctime = source.create_time
                            task.params = source.params
                            task.pid = source.parent_id
                            task.batch_id = source.batch_id
                            task.job_id = source.job_id
                            task.level = source.level
                            local task_val = cjson_safe.encode(task)
                            local len, err = shared_dict:lpush(task_queue_key, task_val)
                            if err then
                                log(CRIT,"shared_dict:lpush," .. ",cause:", err)
                            end
                            
                        end
                    end
                    need_count = need_count - total
                 else
                    log(CRIT,"task,load[" .. level .. "],limit:" .. params.size
                        ..",cost:" .. cost .. ",cause:", status)
                 end
                 if need_count < 0 then
                     break
                 end
             end
         end
         local ok, err = new_timer(delay, check)
         if not ok then
             log(ERR, "failed to create timer: ", err)
             return
         end
     end
 end

 if 0 == ngx.worker.id() then
     log(ERR, "load_task_timer start")
     local ok, err = new_timer(delay, check)
     if not ok then
         log(ERR, "load_task_timer fail to run: ", err)
         return
     end
 end