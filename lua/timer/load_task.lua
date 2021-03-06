-- init_worker_by_lua
local task_dao = require("dao.task_dao")
local script_dao = require("dao.script_dao")
local ssdb_version = require("ssdb.version")
local cjson_safe = require("cjson.safe")
local delay = 1  -- in seconds
local new_timer = ngx.timer.at
local log = ngx.log
local ERR = ngx.ERR
local INFO = ngx.ERR
local CRIT = ngx.CRIT
local shared_dict = ngx.shared.shared_dict
local task_queue_key = "task_queue"
local scrip_type_key = "scrip_types"
local max_count = 20
local task_index = "task"
local task_type = "table"
local task_level_size = {5,10,20}
local check

local importVersions = function ( taskType )
    local versionDoc =  ssdb_version:get(taskType)
    local import_verions = {}
    if versionDoc then
       if  versionDoc.imports then
           for _,itype in ipairs(versionDoc.imports) do
              local iVersionDoc =  ssdb_version:get(itype)
              if iVersionDoc then
                 import_verions[itype] = iVersionDoc.version
              end
           end
       end
       import_verions[taskType] = versionDoc.version
    end
    -- log(ERR,"import_verions["..taskType .. "]:" .. cjson_safe.encode(import_verions))
    return import_verions
end

 check = function(premature)
     if not premature then
         -- do the health check or other routine work
         local has_count ,err = shared_dict:llen(task_queue_key)
         local need_count = max_count - has_count
         log(INFO,'task,cache:' .. tostring(has_count) .. ",need:" .. tostring(need_count))
         local script_types = script_dao:search_all_ids()
         local type_count = 0
         if script_types then
             type_count = #script_types
         end
         log(INFO,'task,script:' .. tostring(type_count) ..",types:" .. tostring(cjson_safe.encode(script_types)))
         if has_count < max_count and type_count > 0 then
             local params = {
                from = 0,
                status = 0
             }
             local from = 0
             local status = 0
             local limit = 10
             local level = #task_level_size

             for i = level, 1, -1 do
                 level = i -1
                 limit = task_level_size[i]
                 local start = ngx.now()
                 local resp,status = task_dao:load_by_level_status(from,limit, level, script_types)
                 ngx.update_time()
                 local cost = (ngx.now() - start)
                 cost = tonumber(string.format("%.3f", cost))
                 if resp then
                    local hits  = resp.hits.hits
                    local total  = resp.hits.total
                    local count = 0
                    if hits then
                        count = #hits
                    end
                    log(INFO,"task,load[" .. level .. "],total:" .. total .. ",count:" ..tostring(count) ..",limit:" .. limit 
                        ..",cost:" .. cost)
                    if total > 0 then
                        for _,v in ipairs(hits) do
                            local source = v._source
                            local task = {}
                            task.id = v._id
                            task.type = source.type
                            task.url = source.url
                            task.ctime = source.create_time
                            task.ltime = ngx.time()
                            task.params = source.params
                            task.parent_id = source.parent_id
                            task.batch_id = source.batch_id
                            task.job_id = source.job_id
                            task.level = source.level
                            task.scripts = importVersions(task.type)
                            local task_val = cjson_safe.encode(task)
                            local len, err = shared_dict:lpush(task_queue_key, task_val)
                            if err then
                                log(CRIT,"shared_dict:lpush," .. ",cause:", err)
                            end
                            
                        end
                    end
                    need_count = need_count - total
                 else
                    log(CRIT,"task,load[" .. level .. "],limit:" .. limit
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