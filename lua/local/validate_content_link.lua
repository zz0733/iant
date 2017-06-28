local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local client_utils = require("util.client_utils")
local link_dao = require "dao.link_dao"
local task_dao = require "dao.task_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local content_fields = {"link"}

local message = {}
message.code = 200

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local post_body = util_request.post_body(ngx.req)
-- log(ERR,"params:" ..tostring(post_body))
local message = {}
message.code = 200
if  not post_body then
    message.error = "illegal playload"
    message.code = 400
    local body = cjson_safe.encode(message)
    ngx.say(body)
    return
end

local query = cjson_safe.decode(post_body)

local sourceClient = client_utils.client()
local sourceIndex = "content";
local scroll = "1m";
local scanParams = {};
local source_reg = "bdp-*";
scanParams.index = sourceIndex
scanParams.scroll = scroll
-- scanParams.sort = {"_doc"}
scanParams.size = 10
scanParams.body = query

local scan_count = 0
local scrollId = nil
local index = 0
local task_count = 0
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
        log(ERR, "done.validate,index:"..index..",scan:"..scan_count..",total:" .. tostring(total) .. ",cost:" .. cost)
        message.data = {cost = cost,index = index, scan = scan_count, total = total,task = task_count}
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
         local task_docs = {}
         for _,v in ipairs(hits) do
             local target_id = v._id
             local from = 0
             local size = 10000
             local lresp = link_dao:query_by_targetid_source(target_id,source_reg,from, size,content_fields)
             if lresp and lresp.hits and lresp.hits.total > 0 then
                 local hits = lresp.hits.hits;
                 local shits = cjson_safe.encode(hits)
                 -- log(ERR,"link-hits:" .. shits)
                 for _,lv in ipairs(hits) do
                    local str_url = lv._source.link
                    if not string.match(str_url, "^http") then
                        str_url = "https://pan.baidu.com/s/" .. str_url;
                    end
                    local task = {}
                    task.type = "bdp-link-convert"
                    task.url = str_url
                    task.level = 0
                    task.status = 0
                    task.params = {tid = target_id,lid = lv._id, retry = { total = 5 } }
                    table.insert(task_docs, task)
                    task_count = task_count + 1
                 end
             end
         end
         task_dao:insert_tasks(task_docs)

         scrollId = data["_scroll_id"]
     end
end
local body = cjson_safe.encode(message)
ngx.say(body)