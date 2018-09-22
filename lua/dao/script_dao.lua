local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ESClient = require "es.ESClient"

local ssdb_script = require "ssdb.script"
local ssdb_version = require "ssdb.version"

local find = ngx.re.find

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = ESClient:new({index = "script", type = "table"})
_M._VERSION = '0.01'


function _M:importTypes(type, script )
 	 local from, to, err = find(script, "ScriptParser.prototype.getImportScripts", "jo")
 	 local types = {}
	 if not from or (from < 0) then
	 	return types
	 end
	 script = string.sub(script, to)
	 from, to, err = find(script, "return", "jo")
	 script = string.sub(script, to + 1)
	 local m, err = ngx.re.match(script, "[0-9a-zA-Z,-]+","mjo")
	 if m then
	 	local body = cjson_safe.encode(m[0])
	 	-- rm "
	 	body = string.sub(body, 2,-2)
		types = string.split(body, ',')
	 end
	 return types
end

function _M:insert_scripts(params )
  if not params then
    return nil, 400
  end
  local resp = nil
  local status = 200
  for _, scriptDoc in ipairs(params) do
  	local ret, err = ssdb_script:set(scriptDoc.type, scriptDoc)
  	if err then
  		status = 500
  		resp = err
  	else
  		local versionDoc = {}
  	    versionDoc.version =  ngx.time()
  	    versionDoc.imports = _M:importTypes(scriptDoc.type, scriptDoc.script)
  	    ssdb_version:set(scriptDoc.type, versionDoc)
  		resp = ret
  		status = 200
  	end
  end
  return resp, status
  -- local configs = {
	 --  refresh = "true"
  --  }
  -- return self:index_docs( params, configs )
end

function _M:update_scripts(params )
	if not params then
      return nil, 400
	end
	-- refresh,use in buildQuery,must be string
    local configs = {
	  refresh = "true"
    }
   return self:update_docs( params, configs )
end

function _M:search_by_type( taskType )
	local ret, err = ssdb_script:get(taskType)
	local versionDoc = ssdb_version:get(taskType)
	if versionDoc then
		ret.version = versionDoc.version
	end
	return ret, err
	-- local resp, status = _M:search{
	-- 	query =  { 
	-- 	    bool =  { 
	-- 	      must = { 
	-- 	        match = { _id = id }
	-- 	      },
	-- 	      filter = { 
	-- 	        { term =  { delete =  0 }}
	-- 	      }
	-- 	    }
	-- 	  }
	-- }
	-- return resp, status
end

function _M:search_all_ids()
	   local ret, err = ssdb_script:keys(1000)
	   -- log(ERR,"search_all_ids.ret:" .. cjson_safe.encode(ret))
	   return ret, err
	-- local resp, status = _M:search{
	-- 	_source = false,
	-- 	size = 1000,
	-- 	query = {
	-- 		bool = {
	-- 		  must_not = {
	-- 		    term = {
	-- 		      delete = 1
	-- 		    }
	-- 		  }
	-- 		}
	-- 	}
	-- }
	-- return resp, status
end

return _M

