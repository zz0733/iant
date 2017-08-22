local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local http = require("socket.http")
local magick = require("magick.gmwand")

local io_open = io.open

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


function getImageByURL( url )
    for i=1,3 do
        local body, code = http.request(url)
        if code == 200 then
            return body
        end
    end
end
function saveFile( path, bytes )
   local file, err = io_open(path, "w") 
   if file == nil then
        log(ERR,"saveFile["..path .. "] fail,cause:"..err)
   else
        file:write(bytes)
        file:close()
   end
end

function handleData(hits)
    if not hits then
        return
    end
    local shits = cjson_safe.encode(hits)
    log(ERR,"hits:" .. shits)

    local url = "https://img3.doubanio.com/view/movie_poster_cover/lpst/public/p2357953076.jpg"
    local imgBytes = getImageByURL(url)

    saveFile("/apps/data/imgs/test2.jpg", imgBytes)

    local img = assert(magick.load_image_from_blob(imgBytes))
    -- local img = assert(magick.load_image('/apps/data/imgs/test2.jpg'))

    log(ERR,"width:" .. img:get_width() .. ",height:" .. img:get_height());

    img:resize(200, 200)
    img:write("/apps/data/imgs/test2.resized.png")
end

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local query = cjson_safe.decode(post_body)

local to_date = ngx.time()
local from_date = to_date - 1*60*60
local body = {
    _source = {"contents","digests"},
    query = {
        bool = {
            must_not = {
                term = {
                  imagick = 1
                }
            }
        }
      }
}

local sourceClient = client_utils.client()
local sourceIndex = "content";
local scroll = "1m";
local scanParams = {};
scanParams.index = sourceIndex
scanParams.scroll = scroll
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
         handleData(hits)
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