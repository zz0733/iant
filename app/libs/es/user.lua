local cjson_safe = require "cjson.safe"
local table_util = require "app.libs.util.table"
local ESClient = require "app.libs.es.client"
local user_ssdb = require "app.libs.ssdb.user"

local ignore_dict = {
    pwd = true,
    avatar = true,
}

local template = {}
if user_ssdb.template then
    for k, v in pairs(user_ssdb.template) do
        if not ignore_dict[k] then
            template[k] = v
        end
    end
end
--ngx.log(ngx.ERR, "template:" .. cjson_safe.encode(template))
local _M = ESClient:new({
    index = "user",
    type = "table",
    template = template
})
_M._VERSION = '0.01'


return _M