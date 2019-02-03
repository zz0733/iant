local ssdb_client = require "app.libs.ssdb.client"
local topic_es = require "app.libs.es.topic"


local template = {
    id = "id",
    userId = "userId",
    mediaId = 1, -- {1:"资讯", 2:"在线视频", 3:"离线视频", 4:"图集"}
    sortId = 1, -- 电影: 1,电视剧: 2,动漫: 3
    siteId = 1, -- 豆瓣: 1
    title = "title",
    albumId = "albumId",
    epindex = 1,
    issueds = { 1496125632, 1496125633 },
    regions = { "中国", "北美" },
    countrys = { "中国", "美国" },
    genres = { "悬疑", "恐怖" },
    directors = { "大导演" },
    actors = { "演员1", "演员2" },
    authors = { "作者1", "作者2" },
    ctime = 1496125632,
    utime = 1496125632,
    url = "url",
    digests = { "imgURL" },
    names = { "name1", "name2" },
    html = "<html>",
    season = 1,
    cost = 1,
    year = 2018
}
if topic_es.template then
    for k, v in pairs(topic_es.template) do
        template[k] = v
    end
end

local _M = ssdb_client:new({
    key_prefix = "topic_",
    template = template
})
_M._VERSION = '0.01'


return _M