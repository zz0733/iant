local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")
local content_dao = require "dao.content_dao"
local meta_dao = require "dao.meta_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local message = {}
message.code = 200

local from_date = tonumber(args.from) or (ngx.time() - 5*60*60)
local timeby = from_date

 -- # -1:失效,0:默认,1:有效,2:自动匹配,3:人工匹配
local must_array = {}
table.insert(must_array,{range = { utime = { gte = from_date } }})
-- table.insert(must_array,{range = { status = { gte = 1 } }})

local body = {
    query = {
        bool = {
            must = must_array
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
scanParams.size = 100
scanParams.body = body

local lindex = 0;
local scan_count = 0
local scrollId = nil
local index = 0
local save = 0
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
        message.data = {cost = cost,index = index, scan = scan_count, total = total,lindex = lindex, save = save,id = doc_id}
        break
     else
         total = data.hits.total
         local hits = data.hits.hits
         -- local shits = cjson_safe.encode(hits)
         -- log(ERR,"hits:" .. shits)
         scan_count = scan_count + #hits
         ngx.update_time()
         local cost = (ngx.now() - start)
         cost = tonumber(string.format("%.3f", cost))
         log(ERR,"timeby:"..timeby..",scrollId["..tostring(scrollId) .. "],total:" .. total ..",hits:" .. tostring(#hits) 
                .. ",scan:" .. tostring(scan_count)..",index:"..index..",cost:" .. cost)
        local elements = {}
        
        for _,v in ipairs(hits) do
            local source = v._source;
            local target = source.target;
            if target then
               local epmax = {}
               epmax.lid = v._id
               epmax.time = source.ctime
               epmax.index = source.episode
               log(ERR,"tv.target:" .. target .. ",epmax:" .. cjson_safe.encode(epmax))
               -- local lresp,lstauts = content_dao:update_link_pipe(tv.id, lpipe)
               local lresp,lstauts = meta_dao:update_epmax(target, epmax)
               if not lresp then
                   log(ERR,"update_epmax.target:"..tostring(target)..",epmax:" .. cjson_safe.encode(epmax)..",status:" ..  cjson_safe.encode(lstauts)..",lresp:" .. cjson_safe.encode(lresp))
               else
                  save = save + 1;
               end
               lindex = lindex + 1;
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