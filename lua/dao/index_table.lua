local elasticsearch = require "elasticsearch"
local rawget = rawget

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 155)
_M._VERSION = '0.01'

local mt = { __index = _M }




function _M.new(self)
    local client = elasticsearch.client{
	  hosts = {
	    {
	      host = "localhost",
	      port = "9200"
	    }
	  }
	}

    return setmetatable({ _client = client, }, mt)
end

local common_cmds = {
    "get",      "mget",          "search",     "scroll"
    "update",      "index",          "bulk",     "delete"
}

function _M._do_cmd(self, method,... )
	local client = rawget(self, "_client")
    if not client then
        return nil, "not initialized"
	end
	local args = {...}

end

for i = 1, #common_cmds do
    local cmd = common_cmds[i]

    _M[cmd] =
        function (self, ...)
            return _do_cmd(self, cmd, ...)
        end
end

setmetatable(_M, {__index = function(self, cmd)
    local method =
        function (self, ...)
            return _do_cmd(self, cmd, ...)
        end

    -- cache the lazily generated method in our
    -- module table
    _M[cmd] = method
    return method
end})


return _M
