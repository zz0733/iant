local wxcrypt = require "util.wxcrypt"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="util_extract"})
local cjson_safe = require("cjson.safe")

local log = ngx.log
local ERR = ngx.ERR

function tb:init()
    self:log("init complete")
end

function tb:test_0encrypt()
   local nonce = "12"
   local timestamp = "1409735669"
   local to_xml = "123"
   local encrypt_xml = wxcrypt.encrypt(to_xml)
   log(ERR,"current:" .. encrypt_xml)
   local cur_len = string.len(encrypt_xml)
   local dest_len = 80
   if cur_len ~= dest_len then
        error("error,expect len["..tostring(dest_len).."],but[" .. tostring(cur_len) .. "]")
    end
end

tb:run()