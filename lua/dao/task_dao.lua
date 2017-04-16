local elasticsearch = require "elasticsearch"
local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"

-- local req_method = ngx.req.get_method()
-- local args = ngx.req.get_uri_args()
-- local method = args.method
local es_index = "task"
local es_type = "table"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

-- if not method then
-- 	ngx.say('empty method')
-- 	return
-- end
-- ngx.say('method:' .. method)

-- local data = util_request.post_body(ngx.req)
-- local params = cjson_safe.encode(args)
-- local body = cjson_safe.encode(data)
-- local body_json = cjson_safe.decode(data)


-- ngx.say('params:' , params)
-- ngx.say('data:' , body_json.a)
-- ngx.say('req_method:' .. req_method)
-- ngx.say('body:' .. type(body))
-- ngx.say('body:' .. body)

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 2)
_M._VERSION = '0.01'


local client_utils = require("util.client_utils")
local client = client_utils.client()

local define_fields = {
	"parent_id","batch_id","job_id","type",
	"url","params","level","status",
	"source","creator","create_time","update_time"
}

function _M.check_insert_tasks(index, type, tasks ) 
	if not tasks or not util_table.is_array(tasks) then
		return false
	end
	return true
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
            create_time = {
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

local method = 1
-- ngx.say('delete_by_ids.body:',method == 'load')
-- if 'insert' == method  then
-- 	ngx.say('insert_tasks.body:')
-- 	insert_tasks(es_index, es_type , body_json )
-- elseif 'delete' == method then
-- 	ngx.say('delete_by_ids.body:')
-- 	delete_by_ids(es_index, es_type , body_json )
-- elseif 'search' == method then
-- 	ngx.say('delete_by_ids.body:')
-- 	search_by_level_status(es_index, es_type , body_json )
-- elseif 'load' == method then
-- 	ngx.say('delete_by_ids.body:')
-- 	load_by_level_status(es_index, es_type , body_json )
-- end

-- search_by_level_status(es_index, es_type , body_json )
-- delete_by_ids(es_index, es_type , body_json )

return _M

