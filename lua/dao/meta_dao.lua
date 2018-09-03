local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_context = require "util.context"
local ESClient = require "es.ESClient"
local ssdb_meta = require "ssdb.meta"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "meta", type = "table"})
_M._VERSION = '0.01'

function _M:save_metas( docs)
    if not docs then
      return nil, 400
    end
    for _,v in ipairs(docs) do
    	if v.regions then
    	  local regions = v.regions
    	  for k,v in ipairs(regions) do
    	  	 if v then
    	  	 	regions[k] = self:to_synonym(v, "ik_smart_synmgroup")
    	  	 end
    	  end
    	end
    	if v.countrys then
    	  local countrys = v.countrys
    	  for kk,vv in ipairs(countrys) do
    	  	 if vv then
    	  	 	countrys[kk] = self:to_synonym(vv, "ik_smart_synonym")
    	  	 end
    	  end
    	end
    	local cmd = v[self.bulk_cmd_field]
        if v.digests then
        	local hasMeta = ssdb_meta:get(v.id)
	    	if hasMeta then
	    		if hasMeta.digests then
	    			local hasDigests = hasMeta.digests
		  			for kk,vimg in ipairs(hasDigests) do
		  				-- dv.content = '/img/a9130b4f2d5e7acd.jpg'
		  				if string.match(vimg,"^/img/") then
		  					v.digests = hasDigests
		  					break
		  				end
		  			end
	    		end
	  			v.cstatus = nil
                v.pstatus = nil
	    	end
        end
        if 'update' == cmd then
        	ssdb_meta:update(v.id, v)
        else
        	ssdb_meta:set(v.id, v)
        end
        v = ssdb_meta:removeOnlyFields(v)
    end
	return self:bulk_docs(docs)
end

function _M:to_synonym(body, analyzer)
    local resp, status = self:analyze(body, nil, analyzer)
    if resp and resp.tokens then
    	for _,tv in ipairs(resp.tokens) do
    		if tv.type == "SYNONYM" then
    			return tv.token
    		end
    	end
    end
    return body
end

return _M