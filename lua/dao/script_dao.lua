local cjson_safe = require "cjson.safe"
local client_utils = require("util.client_utils")
local client = client_utils.client()

local es_index = "script"
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


function _M.insert_scripts(scripts )
	local es_body = {}
	for k,v in ipairs(scripts) do
		es_body[#es_body + 1] = {
	      index = {
	        ["_type"] = es_type,
	        ["_id"] = v.type
	      }
	    }
	    if not v.type or v.type == "" then
	    	return nil, "type is empty"
	    end
	    es_body[#es_body + 1] = v
	end

	local resp, status = client:bulk{
	  index = es_index,
	  body = es_body
	}
    
	return resp, status
end

function _M.search_by_type( id )
	local resp, status = client:search{
	  index = es_index,
	  type = es_type,
	  body = {
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
	  }
	return resp, status
end

return _M

