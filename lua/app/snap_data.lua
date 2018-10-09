local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"

local ssdb_result = require "ssdb.result"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
-- local data = util_request.post_body(ngx.req)
-- local resp, _, _ = ngx.location.capture_multi{
--       {"/api/collect.json", { args = { method = "insert" }, body = data }},
--       {"/api/task.json", { args = { method = "nexts" }, body = data }},
--       {"/api/task.json", { args = { method = "retry" }, body = data }}
-- }
-- ngx.say(resp.body)

local message = {}
message.code = 200
local data = util_request.post_body(ngx.req)
local body_json = cjson_safe.decode(data)
if not body_json then
	message.code = 400
	message.error = "illegal params"
	ngx.say(cjson_safe.encode(message))
	return
end
function can_insert( task , data, status )
	if not task or not data or status ~= 1 then
		return false
	end
	local handlers = data.handlers
	if not handlers or #handlers < 1 then
      return false
	end
	if #handlers == 1 and handlers[1] == "nexts" then
		return false
	end
	return true
end

local count = 0
message.code = 200
for _,v in ipairs(body_json) do
	local task = v.task
    local data = v.data
    local status = v.status
    if can_insert(task, data, status) then
    	 local level = task.level or 0
	     local resp, err = ssdb_result:qpush(level, v )
         if err then
         	 message.code = 500
         	 message.error = cjson_safe.encode(resp)
         end
    else
    	log(CRIT,"taskErr:" .. tostring(v.task.id).. ",task:" .. cjson_safe.encode(task) )
    	if data then
    		log(CRIT,"taskErr:" .. tostring(v.task.id).. ",data:" .. cjson_safe.encode(data) )
    	end
    	if v.error then
    		log(CRIT,"taskErr:" .. tostring(v.task.id).. ",error:" .. cjson_safe.encode(v.error) )
    	end
    end
end
ngx.say(cjson_safe.encode(message))