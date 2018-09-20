local util_movie = require "util.movie"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="util_movie"})
local cjson_safe = require("cjson.safe")

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
end

tb:run()