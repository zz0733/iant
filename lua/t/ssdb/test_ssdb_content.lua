local ssdb_content = require "ssdb.content"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="ssdb_content"})
local cjson_safe = require("cjson.safe")

function tb:init()
    self:log("init complete")
end

function tb:test_set_then_get()
    local key = "550272894"
    local val = { article = { title = "女子的生活"}}
    ssdb_content:set(key, val)
    local get_val = ssdb_content:get(key)
    self:log("key:"..key..",val:" .. cjson_safe.encode(get_val))
end

tb:run()