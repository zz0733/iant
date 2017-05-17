local util_table = require "util.table"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="util_extract"})
local cjson_safe = require("cjson.safe")

function tb:init()
    self:log("init complete")
end

function tb:test_0equals()
   local case_arr = {
     {left=nil,right=nil,ret=true},
     {left={},right=nil,ret=false},
     {left={},right={},ret=true},
     {left={a=1},right={},ret=false},
     {left={a=1},right={a=1,b=2},ret=false},
   }
   for i,v in ipairs(case_arr) do
       print(i,v)
   end
    for t,v in pairs(case_arr) do
        local e = util_table.equals(v.left,v.right)
        if e ~= v.ret then
            error("case["..t .. "],expect["..tostring(v.ret).."],but[" .. tostring(e) .. "]")
        end
    end
end



tb:run()