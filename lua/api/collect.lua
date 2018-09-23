local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local handlers = require "handler.handlers"

local ssdb_result = require "ssdb.result"


local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local method = args.method

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local exptime = 600


local message = {}
message.code = 200
if not method then
	message.status = 400
	message.message = "empty method"
	ngx.say(cjson_safe.encode(message))
	return
end
local data = util_request.post_body(ngx.req)
local body_json = cjson_safe.decode(data)
if not body_json then
	message.code = 400
	message.error = "illegal params"
	ngx.say(cjson_safe.encode(message))
	return
end
if 'insert' == method  then
	
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
		     local resp, err = ssdb_result:set(v.task.id, v )
	         if err then
	         	 message.code = 500
	         	 message.error = cjson_safe.encode(resp)
	         end
	    end
	end
    ngx.say(cjson_safe.encode(message))
end
