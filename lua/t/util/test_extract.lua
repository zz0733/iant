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
        ["[摔跤吧！爸爸.2016"] = nil,
        ["[摔跤吧！爸爸.20160901"] = nil,
        ["爸爸好奇怪 아버지가 이상해‎ (2017)"] = nil,
        ["绯闻少女S03E10@圣城Lovebeans"] = 10,
        ["爸爸好奇怪【更新至六集】"] = 6,
        ["[我D前半生][2017][EP01-EP34][国语中字][MP4-MKV][720P]"] = 34,
        ["我の前半生.2017.国剧更新（24）"] = 24,
        ["境界之轮回第二季[第04话].mkv"] = 4,
        ["放电无罪/放电无罪02.rmvb"] = 2,
        ["来自星星的你_11[电影"] = 11,
        ["怪侠欧阳德/怪侠欧阳德59.[国语DVD].rmvb"] = 59,
        ["云中歌_41.mkv"] = 41,
        ["[久久影视www.99bo.cc电影天堂]夏家三千金[国语DVD]25.rmvb"] = 25,
        ["重案组.1024x548.国粤双语.中文字幕2.mkv"] = 2,
        ["荆棘花EP54.rmvb"] = 54
    }
    for t,v in pairs(title_episods) do
        local e = util_extract.find_episode(t)
        if e ~= v then
            error(t .. ",exisods expect["..v.."],but[" .. tostring(e) .. "]")
        end
    end
end

-- function tb:test_2find_season()
--     local title_seasons = { 
--         ["头文字D第五部[第2话].mp4"] = 5,
--         ["20世纪少年：第一部DVD/20世纪少年：第一部cd2.rmvb"] = 1,
--         ["绯闻少女S03E14@中英双字幕"] = 3,
--         ["南国医恋第二季/南国医恋.第二季EP10.rmvb"] = 2,
--         ["进击的巨人第2季"] = 2
--     }
--     for t,v in pairs(title_seasons) do
--         local e = util_extract.find_season(t)
--         if e ~= v then
--             error(t .. ",seasons expect["..v.."],but[" .. tostring(e) .. "]")
--         end
--     end
-- end


tb:run()