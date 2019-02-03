local util_table = require "util.table"
local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

function _M.year()
	local str_today = ngx.today()
	local m = ngx.re.match(str_today, "([0-9]{4})")
	local year = 2017
    if m and m[1] then
    	year = tonumber(m[1])
    end
    return year
end

return _M