local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "collect", type = "table"})
-- _M._VERSION = '0.01'


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
	    if task and  data and status == 1 then
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

		    -- local data_json = cjson_safe.decode(data)
		    local handlers = data.handlers
		    data.handlers = nil
		    collect_obj.task = cjson_safe.encode(task)
		    collect_obj.data = cjson_safe.encode(data)
		    collect_obj.handlers = handlers
	    	collect_obj.ctime = ngx.time()
		    es_body[#es_body + 1] = collect_obj
		    count = count + 1
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

