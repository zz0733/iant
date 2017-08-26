local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local client_utils = require("util.client_utils")

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

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


function handleData(hits,name_set)
    if not hits then
        return
    end
    for _,v in ipairs(hits) do
        local _source = v._source
        local article = _source.article
        if article then
            local title = article.title
            if title then
                local titles= string.split(title, ' ')
                title = titles[1]
                log(ERR,"title:" .. tostring(title) .. ",len:" .. tostring(#titles))
                if title then
                    name_set[title] = 1
                end
            end
        end
    end
end

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local query = cjson_safe.decode(post_body)

local body = {
    _source = {"article.title"},
    query = {
        match_all = {
        }
    }
}

local sourceClient = client_utils.client()
local sourceIndex = "content";
local scroll = "1m";
local scanParams = {};
scanParams.index = sourceIndex
scanParams.scroll = scroll
scanParams.size = 1000
scanParams.body = body

local scan_count = 0
local scrollId = nil
local index = 0
local total = nil
local begin = ngx.now()
local name_set = {}
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
        log(ERR, "done.magick,index:"..index..",scan:"..scan_count..",total:" .. tostring(total) .. ",cost:" .. cost)
        message.data = {cost = cost,index = index, scan = scan_count, total = total}
        break
     else
         total = data.hits.total
         local hits = data.hits.hits
         scan_count = scan_count + #hits
         ngx.update_time()
         local cost = (ngx.now() - start)
         cost = tonumber(string.format("%.3f", cost))
         log(ERR,"scrollId["..tostring(scrollId) .. "],total:" .. total ..",hits:" .. tostring(#hits) 
                .. ",scan:" .. tostring(scan_count)..",index:"..index..",cost:" .. cost)
         handleData(hits,name_set)
         scrollId = data["_scroll_id"]
     end
end
if not scrollId then
    local params = {}
    params.scroll_id = scrollId
    sourceClient:clearScroll(params)
end

message = ""
local path = "/apps/deploy/iant/logs/names.txt"
local file, err = io.open(path, "w") 
if file == nil then
    log(ERR,"saveFile["..path .. "] fail,cause:"..err)
else
    for kname,_ in pairs(name_set) do
        local line = "片名" .. "\t" .. tostring(kname)
        log(ERR,"nameline:" .. line)
        file:write(line, "\n")
    end
    file:close()
end
ngx.say(message)

