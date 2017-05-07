local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"


local es_index = "task"
local es_type = "table"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local _M = ESClient:new({index="task",type="table"})
-- _M._VERSION = '0.01'

function _M.check_insert_tasks(index, type, tasks ) 
	if not tasks or not util_table.is_array(tasks) then
		return false
	end
	return true
end

function utcformat()
	-- local now_time = ngx.now()
 --    local str_now = tostring(now_time)
	-- local cur_time = os.date ('%Y-%m-%dT%H:%M:%S.', now_time)
	-- local from, to, err = ngx.re.find(str_now, "\\.", "jo")
	-- str_now = '#000' .. string.sub(str_now, from + 1)
	-- str_now = string.sub(str_now, -3)
	-- cur_time = cur_time .. str_now .. "Z"
	
	local local_time = ngx.utctime()
	local new_time, n, err = ngx.re.sub(local_time, " ", "T")
	new_time = new_time .. ".000Z"
	return new_time
end

function _M.insert_tasks(index, type, tasks )
	if not _M.check_insert_tasks(index, type, tasks ) then
		return
	end
	local es_body = {}
	for k,v in ipairs(tasks) do
		es_body[#es_body + 1] = {
	      index = {
	        ["_type"] = type
	      }
	    }
	    if v.params and util_table.is_table(v.params) then
	    	v.params = cjson_safe.encode(v.params)
	    end
	    if not v.ctime then
	    	v.ctime = ngx.time()
	    end
	    if not v.utime then
	    	v.utime = ngx.time()
	    end
	    es_body[#es_body + 1] = v
	end

	local resp, status = _M:bulk(es_body)
	return resp, status
end

function _M.load_by_level_status( from, size, level, types )
	local body = {
	    from = from,
	    size = size,
	    sort = {
           {
            ctime = {
              order = "asc"
       	    }
           }
		},
		query = {
		   bool = {
              filter = {
              	term = {
                  level = level
	            }
	          },
	          must = {
	            terms = {
	              type = types
		        }
		      }
		   }
		}
	  }
	local resp, status = _M:search_then_delete(body)
	return resp, status
end

return _M

