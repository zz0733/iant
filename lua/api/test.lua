local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"

local name = [[继承人2017]]
local name = [[1901继承人2017]]
local name = [[190继承人.2017]]

local find = ngx.re.find
local intact = require("util.intact")


local hit_arr = {}
hit_arr[#hit_arr + 1] = "190"
hit_arr[#hit_arr + 1] = "继承人"
hit_arr[#hit_arr + 1] = "xx"
hit_arr[#hit_arr + 1] = "2017"

local rchar = intact.to_intact_words(name,hit_arr)
rchar = cjson_safe.encode(rchar)
-- local rchar = to_intact_words(name,"继承人")
 ngx.say("end:" .. name .. ",rchar:" .. tostring(rchar) .. ",len:" .. tostring(string.len(name)))