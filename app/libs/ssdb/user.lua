local ssdb_client = require "app.libs.ssdb.client"

local _M = ssdb_client:new({
    key_prefix = "user_",
    template = {
        id = "id",
        name = "user name",
        pwd = "pwd",
        nickname = "昵称",
        role = 1, -- {1:"超级管理员",, 2:"管理员", 3:"普通用户"}
        phone = "15088888888",
        email = "mao@126.com",
        avatar = "avatar",
        family = "李氏",
        ctime = 1496125632,
        utime = 1496125632
    }
})
_M._VERSION = '0.01'


return _M