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



tb:run()