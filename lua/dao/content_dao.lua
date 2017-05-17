local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "content", type = "table"})
_M._VERSION = '0.01'

function _M:query_by_name( from, size, name,fields )
	local body = {
	  from = from,
	  size = size,
	  _source = fields,
	  query = {
	    match = {
	      names = name
	    }
	  },
	  highlight = {
	    order = "score",
	    fields = {
	      names = {
	        fragment_size = 50,
	        number_of_fragments = 1,
	        fragmenter = "span"
	      }
	    }
	  }
	}
	local resp, status = _M:search(body)
	return resp, status
end

function _M:query_by_ctime( from, size, from_date, to_date, fields)
	local body = {
	  from = from,
	  size = size,
	  sort = {
	    ctime = {
	      order = "desc"
	    }
	  },
	  query = {
	    bool = {
		    filter = {
		      range = {
		        ctime ={
		          gt = from_date,
		          lte = to_date
		        }
		      }
		    }
	    }
	  }
	}
	if fields then
		body["_source"] = fields
	end
	local resp, status = _M:search(body)
	return resp, status
end

return _M