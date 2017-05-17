local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"

local name = [[继承人2017]]
local name = [[1901继承人2017]]
local name = [[190继承人.2017]]
local name = [[巴霍巴利王2.2017.123.wex]]
local name = [[破产姐妹【第四季】]]
local name = [[[720粤语]不懂撒娇的女人[第1集].rmvb]]

local find = ngx.re.find
local intact = require("util.intact")
local utf8 = require("3th.utf8")
local link_dao = require "dao.link_dao"
local script_dao = require "dao.script_dao"


local hit_arr = {}
hit_arr[#hit_arr + 1] = "190"
hit_arr[#hit_arr + 1] = "继承人"
hit_arr[#hit_arr + 1] = "2017"

hit_arr={"巴","霍","巴","利","王","2017","123","wex"}
-- hit_arr={"破产","姐妹","第四季"}
-- hit_arr={"破产姐妹","第四季"}
hit_arr={"八个","女人"}

-- local rchar = intact.to_intact_words(name,hit_arr)
-- local concats = intact.concat_segments(name,hit_arr)
local lchar = cjson_safe.encode(hit_arr)
local rchar = intact.to_intact_words(name,hit_arr)
rchar = cjson_safe.encode(rchar)
-- local rchar = to_intact_words(name,"继承人")
 ngx.say("end:" .. name .. ",lchar:"..lchar .. ",rchar:" .. tostring(rchar) .. ",len:" .. tostring(string.len(name)))


local similar = require("util.similar")
local first = "hello"
local second = "hallo"

local first = "人气歌谣.2017.综艺更"
local second = "<em>人气</em><em>歌谣</em> 인기가요‎ (2000)"

-- local score = similar.getJaroWinklerDistance("hello", "hallo") 
-- local score = similar.getJaroWinklerDistance("fly", "ant")
ngx.say("getSegmentDistance:" .. similar.getSegmentDistance(first, second))
ngx.say("getJaroWinklerDistance:" .. similar.getJaroWinklerDistance(first, second))


local content_dao = require "dao.content_dao"
local from = 0
local size = 10
local from_date = 0
local to_date = ngx.time()
local fields = {"utime","ctime"}
local sresp, sstatus = content_dao:query_by_ctime(from, size, from_date, to_date,fields)
local str_sresp = cjson_safe.encode(sresp)
ngx.say("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))

