local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "content_v2", type = "table"})
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

function _M:query_by_title( from, size, title,fields )
	local body = {
	  from = from,
	  size = size,
	  _source = fields,
	  query = {
	    match = {
	      ["article.title"] = title
	    }
	  },
	  highlight = {
	    order = "score",
	    fields = {
	      ["article.title"] = {
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

function _M:query_by_genre( from, size, genre,fields )
	local body = {
	  from = from,
	  size = size,
	  _source = fields,
	  query = {
	    match = {
	      genres = genre
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

function _M:to_synonym(body, field)
    local resp, status = self:analyze(body, field)
    if resp and resp.tokens then
    	for _,tv in ipairs(resp.tokens) do
    		if tv.type == "SYNONYM" then
    			return tv.token
    		end
    	end
    end
    return body
end

function _M:save_docs( docs)
    if not docs then
      return nil, 400
    end
    for _,v in ipairs(docs) do
    	if v.issueds then
    	  local issueds = v.issueds
    	  for _,sv in ipairs(issueds) do
    	  	 if sv.region then
    	  	 	sv.region = self:to_synonym(sv.region, "issueds.region")
    	  	 end
    	  	 if sv.country then
    	  	 	sv.country = self:to_synonym(sv.country, "issueds.country")
    	  	 end
    	  end
    	end
    end
	return self:bulk_docs(docs)
end

return _M