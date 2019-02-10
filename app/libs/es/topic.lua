local cjson_safe = require "cjson.safe"
local table_util = require "app.libs.util.table"
local ESClient = require "app.libs.es.client"

local _M = ESClient:new({
    index = "topic",
    type = "table",
    template = {
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
        year = 2019
    }
})
_M._VERSION = '0.01'

function _M:to_synonyms(regions, field)
    if regions then
        for k, v in ipairs(regions) do
            regions[k] = self:to_synonym(v, field)
        end
    end
end

function _M:save(source)
    local index_bean = self:to_index(source)
    if index_bean then
        self:to_synonyms(index_bean.regions, "ik_smart_synmgroup")
        self:to_synonyms(index_bean.countrys, "ik_smart_synonym")
        local index_arr = {}
        table.insert(index_arr, index_bean)
        return self:index_docs(index_arr)
    end
    return "illegal params", 400
end

return _M