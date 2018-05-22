local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_context = require "util.context"
local ESClient = require "es.ESClient"
local ssdb_content = require "ssdb.content"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "content", type = "table"})
_M._VERSION = '0.01'

-- local origin_search = _M:search;



function _M:search(body)
 local resp, status = _M.client:search{
    index = _M.index,
    type = _M.type,
    body = body
  }
  self:addOnlySSDBFields(resp, body._source)
  if resp and resp.hits and resp.hits.hits then
  	local hits = resp.hits.hits
  	for i,v in ipairs(hits) do
  		local _source = v._source
  		if _source and _source.digests then
  			local digests = _source.digests
  			for _,dv in ipairs(digests) do
  				-- dv.content = '/img/a9130b4f2d5e7acd.jpg'
  				if dv.sort == 'img' and string.match(dv.content,"^/img/") then
  					dv.content = util_context.CDN_URI .. dv.content
  				end
  			end
  		end
  	end

  end
  return resp, status
end

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
    	local cmd = v[self.bulk_cmd_field]
        if v.digests then
        	local hasContent = ssdb_content:get(v.id)
	    	if hasContent and hasContent.digests then
	    		local digests = hasContent.digests
	  			for _,dv in ipairs(digests) do
	  				-- dv.content = '/img/a9130b4f2d5e7acd.jpg'
	  				if dv.sort == 'img' and dv.content and string.match(dv.content,"^/img/") then
	  					v.digests = digests
	  					break
	  				end
	  			end
	    	end
        end
        if 'update' == cmd then
        	ssdb_content:update(v.id, v)
        else
        	ssdb_content:set(v.id, v)
        end
        v = ssdb_content:removeOnlyFields(v)
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
	      inline = "def newPipe=params.lpipe; def upval=true; if(ctx._source.lpipe != null) { def hasPipe=ctx._source.lpipe; if(hasPipe.epmax !=null && ( newPipe.epmax==null || hasPipe.epmax > newPipe.epmax) ){ upval=false; } if(ctx._source.article.epcount!=null && newPipe.epmax!=null && ctx._source.article.epcount<newPipe.epmax){ upval=false; }} if(upval){ ctx._source.lpipe=newPipe; ctx._source.utime=params.utime;}", 
	      lang = "painless", 
	      params = up_doc
	    }
  }
  table.insert(es_body,new_doc)
  -- log(ERR,"incr_by_target.resp:" ..  cjson_safe.encode(new_doc) )
  return self:bulk( es_body )
end

function _M:addOnlySSDBFields( resp, fields )
	if resp and resp.hits and ssdb_content:hasOnlyFields(fields) then
		local idArr = {}
	    for _,v in ipairs(resp.hits.hits) do
	      table.insert(idArr, v._id)
	    end
	    local kv_doc = ssdb_content:multi_get(idArr)
		for _,v in ipairs(resp.hits.hits) do
			local es_source = v._source
			local ssdb_source = kv_doc[v._id]
			log(ERR,"ssdb_source:" .. cjson_safe.encode(ssdb_source))
			local merge_source = es_source
			if ssdb_source then
				merge_source = ssdb_source
				for k,v in pairs(es_source) do
					merge_source[k] = v
				end
			end
			local select_source = nil
            if fields then
            	select_source = {}
            	for _,fld in ipairs(fields) do
            		select_source[fld] = merge_source[fld]
            	end
            else
            	select_source = merge_source
            end
			v._source = select_source
		end
	end
end

return _M