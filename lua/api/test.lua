local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"

local name = [[继承人2017]]
local name = [[1901继承人2017]]
local name = [[190继承人.2017]]
local name = [[巴霍巴利王2.2017]]
-- local name = [[破产姐妹【第四季】]]

local find = ngx.re.find
local intact = require("util.intact")
local utf8 = require("3th.utf8")
local link_dao = require "dao.link_dao"
local script_dao = require "dao.script_dao"


local hit_arr = {}
hit_arr[#hit_arr + 1] = "190"
hit_arr[#hit_arr + 1] = "继承人"
hit_arr[#hit_arr + 1] = "2017"

hit_arr={"巴","霍","巴","利","王","2017"}
-- hit_arr={"破产","姐妹","第四季"}
-- hit_arr={"破产姐妹","第四季"}

-- local rchar = intact.to_intact_words(name,hit_arr)
-- local concats = intact.concat_segments(name,hit_arr)
local lchar = cjson_safe.encode(hit_arr)
local rchar = intact.to_intact_words(name,hit_arr)
rchar = cjson_safe.encode(rchar)
-- local rchar = to_intact_words(name,"继承人")
 ngx.say("end:" .. name .. ",lchar:"..lchar .. ",rchar:" .. tostring(rchar) .. ",len:" .. tostring(string.len(name)))

 local id = "b2714164294"
 local doc = {}
 local targets = {}
 targets[#targets + 1] = {id="123",score=1.23,status=1}
 doc.targets = targets
 doc.status = 1
 local resp, status = script_dao.search_all_ids()
 local str_resp = cjson_safe.encode(resp)
  ngx.say("str_resp:" .. str_resp .. ",status:".. tostring(status))
