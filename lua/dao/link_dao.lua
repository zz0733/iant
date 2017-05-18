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
	if not names or #names < 1 then
		return nil, "400,names is empty"
	end
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
		    title = {
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

function _M:count_by_target( target_id )
  if not target_id then
  	return 0
  end
  local  body = {
    query = {
      nested = {
        path = "targets",
         query ={
           match = { 
              ["targets.id"] = target_id
           }
         }
      }
    }
  }
  local resp, status = _M:count(body)
  if resp then
  	return resp.count
  else
  	return nil, status
  end
end

function _M:query_by_target( target_id, from , size )
  if not target_id then
  	return 0
  end
  local  body = {
    from = from,
    size = size,
    query = {
      nested = {
        path = "targets",
         query ={
           match = { 
              ["targets.id"] = target_id
           }
         }
      }
    }
  }
  return _M:search(body)
end

return _M