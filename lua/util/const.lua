local util_table = require "util.table"
local cjson_safe = require "cjson.safe"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

-- // 内容类型
_M.MEDIA_DICT = {
    ["影视信息"] = 0,
    ["在线视频"] = 1
}
-- // 内容分类
_M.SORT_DICT = {
    ["电影"] = 0,
    ["电视剧"] = 1
}

_M.LANG_DICT = {
    ["英语"] = 10,
    ["英文"] = 10,
    ["汉语"] = 20,
    ["中文"] = 20,
    ["普通话"] = 20,
    ["粤语"] = 21,
}

_M.SOURCE_DICT = {
    ["豆瓣"] = 0,
    ["爱奇艺"] = 1,
    ["腾讯视频"] = 2,
    ["优酷视频"] = 3
}

_M.VIP_DICT = {
    ["预告"] = 0,
    ["会员"] = 1,
    ["普通"] = 2
}

_M.CSTATUS_DICT = {
    ["默认"] = 0,
    ["题图"] = 1,
    ["视频"] = 2
}

_M.PSTATUS_DICT = {
    ["默认"] = 0,
    ["上线"] = 1,
    ["下线"] = 2
}


function _M.name2Index( cmd, name )
    return _M[cmd][name]
end

function _M.index2Name( cmd, index )
    local cmdDict = _M[cmd]
    -- log(ERR,"SORT_DICT:" .. cjson_safe.encode(cmdDict) ..",index:" .. tostring(index))
    for k,v in pairs(cmdDict) do
        if index == v then
            return k
        end
    end
    return 
end

return _M