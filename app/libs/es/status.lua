local cjson_safe = require "cjson.safe"
local ESClient = require "app.libs.es.client"


local _M = ESClient:new({
    index = "status",
    type = "table",
    template = {
        id = "id",
        userId = "userId",
        sortId = 1,
        like = 100, -- 点赞
        comment = 100, -- 评论
        collect = 100, -- 收藏
        follow = 100, -- 关注
        view = 100, -- 观看
        cstatus = 1, -- {0:"待审核", 1:"已发布", 2:"已下线", 3:"审核失败"}
        pstatus = 1, -- {0:"待审核", 1:"已发布", 2:"已下线", 3:"审核失败"}
        pstatus = 1, -- {0:"待审核", 1:"已发布", 2:"已下线", 3:"审核失败"}
        ctime = 1496125632,
        utime = 1496125632,
        vip = 1,
        qq_score = 100,
        douban_score = 100
    }
})
_M._VERSION = '0.01'

function _M:save(source)
    local index_bean = self:to_index(source)
    ngx.log(ngx.ERR, "index_bean:" .. cjson_safe.encode(index_bean))
    if index_bean then
        local index_arr = {}
        table.insert(index_arr, index_bean)
        return self:update_docs(index_arr)
    end
    return "illegal params", 400
end

return _M