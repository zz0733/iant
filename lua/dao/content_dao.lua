local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "content", type = "table"})
_M._VERSION = '0.01'

function _M:query_by_codes(from, size, codes, fields )
  if not codes then
    return nil, 400
  end
  local body = {
	  from = from,
	  size = size,
      _source = fields,
      query = {
         terms = {
           ["article.code"] = codes
         }
      }
  }
  return self:search(body)
end

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
	  sort = {_score = { order = "desc"}},
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
	local str_today = ngx.today()
	local m = ngx.re.match(str_today, "([0-9]{4})")
	local year = 2016
    if m and m[1] then
    	year = tonumber(m[1])
    end
	local body = {
	  from = from,
	  size = size,
	  _source = fields,
  	  sort = {_score = { order = "desc"}, ["article.year"] = { order = "desc"}},
	  query = {
	   bool = {
		  filter = {
		      range = {
		        ["article.year"] = {
		          lte = year
		        }
		      }
		   },
		   must = {
		       match = {
			      genres = genre
			   }
		   }
	    }
	  }
   }
	local resp, status = _M:search(body)
	return resp, status
end

function _M:query_by_region( from, size, region,fields )
	if not region then
		return nil, 400
	end
	local str_today = ngx.today()
	local m = ngx.re.match(str_today, "([0-9]{4})")
	local year = 2016
    if m and m[1] then
    	year = tonumber(m[1])
    end

	local body = {
	  from = from,
	  size = size,
	  sort = {_score = { order = "desc"}, ["article.year"] = { order = "desc"}},
	  _source = fields,
	  query = {
	   bool = {
		  filter = {
		      range = {
		        ["article.year"] = {
		          lte = year
		        }
		      }
		   },
		   must = {
			 nested = {
			     path = "issueds",
			     query = {
	                match = {
	                   ["issueds.region"] = region
		            }
				 }
			  }
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

function _M:update_link_pipe( id, lpipe )
  local es_body = {}
  local cmd = 'update'
  local cmd_doc = {}
   cmd_doc[cmd] = {
	  ["_type"] = self.type,
	  ["_id"] = id
   }
   table.insert(es_body,cmd_doc)
  local up_doc = { utime = ngx.time(),lpipe = lpipe };
  local new_doc = { 
	    script = { 
	      inline = "def newPipe=params.lpipe; def upval=true; if(ctx._source.lpipe != null) { def hasPipe=ctx._source.lpipe; if(hasPipe.epmax !=null && ( newPipe.epmax==null || hasPipe.epmax > newPipe.epmax) ){ upval=false; } if(upval){ ctx._source.lpipe=newPipe; ctx._source.utime=params.utime;}}", 
	      lang = "painless", 
	      params = up_doc
	    }
  }
  table.insert(es_body,new_doc)
  -- log(ERR,"incr_by_target.resp:" ..  cjson_safe.encode(new_doc) )
  return self:bulk( es_body )
end

return _M