local util_table = require "util.table"
local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local content_dao = require("dao.content_dao")
local cjson_safe = require("cjson.safe")
local client_utils = require("util.client_utils")

function _M.reindex()
  if 0 ~= ngx.worker.id() then
    return false
  end
  local sourceClient = client_utils.client()
  local sourceIndex = "content";
  local  targetIndex = "content_v2";
  local query;
  local targetClient;
  local scroll;
  local scanParams;
  local bulkParams;
  query = query or {}
  targetClient = targetClient or sourceClient
  scroll = scroll or "1m"
  scanParams = scanParams or {}
  bulkParams = bulkParams or {}

  -- Performing a search query
  scanParams.index = sourceIndex
  -- scanParams.search_type = "scan"
  scanParams.scroll = scroll
  scanParams.size = 100
  scanParams.body = query
  local str_params = cjson_safe.encode(scanParams)
  local data, err = sourceClient:search(scanParams)
  local str_data = cjson_safe.encode(data)
  log(ERR,"first.str_params:"..str_params..",str_data:" .. str_data .. ",err:" .. tostring(err))
  -- Checking for error in search query
  if data == nil then
    return false, err
  end

  local scrollId = data["_scroll_id"]
  -- Performing a repetitive scroll queries
  while true do
   
    -- Checking for error in scroll query
    if data == nil then
      return false, err
    end

    -- If no more hits then break
    if #data["hits"]["hits"] == 0 then
      break
    end

    scrollId = data["_scroll_id"]

    -- Bulk indexing the documents
    local save_docs = {}
    for _, item in pairs(data["hits"]["hits"]) do
      local doc = item["_source"]
      doc.id = item["_id"]
      table.insert(save_docs, doc)
    end
    local str_docs = cjson_safe.encode(save_docs)
    data, err = content_dao:save_docs(save_docs)
    log(ERR,"len:"..tostring(#save_docs)..",str_docs:" .. str_docs .. ",err:" .. tostring(err))
    -- Checking for error in bulk request
    if data == nil then
      return false, err
    end
    data, err = sourceClient:scroll{
      scroll_id = scrollId,
      scroll = scroll
    }
    local str_data = cjson_safe.encode(data)
	log(ERR,"scrollId:"..scrollId..",str_data:" .. str_data .. ",err:" .. tostring(err))
  end
  return true
 end

return _M