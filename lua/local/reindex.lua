local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")
local content_dao = require "dao.content_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local message = {}
message.code = 200

local body = {
}

local sourceClient = client_utils.client()
local targetClient =  sourceClient
local sourceIndex = "content_v2";
local targetIndex = "content_v3";
content_dao.index = targetIndex
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
        message.data = {cost = cost,index = index, scan = scan_count, total = total,save = save,id = doc_id}
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
     
        local save_docs = {}
        for _,v in ipairs(hits) do
            local doc = v["_source"]
            doc.id = v["_id"]
            if doc.epcount then
              doc.epcount = tonumber(doc.epcount)
            end
            table.insert(save_docs, doc)
        end
        local str_docs = cjson_safe.encode(save_docs)
        local srep,serr = content_dao:save_docs(save_docs)
        if srep then
          save = save + #save_docs
        end
        log(ERR,"len:"..tostring(#save_docs)..",str_docs:" .. str_docs .. ",err:" .. tostring(serr))
        scrollId = data["_scroll_id"]
     end
end
local body = cjson_safe.encode(message)
ngx.say(body)