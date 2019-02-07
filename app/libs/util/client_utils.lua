local _M = {}
_M._VERSION = '0.01'


local elasticsearch = require "elasticsearch"
local client = elasticsearch.client{
  hosts = {
    {
      host = "127.0.0.1",
      port = "9200"
    }
  },
  params = {
	maxRetryCount = 1
  }
}

function _M.client()
    return client
end

return _M