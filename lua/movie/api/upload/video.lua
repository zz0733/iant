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
ngx.say(cjson_safe.encode(message))