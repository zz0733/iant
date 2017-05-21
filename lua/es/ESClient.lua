local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"

local es_index = "task"
local es_type = "table"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end



local client_utils = require("util.client_utils")

local ESClient = new_tab(0, 6)
ESClient._VERSION = '0.01'
-- The index
ESClient.index = nil
-- The type
ESClient.type = nil

ESClient.accept_commands = {update = 1, index =1, create = 1, delete = 1}
ESClient.default_bulk_command = "create"
ESClient.bulk_cmd_field = "_doc_cmd"

function ESClient:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  local error = nil
  if not o.index then
  	error = "index is nil"
  elseif not o.type then
  	error = "type is nil"
  end
  if not self.client then
  	-- the execute client
  	self.client = client_utils.client()
  end
  if error then
  	log(ERR,"ESClient:new",error)
  end
  return o, error
end

function ESClient:create_docs( docs, configs )
  for _, doc in ipairs(docs) do
    doc[self.bulk_cmd_field] = "create"
  end
  return self:bulk_docs(docs, configs )
end

function ESClient:index_docs( docs, configs )
  for _, doc in ipairs(docs) do
    doc[self.bulk_cmd_field] = "index"
  end
  return self:bulk_docs(docs, configs )
end

function ESClient:update_docs( docs, configs )
  for _, doc in ipairs(docs) do
    doc[self.bulk_cmd_field] = "update"
  end
  return self:bulk_docs(docs, configs )
end

function ESClient:delete_docs( docs, configs )
  for _, doc in ipairs(docs) do
    doc[self.bulk_cmd_field] = "delete"
  end
  return self:bulk_docs(docs, configs)
end

function ESClient:bulk_docs( docs, configs )
  if not docs then
    return nil, 400
  end
  -- log(ERR,"bulk_docs.docs" ..  cjson_safe.encode(docs))
  -- log(ERR,"bulk_docs.configs" ..  cjson_safe.encode(configs))
  local es_body = {}
  local count = 0
  for _, val in ipairs(docs) do
      local id = val.id
      local cmd = val[self.bulk_cmd_field]
      if not self.accept_commands[cmd] then
        cmd = self.default_bulk_command
      end
      local cmd_doc = {}
      cmd_doc[cmd] = {
          ["_type"] = self.type,
          ["_id"] = id
      }
      es_body[#es_body + 1] = cmd_doc
      val.id = nil
      val[self.bulk_cmd_field] = nil
      if not val.ctime then
        val.ctime = ngx.time()
      end
      if not val.utime then
        val.utime = ngx.time()
      end
      local new_doc = val
      if cmd == 'update' then
         new_doc = {}
         new_doc.doc = val
         new_doc.doc.ctime = nil
         new_doc.doc_as_upsert = true
      end
      es_body[#es_body + 1] = new_doc
      count = count + 1
  end
  if count < 1 then
      local resp = {}
      return resp, 200
  end
    -- log(ERR,"content.es_body" ..  cjson_safe.encode(es_body))
  return self:bulk( es_body, configs)
end

function ESClient:bulk( body, configs )
  local resp, status
  local es_body = {}
  local batch_size =  10
  if configs and tonumber(configs.batch) then
     batch_size = 2 * tonumber(configs.batch)
     configs.batch = nil
  end
  local sum = #body
  local total = sum / 2
  for _,v in ipairs(body) do
    es_body[#es_body + 1] = v
    if #es_body == batch_size then
        resp, status = self:dobulk(es_body, configs) 
        if not resp then
          local count = #es_body / 2
          log(CRIT,"fail.batch.bulk,count:" .. count .. ",total:" .. total .. ",cause:", status)
        end
        es_body = {}
    end
  end
  if #es_body >= 1 then
     resp, status = self:dobulk(es_body,  configs )
      if not resp then
        local count = #es_body / 2
        local total = sum / 2
        log(CRIT,"fail.batch.bulk,count:" .. count .. ",total:" .. total .. ",cause:", status)
      end
  end

  return resp, status
end

function ESClient:dobulk( body, configs )
  local params = configs or {}
  params.index = self.index
  params.body = body
  -- log(ERR,"dobulk.params" ..  cjson_safe.encode(params))
  local resp, status = self.client:bulk(params)
  return resp, status
end

function ESClient:search( body )
	-- local string_body = cjson_safe.encode(body)
	-- log(ERR,"search,body:" .. string_body)
	local resp, status = self.client:search{
	  index = self.index,
	  type = self.type,
	  body = body
	}
	return resp, status
end

function ESClient:delete_by_query(params, endpointParams)
  local Endpoint = require("es.ESDeleteByQuery")
  local endpoint = Endpoint:new{
    transport = self.client.settings.transport,
    endpointParams = endpointParams or {}
  }
  if params ~= nil then
    -- Parameters need to be set
    local err = endpoint:setParams(params)
    if err ~= nil then
      -- Some error in setting parameters, return to user
      return nil, err
    end
  end
  -- Making request
  local response, err = endpoint:request()
  if response == nil then
    -- Some error in response, return to user
    return nil, err
  end
  -- Request successful, return body
  return response.body, response.statusCode
end

function ESClient:query_by_ids( ids, fields )
  if not ids then
    return nil, 400
  end
  local body = {
      _source = fields,
      query = {
         terms = {
           _id = ids
         }
      }
  }
  return self:search(body)
end


function ESClient:delete_by_ids( ids )
	local params = {
	  index = self.index,
	  type = self.type,
	  body = {
		query = {
		   terms = {
		   	 _id = ids
		   }
		}
	  }
	}
	local resp, status = self:delete_by_query(params)
	-- local body = cjson_safe.encode(resp)
    return resp, status

end

function ESClient:search_then_delete( body )
  	local resp, status = self:search(body)
  	if not resp then
  		return resp, status
  	end
	-- local body = cjson_safe.encode(resp)
	-- log(ERR,"search_then_delete:" .. body)
    local total  = resp.hits.total
    if total < 1 then
    	return resp, status
    end
    local hits  = resp.hits.hits
    local ids = {}
    for i,v in ipairs(hits) do
    	ids[#ids + 1] = v._id
    end
    self:delete_by_ids(ids)
    return resp, status
end

function ESClient:update( id, new_doc )
    local res, status = self.client:update{
      index = self.index,
      type = self.type,
      id = id,
      body = {
        doc = new_doc
      }
    }
    return resp, status
end

function ESClient:count( body )
    local resp, status = self.client:count{
      index = self.index,
      type = self.type,
      body = body
    }
    return resp, status
end


return ESClient