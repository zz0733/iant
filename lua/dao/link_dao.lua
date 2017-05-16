local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "link", type = "table"})
_M._VERSION = '0.01'



function _M:query_unmatch( from_date, to_date, from, size)
	local body = {
	  from = from,
	  size = size,
	  sort = {
	    ctime = {
	      order = asc
	    }
	  },
	  query = {
	    bool = {
		    filter = {
		      range = {
		        ctime ={
		          gte = from_date,
		          lt = to_date
		        }
		      }
		    },
		    must_not = {
		        term = {
		          status = -1
		        }
		    },
		    must_not = {
		        term = {
		          status = 1
		        }
		    }
	    }
	  }
	}
	local resp, status = _M:search(body)
	return resp, status
end

function _M:update_doc(id, doc)
	if not doc or not id then
		return {}, 400
	end
	local resp, status = _M:update(id, doc)
	-- log(ERR,"update_doc.resp:" ..  cjson_safe.encode(resp) ..",status:" .. tostring(status))
	return resp, status
end

function _M:query_by_titles( from, size, names,fields )
	local shoulds = {}
	for _,v in ipairs(names) do
		local should = {
	        match = {
	          title = v
	        }
	    }
		shoulds[#shoulds + 1] = should
	end
	local body = {
		from = from,
		size = size,
		_source = fields,
		query = {
		  bool = {
		    should = shoulds
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

return _M