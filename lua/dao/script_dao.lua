local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "script", type = "table"})
_M._VERSION = '0.01'


function _M.insert_scripts(scripts )
	local es_body = {}
	for k,v in ipairs(scripts) do
		es_body[#es_body + 1] = {
	      index = {
	        ["_type"] = _M.type,
	        ["_id"] = v.type
	      }
	    }
	    if not v.type or v.type == "" then
	    	return nil, "type is empty"
	    end
	    es_body[#es_body + 1] = v
	end

	local resp, status = _M:bulk(es_body)
	return resp, status
end

function _M.search_by_type( id )
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

function _M.search_all_ids()
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

