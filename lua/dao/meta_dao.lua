local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_context = require "util.context"
local util_arrays = require "util.arrays"
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


local ARRAY_FIELDS = {"names","genres","actors","directors","images","digests","issueds","countrys","regions"}

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
                            if (not hasMeta.cstatus ) or (bit.band(hasMeta.cstatus, 1) ~= 1) then
                                hasMeta.cstatus = 1
                            end
		  					break
		  				end
		  			end
	    		end
                if (not v.cstatus) or (hasMeta.cstatus and v.cstatus < hasMeta.cstatus) then
                    v.cstatus = hasMeta.cstatus
                end
                if (not v.pstatus) or (hasMeta.pstatus and v.pstatus < hasMeta.pstatus) then
                    v.pstatus = hasMeta.pstatus
                end
	    	end
        end
        util_arrays.emptyArray(v, unpack(ARRAY_FIELDS))
        ssdb_meta:set(v.id, v)
        v = ssdb_meta:removeOnlyFields(v)
    end
	return self:index_docs(docs)
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

function _M:search(body, withSSDB )
 local resp, status = _M.client:search{
    index = _M.index,
    type = _M.type,
    body = body
  }
  
  if withSSDB then
    if resp and resp.hits and resp.hits.hits then
        local hits = resp.hits.hits
        local idArr = {}
        for i,v in ipairs(hits) do
            table.insert(idArr, v._id)
        end
        local meta_dict = ssdb_meta:multi_get(idArr)
        for i,v in ipairs(hits) do
            v._source = meta_dict[v._id]
        end
    end
  end
  return resp, status
end
      

function _M:corpDigest(oDoc)
  local hasMeta = ssdb_meta:get(oDoc.id)
  if not hasMeta then
     return nil, 'miss meta:' .. cjson_safe.encode(oDoc)
  end
  local imgBody  = decode_base64(oDoc.image)
  local md5Val = util_magick.toMD5(imgBody)
  local img = util_magick.toImage(imgBody)
  local imgName = md5Val ..".".. oDoc.suffix
  local width = oDoc.width or 0
  local height = oDoc.height or 0
  local saveName, err = util_magick.saveCorpImage(img, width, height, imgName)
  if err then
    log(ERR,"saveCorpImageErr:" .. saveName .. ",cause:", err)
    return nil, err
  else 
    local cstatus = hasMeta.cstatus or 0
    hasMeta.cstatus = bit.bor(cstatus, 1)
    if hasMeta.digests then
       local index =  oDoc.index or 1
       hasMeta.digests[index] = '/img/' .. saveName
    end
    -- log(ERR,"corpDigest.hasMeta:" ..  cjson_safe.encode(hasMeta) .. ",old cstatus:" .. tostring(cstatus) )
    local es_body = {}
    table.insert(es_body, hasMeta)
    local resp, status = self:save_metas( es_body )
    log(ERR,"corpDigest.req:" ..  cjson_safe.encode(es_body)  .. ",resp:" .. cjson_safe.encode(resp) .. ",status:" .. status )
    return status, nil
  end
end

function _M:searchUnDigest(fromDate, size)
    local must_array = {}
    table.insert(must_array,{range = { utime = { gte = fromDate } }})

    local must_nots = {}
    -- 完成题图的所有取值，新增cstatus需改动
    local cstatus_digests = {}
    table.insert(cstatus_digests,1)
    table.insert(cstatus_digests,2)
    table.insert(must_nots,{terms = { cstatus = cstatus_digests }})

    local body = {
        size = size,
        query = {
            bool = {
                must = must_array,
                must_not = must_nots
            }
        }
    }
    local resp, status = _M:search(body, true)
    return resp, status
end
return _M