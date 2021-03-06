local util_table = require "util.table"

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function(narr, nrec) return {} end
end
local _M = new_tab(0, 2)
_M._VERSION = '0.01'

local context = require "util.context"
local ssdb = require "resty.ssdb"

-- can not share 
-- https://github.com/openresty/lua-resty-redis/#limitations
function _M.newClient()
    local ssdbClient = ssdb:new()
    ssdbClient:set_timeout(1000) -- 1 sec
    local _, err = ssdbClient:connect(context.SSDB_HOST, context.SSDB_PORT)
    if err then
        string.error("ssdbErr,connect[", context.SSDB_HOST .. ":" .. context.SSDB_PORT, "],cause:", err)
        return nil, err
    end
    return ssdbClient
end

function _M:open()
    return _M:newClient()
end

function _M:close(client)
    if util_table.isNull(client) then
        return
    end
    local _, err = client:set_keepalive(0, 20)
    if err then
        string.error("ssdbErr,close[", context.SSDB_HOST .. ":" .. context.SSDB_PORT, "],cause:", err)
    end
end

return _M


