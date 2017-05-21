local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "channel", type = "table"})
_M._VERSION = '0.01'

function _M:save_docs( docs)
	if not docs then
      return nil, 400
    end
    local update_docs = {}
    local remain_docs = {}
    for _,v in ipairs(docs) do
    	if "update" == v[self.bulk_cmd_field] then
    		update_docs[#update_docs + 1] = v
    	else
    		remain_docs[#remain_docs + 1] = v
    	end
    end
    local resp = nil 
    local status = 400
    if #update_docs > 0 then
    	resp, status = self:update_docs(update_docs)
    end
    if #remain_docs > 0 then
    	resp, status = self:bulk_docs(remain_docs)
    end
	return resp, status
end

function _M:update_docs( docs)
  if not docs then
    return nil, 400
  end
  local es_body = {}
  local count = 0
  local cmd = 'update'
  for _, val in ipairs(docs) do
      if val.elements then
      	  local cmd_doc = {}
	      cmd_doc[cmd] = {
	          ["_type"] = self.type,
	          ["_id"] = val.id
	      }
	      es_body[#es_body + 1] = cmd_doc
          val.id = nil
	      val[self.bulk_cmd_field] = nil

	      local new_doc = { 
	        script = { 
	               inline = "ctx._source.utime = params.utime; if(ctx._source.elements != null) { def elements = ctx._source.elements; Map codeMap = new HashMap(); for (int i = 0; i < elements.length; ++i){ def ele = elements[i]; String key = ele.code; codeMap.put(key,ele); } def inputs = params.elements; for (int j = 0; j < inputs.length; ++j){ def ele = inputs[j]; String key = ele.code.toString(); codeMap.put(key,ele); } ctx._source.elements = codeMap.values(); } else { ctx._source.elements = params.elements; } ctx._source.total = ctx._source.elements.size(); ", 
	          lang = "painless", 
	          params = {
	             total = val.total,
	             elements = val.elements,
	             utime = ngx.time()
	          }
	        },
	        upsert = val
		  }
	      es_body[#es_body + 1] = new_doc
	      count = count + 1
      end
  end
  if count < 1 then
      local resp = {}
      return resp, 200
  end
    -- log(ERR,"content.es_body" ..  cjson_safe.encode(es_body))
  return self:bulk( es_body )
end

function _M:query_by_channels(channels, from, size,fields )
  if not channels or #channels < 1 then
    return nil, "400,names is empty"
  end
  local shoulds = {}
  for _,v in ipairs(channels) do
    local should = {
          match = {
            channel = v
          }
      }
    shoulds[#shoulds + 1] = should
  end
  local body = {
    from = from,
    size = size,
    _source = fields,
    sort = { timeby = { order = "desc"}},
    query = {
      bool = {
        should = shoulds
      }
    }
  }
  local resp, status = _M:search(body)
  return resp, status
end

return _M