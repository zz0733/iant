local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "script", type = "table"})
_M._VERSION = '0.01'


function _M:insert_scripts(params )
  if not params then
    return nil, 400
  end
  local configs = {
	  refresh = "true"
   }
  return self:index_docs( params, configs )
end

function _M:update_scripts(params )
	if not params then
      return nil, 400
	end
	-- refresh,use in buildQuery,must be string
    local configs = {
	  refresh = "true"
    }
   return self:update_docs( params, configs )
end

function _M:search_by_type( id )
	local resp, status = _M:search{
		query =  { 
		    bool =  { 
		      must = { 
		        match = { _id = id }
		      },
		      filter = { 
		        { term =  { delete =  0 }}
		      }
		    }
		  }
	}
	return resp, status
end

function _M:search_all_ids()
	local resp, status = _M:search{
		_source = false,
		size = 1000,
		query = {
			bool = {
			  must_not = {
			    term = {
			      delete = 1
			    }
			  }
			}
		}
	}
	return resp, status
end

return _M

