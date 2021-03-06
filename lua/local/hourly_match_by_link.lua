local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")
local content_dao = require "dao.content_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local content_fields = {"names","directors","issueds","article","ctime"}

local message = {}
message.code = 200

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local to_date = ngx.time()
local from_date = to_date - 1*60*60
local body = {
    _source = "title",
    query = {
        bool = {
            filter = {
              range = {
                ctime ={
                  gte = from_date
                }
              }
            }
        }
      }
}

local sourceClient = client_utils.client()
local sourceIndex = "link";
local scroll = "1m";
local scanParams = {};
scanParams.index = sourceIndex
scanParams.scroll = scroll
-- scanParams.sort = {"_doc"}
scanParams.size = 10
scanParams.body = body

local scan_count = 0
local scrollId = nil
local index = 0
local total = nil
local begin = ngx.now()
while true do
     index = index + 1;
     local data,err;
     local start = ngx.now()
     if not scrollId then
         data, err = sourceClient:search(scanParams)
     else
        data, err = sourceClient:scroll{
          scroll_id = scrollId,
          scroll = scroll
        }
     end
     -- local shits = cjson_safe.encode(data)
     -- log(ERR,"data:" .. shits .. ",err:" .. tostring(err))
     if data == nil or not data["_scroll_id"] or #data["hits"]["hits"] == 0 then
        local cost = (ngx.now() - begin)
         cost = tonumber(string.format("%.3f", cost))
        log(ERR, "done.match,index:"..index..",scan:"..scan_count..",total:" .. tostring(total) .. ",cost:" .. cost)
        message.data = {cost = cost,index = index, scan = scan_count, total = total}
        break
     else
         total = data.hits.total
         local hits = data.hits.hits
         local shits = cjson_safe.encode(hits)
         log(ERR,"hits:" .. shits)
         scan_count = scan_count + #hits
         ngx.update_time()
         local cost = (ngx.now() - start)
         cost = tonumber(string.format("%.3f", cost))
         log(ERR,"scrollId["..tostring(scrollId) .. "],total:" .. total ..",hits:" .. tostring(#hits) 
                .. ",scan:" .. tostring(scan_count)..",index:"..index..",cost:" .. cost)
         -- match_handler.build_similars(hits)
         for i,v in ipairs(hits) do
             local name = v._source.title
             local from = 0
             local size = 10
             local data = content_dao:query_by_title(from, size, name,content_fields)
             if data and data.hits and data.hits.total > 0 then
                 local hits = data.hits.hits;
                 local shits = cjson_safe.encode(hits)
                 log(ERR,"data.query_by_title["..name.."]:" .. shits)
                 match_handler.build_similars(hits)
             end
         end

         scrollId = data["_scroll_id"]
     end
end
if not scrollId then
    local params = {}
    params.scroll_id = scrollId
    sourceClient:clearScroll(params)
end
local body = cjson_safe.encode(message)
ngx.say(body)