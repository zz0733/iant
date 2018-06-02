local upload = require "resty.upload"
local resty_md5 = require "resty.md5"
local resty_string = require "resty.string"
local cjson_safe = require "cjson.safe"
local magick = require("magick.gmwand")
local resty_string = require "resty.string"
local util_context = require("util.context")
local lfs = require("lfs")

local string_sub = string.sub
local string_len = string.len
local table_insert = table.insert

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local args = ngx.req.get_uri_args()

local width = args.width or 515
local height = args.height or 220

local size_arr = {}
-- origin image
table_insert(size_arr,{w=0,h=0})
-- table_insert(size_arr,{w=154,h=100})
-- table_insert(size_arr,{w=130,h=90})
-- feed video image
-- table_insert(size_arr,{w=515,h=220})
table_insert(size_arr,{w=width,h=height})

local message = {}
message.code = 200

local chunk_size = 4096
local form = upload:new(chunk_size)
local imgBody = ""
while true do
    local type, res, err = form:read()
    if not type then
         message.error = tostring(err)
         message.code = 400
         break
    end
    if type == "body" then
        imgBody = imgBody .. res
    elseif type == "part_end" then
        break
    elseif type == "eof" then
        break
    else
        -- do nothing
    end
end
function doReturn( message, code )
    message.code = code or message.code
    ngx.say(cjson_safe.encode(message))
end
if not imgBody or string_len(imgBody) < 10 then
    message.error = message.error or 'bad image body'
    return doReturn(message, 400)
end
local img = magick.load_image_from_blob(imgBody)
if not img then
    message.error = message.error or 'bad image body'
    return doReturn(message, 400)
end
local md5 = resty_md5:new()
md5:update(imgBody)
-- 摘要,特征
local digest = md5:final()
digest = resty_string.to_hex(digest)
digest = string_sub(digest,9, 24)
local suffix = img:get_format() or "jpg"
local name =   digest .. '.' .. suffix

-- log(ERR,"width:" .. img:get_width() .. ",height:" .. img:get_height());
for si, sv in ipairs(size_arr) do
     local sizeDir = "origin"
     if sv.w > 1 and sv.h > 1 then
        sizeDir = tostring(sv.w) .."x"..tostring(sv.h)
        -- img:resize(sv.w, sv.h)
        -- img:crop(sv.w, sv.h, x, y)
        img:resize_and_crop(sv.w, sv.h)
     end
     lfs.mkdir(util_context.IMG_DIR .. '/' .. sizeDir)
     local newPath = util_context.IMG_DIR .. '/' .. sizeDir .."/".. name
     local resp,err = img:write(newPath)
     if err then
       message.error = 'magick:' .. sizeDir .. ',cause:' .. tostring(err)
       log(ERR,"newPath:" .. newPath .. ",err:" .. tostring(err))
       return doReturn(message, 500)
     end
     if si == #size_arr then
        message.data = '/img/' .. sizeDir .. '/' .. name
     end
end
img:destroy()
img = nil
ngx.say(cjson_safe.encode(message))