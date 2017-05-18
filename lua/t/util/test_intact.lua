local util_intact = require "util.intact"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="util_intact"})
local cjson_safe = require("cjson.safe")

function tb:init()
    self:log("init complete")
end

local to_highlight = function ( name )
    local hl_arr = {}
    if not name then
        return hl_arr
    end
    local it, err = ngx.re.gmatch(name, "<em>(.+?)<\\/em>", "ijo")
    if not it then
       return hl_arr
    end
     while true do
         local m, err = it()
         if m then
            hl_arr[#hl_arr + 1] = m[1]
         else
            break
         end
     end
     return hl_arr
end

function tb:test_0to_intact_words()
    local case_arr = { 
        {
          title = "23号公寓的坏女孩 第一季 Don't Trust the B---- in Apartment 23 Season 1‎ (2012",
          -- special characters escape, cause: utf8.lua:756: invalid regex after TrustB-- 
          hl_title = "<em>Don</em>'<em>t</em> <em>Trust</em> the <em>B----</em> in <em>Apartment</em> <em>23</em>"
       },
       {
          title = "23号公寓的坏女孩 第一季 Don't Trust the B---- in Apartment 23 Season 1‎ (2012",
          hl_title = "<em>23</em><em>号</em><em>公寓</em>第二<em>季</em>/<em>23</em><em>号</em><em>公寓</em>.第二<em>季</em>EP04.mkv",
       }
    }
    for t,v in ipairs(case_arr) do
        local e = util_intact.to_intact_words(v.title, to_highlight(v.hl_title))
        local str_v = cjson_safe.encode(v)
        if  e then
            local str_e = cjson_safe.encode(e)
            self:log(t .. ",exisods expect["..str_v.."],but[" .. tostring(str_e) .. "]")
        else
            error(t .. ",exisods expect["..str_v.."],but[ nil]")
        end
    end
end


tb:run()