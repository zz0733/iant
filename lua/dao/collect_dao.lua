local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local max_len = 32760

local encode_base64 = ngx.encode_base64

local _M = ESClient:new({index = "collect", type = "table"})
-- _M._VERSION = '0.01'
local can_insert = function ( task , data, status )
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

function _M.inserts( collects )
	if not collects then
		return {}, 400
	end
	local es_body = {}
	local count = 0
	for _,v in ipairs(collects) do
		local task = v.task
	    local data = v.data
	    local status = v.status
    	local str_task = cjson_safe.encode(task)
	    local str_data = cjson_safe.encode(data)
	    if can_insert(task, data, status) then
	    	local handlers = data.handlers
	    	es_body[#es_body + 1] = {
		      index = {
		        ["_type"] = _M.type,
		        ["_id"] = task.id
		      }
		    }
		    local collect_obj = {}
		    collect_obj.type = task.type

			--  can not use ipairs,iterator by pairs
			--  table.remove(task,index) not work
		    task.id = nil
		    task.type = nil

		    data.handlers = nil
		    data.nextTasks = nil
		    if string.len(str_task) >= max_len then
		    	str_task = string.sub(str_task, 1, max_len)
		    end
		    collect_obj.task = str_task
		    collect_obj.data = encode_base64(str_data)
		    collect_obj.handlers = handlers
	    	collect_obj.ctime = ngx.time()

		    es_body[#es_body + 1] = collect_obj
		    count = count + 1			    
		else
		    log(ERR,"ignore.collect:" .. str_task .. ",data:" .. str_data)
	    end
	end
    if count < 1 then
    	local resp = {}
    	return resp, 200
    end
	return _M:bulk( es_body )
end

function _M.load_by_handlers( from, size, handlers )
	local body = {
	    from = from,
	    size = size,
		query = {
		  bool= {
		    filter= {
		      terms= {
		        handlers= handlers
		      }
		    }
		  }
		}
	  }
	local resp, status = _M:search_then_delete(body)
	return resp, status
end

return _M

