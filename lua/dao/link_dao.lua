local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "link", type = "table"})
_M._VERSION = '0.01'


function _M.bulk_docs( params )
	if not params then
		return {}, 400
	end
	local es_body = {}
	local count = 0
	for _, val in ipairs(params) do
	    local id = val.id
	    local cmd = val._doc_cmd or "update"
	    if not _M.accept_commands[cmd] then
	    	cmd = "update"
	    end
	    local cmd_doc = {}
	    cmd_doc[cmd] = {
	        ["_type"] = _M.type,
	        ["_id"] = id
	    }
		es_body[#es_body + 1] = cmd_doc
	    val.id = nil
	    val._doc_cmd = nil
	    if not val.ctime then
	    	val.ctime = ngx.time()
	    end
	    if not val.utime then
	    	val.utime = ngx.time()
	    end
	    local new_doc = {}
	    new_doc.doc = val
	    new_doc.doc_as_upsert = true

	    es_body[#es_body + 1] = new_doc
	    count = count + 1
	end
    if count < 1 then
    	local resp = {}
    	return resp, 200
    end
    -- log(ERR,"content.es_body" ..  cjson_safe.encode(es_body))
	return _M:bulk( es_body )
end

function _M.query_unmatch( from_date, to_date, from, size)
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

function _M.update_doc(id, doc)
	if not doc or not id then
		return {}, 400
	end
	local resp, status = _M:update(id, doc)
	-- log(ERR,"update_doc.resp:" ..  cjson_safe.encode(resp) ..",status:" .. tostring(status))
	return resp, status
end

return _M