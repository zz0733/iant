local util_movie = require "util.movie"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="util_movie"})
local cjson_safe = require("cjson.safe")
local util_string = require("util.string")


function tb:init()
    self:log("init complete")
end

function tb:test_0equals()
    local linkURL = 'magnet:?xt=urn:btih:a14a3a79234c7844447fd8f2fce233e71425221a'
    local expect = 'm614785471'
    local id = util_movie.makeId(linkURL)
    if expect ~= id then
       error(linkURL .. ",id expect["..expect.."],but[" .. tostring(id) .. "]")
    end
end

function tb:test_match()
    local body = "http://data.video.iqiyi.com/videos/v0/20150416/b9/60/b44c5df8ad4da4b3b1b71c9b44e0440e.ts?qypid=103541100"
    local res = string.match(body,"%.ts%?")
    local expect = ".ts?"
    if not res  then
       error(body .. ",string.match expect["..expect.."],but[" .. tostring(res) .. "]")
    else
       self:log(body .. ",string.match expect["..expect.."],and actual[" .. tostring(res) .. "]")
    end
    local sourcURL = "http://data.video.iqiyi.com\nhttp://data.video.iqiyi.com2"
    local actual = ngx.re.gsub(sourcURL, "http://", "//")
    local expect = "//data.video.iqiyi.com\n//data.video.iqiyi.com2"
    if expect ~=  actual then
       error(body .. ",ngx.re.gsub expect["..expect.."],but[" .. tostring(actual) .. "]")
    else
       self:log(body .. ",ngx.re.gsub expect["..expect.."],and actual[" .. tostring(actual) .. "]")
    end
    self:log("type(sourcURL)=" .. type(sourcURL))
    local metaURL = 'http://v-acfun.com/v_19rqzp6oy0.html'
    local metaId = '13627749211415260000'
    local oldId = '1155549679'

    local hasCstatus = 6
    if bit.band(bit.rshift(hasCstatus,2),1) == 1 then
        hasCstatus = bit.bxor(hasCstatus, 4)
    elseif bit.band(bit.rshift(hasCstatus,1),1) == 1 then
        hasCstatus = bit.bxor(hasCstatus, 2)
    end 
    self:log( "hasCstatus:" .. bit.rshift(hasCstatus,2))
    self:log( "hasCstatus:" .. hasCstatus)

    local metaBody = "#EXTM3U\n#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=800000,RESOLUTION=1080x608\nhttps://fuli.zuida-youku-le.com/20180626/28905_62f204a7/index.m3u8"
    local matchURL = string.match(metaBody,"http[^\n%s]+")
    self:log( "matchURL:" .. tostring(matchURL))
    self:log( "metaBodyMath:" .. tostring(string.match(metaBody, "#EXT%-X%-STREAM%-INF:PROGRAM%-ID=1,BANDWIDTH=")))
    local oldpat = "EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH="
    local newpat = string.gsub(oldpat,"([^\\])%-","%1%%%-")
    self:log( "metaBodyMath:" .. tostring(string.match(metaBody, newpat)))
    self:log( "subTaskId:" .. string.sub("c6add4444d144264ba6214402780902a", -8))
    self:log( "contains:" .. tostring(string.contains("contains", "axi")))
end

tb:run()