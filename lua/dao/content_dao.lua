local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "content", type = "table"})
_M._VERSION = '0.01'

local CHECK_FIELDS = {"evaluates","names","genres","actors","directors","images","tags","digests","contents","issueds"}

function _M.inserts( params )
	if not params then
		return {}, 400
	end
	local es_body = {}
	local count = 0
	for _, val in ipairs(params) do
	    local id = val.id
		es_body[#es_body + 1] = {
	      index = {
	        ["_type"] = _M.type,
	        ["_id"] = id
	      }
	    }
	    if not val.ctime then
	    	val.ctime = ngx.time()
	    end
	    if not val.utime then
	    	val.utime = ngx.time()
	    end
	    for _,key in ipairs(CHECK_FIELDS) do
	    	local val_obj = val[key]
	    	if val_obj and util_table.is_empty_table(val_obj) then
	    		val[key] = nil
	    	end
	    end
	    es_body[#es_body + 1] = val
	    count = count + 1
	end
    if count < 1 then
    	local resp = {}
    	return resp, 200
    end
    -- log(ERR,"content.es_body" ..  cjson_safe.encode(es_body))
	return _M:bulk( es_body )
end

function _M.query_by_name( from, size, name )
	local body = {
	  from = from,
	  size = size,
	  query = {
	    multi_match = {
	      query = name,
	      type = "best_fields",
	      fields = {"names"},
	      operator = "and",
	      minimum_should_match = "60%"
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