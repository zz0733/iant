local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")
local channel_dao = require "dao.channel_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local message = {}
message.code = 200

local to_date = ngx.time()
local from_date = to_date - 1*60*60
local from_issued = to_date - 30*24*60*60

local timeby = os.date("%Y%m%d%H", from_date)
local media = 'all'
local groupby = 'issued'
local source = 'all'
local channel = 'newest'
-- tv;douban;recommend;201705;韩剧
local doc_id = media ..";" .. source ..";".. groupby ..";".. timeby ..";".. channel

local must_array = {}
table.insert(must_array,{match = { status = 1 }})
table.insert(must_array,{
               nested = {
                    path = "issueds",
                     query ={
                          range = {
                            ["issueds.time"] ={
                              gte = from_issued
                            }
                          }
                     }
                  }
            })

local body = {
    query = {
        bool = {
            filter = {
              range = {
                ctime ={
                  gte = from_date
                }
              }
            },
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
        local elements = {}
     
        local did_map = {}
        for _,v in ipairs(hits) do
            local targets = v._source.targets
            if targets then
                for _,tv in ipairs(targets) do
                    if (not tv.bury or tv.bury < 10) and not did_map[tv.id] then
                        local ele = {}
                        ele.code = tv.id
                        ele.title = v._source.title
                        table.insert(elements,ele)
                        did_map[ele.code] = 1
                    end
                end
            end
        end
        if #elements > 0 then
            local doc = {}
            doc.id = doc_id
            doc.timeby = timeby
            doc.media = media
            doc.groupby = groupby
            doc.source = source
            doc.channel = channel
            doc.elements = elements
            doc._doc_cmd = 'update'
            local channel_docs = {}
            table.insert(channel_docs, doc)
            channel_dao.save_docs(channel_docs)
        end
        scrollId = data["_scroll_id"]
     end
end
local body = cjson_safe.encode(message)
ngx.say(body)