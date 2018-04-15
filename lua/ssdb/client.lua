local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
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
    local ok, err = ssdbClient:connect(context.SSDB_HOST, context.SSDB_PORT)
    if not ok then
        ngx.say("failed to connect[" .. context.SSDB_HOST .. ":" .. context.SSDB_PORT .. "],cause:", err)
        return
    end
    return ssdbClient
end

return _M