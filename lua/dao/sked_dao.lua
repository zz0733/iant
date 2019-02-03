local ESClient = require "es.ESClient"


local _M = ESClient:new({index = "sked", type = "table"})
_M._VERSION = '0.01'


return _M

