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

function _M:query_by_titles(names, from, size,fields )
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
		    should = shoulds,
		    must_not = {
	            match = { status = -1 }
	        }
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

function _M:query_by_target( target_id, from , size, fields )
  if not target_id then
  	return 0
  end
  local  body = {
    from = from,
    size = size,
    _source = fields,
    sort = { _score = { order = "desc"}},
    query = {
      bool = {
        must = {
		   nested = {
		        path = "targets",
		         query ={
		           match = { 
		              ["targets.id"] = target_id
		           }
		         }
		      }
	    },
	    must_not = {
            match = { status = -1 }
        }
	  }
    }
  }
  return _M:search(body)
end

function _M:query_by_target_title( target_id,title , from , size, fields )
  local shoulds = {}
  if target_id then
  	  table.insert(shoulds,{
		   nested = {
		        path = "targets",
		         query ={
		           match = { 
		              ["targets.id"] = target_id
		           }
		         }
		      }
	  })
  end
  if title then
  	  table.insert(shoulds,{
			match = { 
			  title = title
			}
	  })
  end
  if #shoulds < 1 then
  	return nil, 400
  end


  local  body = {
    from = from,
    size = size,
    _source = fields,
    sort = { _score = { order = "desc"}},
    query = {
      bool = {
        should = shoulds,
	    must_not = {
            match = { status = -1 }
        }
	  }
    }
  }
  -- log(ERR,"query_by_target_title.resp:" ..  cjson_safe.encode(body) )
  return _M:search(body)
end

function _M:query_by_targetid_source(target_id, source_reg, from , size, fields )
  if not target_id or not source_reg then
  	return nil,400
  end
  target_id = tostring(target_id)
  local must_arr = {}
    table.insert(must_arr,{
		   nested = {
		        path = "targets",
		         query ={
		           match = { 
		              ["targets.id"] = target_id
		           }
		         }
		      }
	})
    table.insert(must_arr,{
	           match = { 
	              status = 1
	           }
    })
    table.insert(must_arr,{
	           regexp = { 
	              source = { value = source_reg}
	           }
    })
  -- log(ERR,"query_by_targetid_source.resp:" ..  tostring(target_id) ..",source_reg:"..source_reg..",from:"..from..",size:"..size..cjson_safe.encode(fields))
  local  body = {
    from = from,
    size = size,
    _source = fields,
    query = {
      bool = {
        must = must_arr
	  }
    }
  }
  return _M:search(body)
end


function _M:incr_bury_digg( id, target_id, bury, digg )
  if not id or not bury or not digg then
  	return nil, 400
  end

  local es_body = {}
  local cmd = 'update'
  local cmd_doc = {}
   cmd_doc[cmd] = {
	  ["_type"] = self.type,
	  ["_id"] = id
   }
   es_body[#es_body + 1] = cmd_doc
  local up_doc = { tid = target_id, bury = bury, digg = digg, utime = ngx.time() }
  local new_doc = { 
	    script = { 
	      inline = "def targets = ctx._source.targets; for(int i = 0; i < targets.length; i++){ def target = targets[i]; if(target == null || target.id == null) { continue; } if(target.id == params.tid) { if(params.bury != null) { def bury = target.bury; if (bury == null) { bury = 0 ; } target.bury = bury + params.bury; if(target.bury >= 10 && targets.length == 1) { ctx._source.status=-1; } } if(params.digg != null) { def digg = target.digg; if (digg == null) { digg = 0 ; } target.digg = digg + params.digg; } break; } }", 
	      lang = "painless", 
	      params = up_doc
	    },
	    upsert = up_doc
  }
  es_body[#es_body + 1] = new_doc
  -- log(ERR,"incr_by_target.resp:" ..  cjson_safe.encode(new_doc) )
  return self:bulk( es_body )
end

return _M