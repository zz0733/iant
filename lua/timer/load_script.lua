-- init_worker_by_lua
local script_dao = require("dao.script_dao")
local cjson_safe = require("cjson.safe")
local delay = 60  -- in seconds
local new_timer = ngx.timer.at
local log = ngx.log
local ERR = ngx.ERR
local INFO = ngx.ERR
local CRIT = ngx.CRIT
local shared_dict = ngx.shared.shared_dict
local scrip_type_key = "scrip_types"

local check

 check = function(premature)
     if not premature then
         local start = ngx.now()
         local resp,status = script_dao.search_all_ids()
         ngx.update_time()
         local cost = (ngx.now() - start)
         cost = tonumber(string.format("%.3f", cost))
         if resp then
            local hits  = resp.hits.hits
            local total  = resp.hits.total
            log(INFO,"script,load,total:" .. total ..",cost:" .. cost)
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
                log(CRIT,"fail.script.set,types:" .. types_val .. ",cause:", err)
            else 
                log(ERR,"script.set,types:" .. types_val .. ",count:" .. total)
            end
         else
            log(CRIT,"script,load,cost:" .. cost .. ",cause:", status)
         end
         local ok, err = new_timer(delay, check)
         if not ok then
             log(ERR, "failed to create timer: ", err)
             return
         end
     end
 end

 if 0 == ngx.worker.id() then
     log(ERR, "load_script_timer start")
     local ok, err = new_timer(delay, check)
     if not ok then
         log(ERR, "load_script_timer fail to run: ", err)
         return
     end
 end