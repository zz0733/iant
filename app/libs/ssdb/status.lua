local ssdb_client = require("app.libs.ssdb.client")
local status_es = require("app.libs.es.status")

local template = {}
if status_es.template then
    for k, v in pairs(status_es.template) do
        template[k] = v
    end
end
--包含索引字段和独ssdb存储
local _M = ssdb_client:new({
    key_prefix = "status_",
    template = template,
    update_by_crawler = {
        vip = 1,
        qq_score = 100,
        douban_score = 100
    }
})
_M._VERSION = '0.01'


return _M