local ssdb_client = require "app.libs.ssdb.client"

local template = {
    topics = { { id = "id" } }
}

local _M = ssdb_client:new({
    key_prefix = "channel_",
    template = template
})
_M._VERSION = '0.01'


return _M