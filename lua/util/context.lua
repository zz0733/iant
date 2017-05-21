local util_table = require "util.table"
local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'


local shared_dict = ngx.shared.shared_dict
local key_version = "app_verion"

function _M.version(new_ver)
    if new_ver then
        shared_dict:set(key_version,new_ver) 
        return new_ver
    end
    local ver =  shared_dict:get(key_version)
   
   return ver or _M.version(ngx.time())
end

return _M