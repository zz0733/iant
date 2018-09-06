local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_context = require "util.context"
local util_magick = require "util.magick"
local ESClient = require "es.ESClient"
local ssdb_meta = require "ssdb.meta"

local bit = require("bit") 

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local decode_base64 = ngx.decode_base64

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

function _M:search(body)
 local resp, status = _M.client:search{
    index = _M.index,
    type = _M.type,
    body = body
  }
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

function _M:corpDigest(oDoc)
  local hasMeta = ssdb_meta:get(oDoc.id)
  if not hasMeta then
     return nil, 'miss meta:' .. oDoc.id
  end
  local imgBody  = decode_base64(oDoc.image)
  local md5Val = util_magick.toMD5(imgBody)
  local img = util_magick.toImage(imgBody)
  local imgName = md5Val .. oDoc.suffix
  local width = oDoc.width or 0
  local height = oDoc.height or 0
  local savePath, err = util_magick.saveCorpImage(img, width, height, imgName)
  if err then
    log(ERR,"saveCorpImage:" .. newPath .. ",cause:", err)
    return nil, err
  else 
    local cstatus = hasMeta.cstatus or 0
    local es_body = {}
    local upDoc = {}
    upDoc.id = oDoc.id
    upDoc.cstatus =  bit.bor(cstatus, 1)
    table.insert(es_body, upDoc)
    local resp, status = self:update_docs( es_body )
    log(ERR,"corpDigest.req:" ..  cjson_safe.encode(es_body)  .. ",resp:" .. cjson_safe.encode(resp) .. ",status:" .. status )
    if status == 200 then
        hasMeta.cstatus = upDoc.cstatus
        ssdb_meta:set(oDoc.id, hasMeta)
    end
    return status, nil
  end
end
return _M