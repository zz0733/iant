local util_extract = require "util.extract"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="util_extract"})
local cjson_safe = require("cjson.safe")

function tb:init()
    self:log("init complete")
end

function tb:test_0find_episode()
    local title_episods = { 
        ["爸爸好奇怪.2017.连载至EP05"] = 5,
        ["爸爸好奇怪【更新至15】"] = 15,
        ["爸爸好奇怪【更新至6集】"] = 6,
        ["爸爸好奇怪06.rmvb"] = 6 ,
        ["爸爸好奇怪06.rmvbx"] = nil,
        ["绯闻少女S03E10@圣城Lovebeans"] = 10,
        ["爸爸好奇怪【更新至六集】"] = 6
    }
    for t,v in pairs(title_episods) do
        local e = util_extract.find_episode(t)
        if e ~= v then
            error(t .. ",exisods expect["..v.."],but[" .. tostring(e) .. "]")
        end
    end
end

function tb:test_2find_season()
    local title_seasons = { 
        ["头文字D第五部[第2话].mp4"] = 5,
        ["20世纪少年：第一部DVD/20世纪少年：第一部cd2.rmvb"] = 1,
        ["绯闻少女S03E14@中英双字幕"] = 3,
        ["南国医恋第二季/南国医恋.第二季EP10.rmvb"] = 2,
        ["进击的巨人第2季"] = 2
    }
    for t,v in pairs(title_seasons) do
        local e = util_extract.find_season(t)
        if e ~= v then
            error(t .. ",seasons expect["..v.."],but[" .. tostring(e) .. "]")
        end
    end
end


tb:run()