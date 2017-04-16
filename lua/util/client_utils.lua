local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 1)
_M._VERSION = '0.01'


local elasticsearch = require "elasticsearch"
local client = elasticsearch.client{
  hosts = {
    {
      host = "localhost",
      port = "9200"
    }
  }
}

function _M.client()
    return client
end

return _M