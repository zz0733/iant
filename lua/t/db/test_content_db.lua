local content_db = require "db.content_db"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="rocksdb"})
local cjson_safe = require("cjson.safe")

local test_id = "test_link_id"
-- local test_id = "b1332440830"
function tb:init()
    self:log("init complete")
end

function tb:test_save_then_read()
    local key = "key"
    local val = "val123"
    content_db.put(key, val)
    local sVal = content_db.get(key)
    self:log("key:"..key..",val:" .. tostring(sVal))
end

tb:run()