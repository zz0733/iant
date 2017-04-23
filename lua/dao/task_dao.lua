local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"

local es_index = "task"
local es_type = "table"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 2)
_M._VERSION = '0.01'


local client_utils = require("util.client_utils")
local client = client_utils.client()


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
	    if not v.ctime then
	    	v.ctime = ngx.time()
	    end
	    if not v.utime then
	    	v.utime = ngx.time()
	    end
	    es_body[#es_body + 1] = v
	end

	local resp, status = client:bulk{
	  index = index,
	  body = es_body
	}
    
	return resp, status
end

function _M.check_search_by_level_status( params ) 
	if not params or not params.from or not params.size or not params.level then
		return false
	end
	return true
end

function _M.search_by_level_status(index, type, params )
	if not _M.check_search_by_level_status( params ) then
		return
	end

	local resp, status = client:search{
	  index = index,
	  type = type,
	  body = {
	    from = params.from,
	    size = params.size,
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
                  level = params.level
	            }
	          }
		   }
		}
	  }
	}
	return resp, status
end

function _M.request_by_query(client, params, endpointParams)
  local Endpoint = require("dao.remove_by_query")
  local endpoint = Endpoint:new{
    transport = client.settings.transport,
    endpointParams = endpointParams or {}
  }
  if params ~= nil then
    -- Parameters need to be set
    local err = endpoint:setParams(params)
    if err ~= nil then
      -- Some error in setting parameters, return to user
      return nil, err
    end
  end
  -- Making request
  local response, err = endpoint:request()
  if response == nil then
    -- Some error in response, return to user
    return nil, err
  end
  -- Request successful, return body
  return response.body, response.statusCode
end

function _M.check_delete_by_ids( ids )
	if not ids or not util_table.is_array(ids) then
		return false
	end
	return true
end

function _M.delete_by_ids( index, type, ids )
	if not _M.check_delete_by_ids( ids ) then
		return
	end
	local params = {
	  index = index,
	  type = type,
	  body = {
		query = {
		   terms = {
		   	 _id = ids
		   }
		}
	  }
	}
	local resp, status = _M.request_by_query(client,params)
	local body = cjson_safe.encode(resp)
	-- ngx.say('delete_by_ids.body:',body)
	-- ngx.say('delete_by_ids.status:',status)
    return resp, status

end

function _M.load_by_level_status( index, type, body_json )
	local body = cjson_safe.encode(body_json)
	log(ERR,'load_by_level_status:',body)
	local resp, status = _M.search_by_level_status(index, type, body_json)
	if not resp then
		return resp, status
	end
	local body = cjson_safe.encode(resp)
	log(ERR,'load_by_level_status.resp:',body)
    local total  = resp.hits.total
    if total < 1 then
    	return resp, status
    end
    local hits  = resp.hits.hits
    local ids = {}
    for i,v in ipairs(hits) do
    	ids[#ids + 1] = v._id
    end
    _M.delete_by_ids(index, type, ids)
    return resp, status
end

return _M

