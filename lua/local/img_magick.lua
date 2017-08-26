local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")
local util_context = require("util.context")

local content_dao = require "dao.content_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local http = require("socket.http")
local magick = require("magick.gmwand")
local lfs = require("lfs")

local io_open = io.open
local table_insert = table.insert

local resty_md5 = require "resty.md5"
local resty_string = require "resty.string"

local string_sub = string.sub
local string_len = string.len



local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local post_body = util_request.post_body(ngx.req)

local size_arr = {}
table_insert(size_arr,{w=0,h=0})
table_insert(size_arr,{w=154,h=100})
table_insert(size_arr,{w=130,h=90})
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
    local updateIdArr = {}
    local update_docs = {}
    for _,v in ipairs(hits) do
        local _source = v._source
        local digests = _source.digests
        -- log(ERR,"handle doc:" .. tostring(v._id))
        if digests then
            local bUpdate = false
            for _,dv in ipairs(digests) do
                if dv.sort == "img" then
                    local str_img = dv.content
                    str_img = ngx.re.sub(str_img, "[%.]webp", ".jpg")
                    local imgBytes = getImageByURL(str_img)
                    if imgBytes then
                        local md5 = resty_md5:new()
                        md5:update(imgBytes)
                        local digest = md5:final()
                        digest = resty_string.to_hex(digest)
                        digest = string_sub(digest,9, 24)
                        local m = ngx.re.match(str_img, "(\\.[a-zA-Z0-9]+)$")
                        local suffix = ".jpg"
                        if m then
                            suffix = m[0]
                        end
                        local name =   digest .. suffix
                        dv.content =  'http://cdn.lezomao.com/img/' .. name

                        local img = magick.load_image_from_blob(imgBytes)
                        if img then
                            -- log(ERR,"width:" .. img:get_width() .. ",height:" .. img:get_height());
                            for _,sv in ipairs(size_arr) do
                                 local sizeDir
                                 if sv.w < 1 or sv.h < 1 then
                                    sizeDir = util_context.IMG_DIR .."/origin"
                                 else
                                    sizeDir = util_context.IMG_DIR .."/" .. tostring(sv.w) .."x"..tostring(sv.h)
                                    img:resize(sv.w, sv.h)
                                 end
                                 lfs.mkdir(sizeDir)
                                 local newPath = sizeDir.."/".. name
                                 local resp,err = img:write(newPath)
                                 if err then
                                   log(ERR,"newPath:" .. newPath .. ",err:" .. tostring(err))
                                 else
                                   log(ERR,"newPath:" .. newPath)
                                 end
                            end
                            bUpdate = true
                        end
                    end
                end
            end
            if bUpdate then
               local doc = _source
               doc.id = v._id
               doc.imagick = 1
               table_insert(update_docs, doc)
               table_insert(updateIdArr, v._id)
            end
        end
    end

    local resp,status = content_dao:update_docs(update_docs);
    local str_ids = table.concat( updateIdArr, ",")
    if not resp then
        log(ERR,"fail.magick docs:"..tostring(#update_docs)..",id["..tostring(str_ids).."],cause:", tostring(status))
    else
        log(ERR,"success.magick docs:"..tostring(#update_docs)..",id["..tostring(str_ids).."]")
    end
end

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local query = cjson_safe.decode(post_body)

local to_date = ngx.time()
local from_date = to_date - 1*60*60
local body = {
    _source = {"digests"},
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