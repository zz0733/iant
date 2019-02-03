local cjson_safe = require "cjson.safe"
local table_util = require "app.libs.util.table"
local ESClient = require "app.libs.es.client"


local _M = ESClient:new({
    index = "link",
    type = "table",
    template = {
        lid = "lid",
        title = "title",
        imdb = "imdb",
        link = "link",
        secret = "secret",
        directors = { "大导演" },
        ctime = 1496125632,
        utime = 1496125632,
        space = 1496125632,
        season = 1,
        episode = 2,
        episode = 2019,
        target = "target",
        score = 0.8,
        status = 1,
        webRTC = 1,
        level = 1,
        feedimg = "feedimg"
    }
})
_M._VERSION = '0.01'


return _M