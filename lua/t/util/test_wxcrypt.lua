local wxcrypt = require "util.wxcrypt"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="util_extract"})
local cjson_safe = require("cjson.safe")

local log = ngx.log
local ERR = ngx.ERR

function tb:init()
    self:log("init complete")
end

-- function tb:test_0encrypt()
--    local nonce = "12"
--    local timestamp = "1409735669"
--    local to_xml = "123"
--    local encrypt_xml = wxcrypt.encrypt(to_xml)
--    log(ERR,"current:" .. encrypt_xml)
--    local cur_len = string.len(encrypt_xml)
--    local dest_len = 80
--    if cur_len ~= dest_len then
--         error("error,expect len["..tostring(dest_len).."],but[" .. tostring(cur_len) .. "]")
--     end
-- end

-- function tb:test_1decrypt()
--    local nonce = "12"
--    local timestamp = "1409735669"
--    local encrypt_xml = "PMRQVHuo1hA0FwJ0mrGLFb0q2FQWEgvSDRSE4inaLD/GtLMCYkSNtI1p85ZSGfgToXBHyWIE692pZxOmyEmhOxqU70sUwP8hz7p/s57hqao9uACMyG1ZAEq6eEnOAdzevixay2+5CqUk+uKqO5xcU+e7akNQsvMO7SjxxDSHWxeVT4LcTgLcZ1/pxEiVVDiPpZAyi6ya6SWNV4um9E0Fpmx70z6zsNfe8jKJgSmJ//TsqWEKi2ItbTY7aCV669+BjDdohKJjWfCnsGjYbnEuRdV7cWCo83ugDqG8Z1cXqlyPY1ewMhViWQR0YXaRzlADRVdn2EwlxGWrumCDvJ20HiXsv47qgM473m3p60Z4hvRPwBSVwidwwqqgs/oygX6mrqpStub7oLlSE3gn3Q1sgUGAcTqIt3D0siaDFO+BRd24Sl5RSO2kd4KlTZGXmWa3L9pOJQmVd2aSTRIoM+T6OMt4obK5g47Sl/qsVS9s7UeSmX3oNw1YQwsT/8BB0i6E"
--    local to_xml = wxcrypt.decrypt(encrypt_xml)
--    log(ERR,"current:" .. to_xml)
--    local cur_len = string.len(encrypt_xml)
--    local dest_len = 80
--    if cur_len ~= dest_len then
--         error("error,expect len["..tostring(dest_len).."],but[" .. tostring(cur_len) .. "]")
--     end
-- end

-- function tb:test_2encrypt()
--    local input = "886a6620fa9b9042I<xml><URL><![CDATA[http://www.lezomao.com/auth/wx/msgcb]]></URL><ToUserName><![CDATA[gh_d660614a423d]]></ToUserName><FromUserName><![CDATA[od2SawOfo7zAFcs4Q7TBGjS0CQqs]]></FromUserName><CreateTime>1499258756091</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA[妹子]]></Content><MsgId>1499258756091</MsgId></xml>wx824e96d4ea11863a"
--    local ouput = wxcrypt.encrypt(input)
--    log(ERR,"ouput:" .. ouput)
--    local cur_len = string.len(ouput)
--    local dest_len = 80
--    if cur_len ~= dest_len then
--         error("error,expect len["..tostring(dest_len).."],but[" .. tostring(cur_len) .. "]")
--     end
-- end

function tb:test_2signature()
   local timestamp = "1499265774";
   local nonce = "1661975313";
   local encrypt = "5162988984223071214";
   local ouput = wxcrypt.signature(timestamp,nonce,encrypt)
   local sign = "25ba7b8c9a90a7d0fc569e02279216a6e8989657"
   log(ERR,"ouput:" .. ouput)
   if ouput ~= sign then
        error("error,expect len["..tostring(sign).."],but[" .. tostring(ouput) .. "]")
    end
end
tb:run()