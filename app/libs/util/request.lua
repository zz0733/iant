local util_file = require("app.libs.util.file")
local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 1)
_M._VERSION = '0.01'

-- 获取post请求体
function _M.post_body(req)
    if not req then
    	return
    end
	req.read_body()
	local data = req.get_body_data()
	if nil == data then
	    local file_name = req.get_body_file()
	    data = util_file.content(file_name)
	end
    return data
end

return _M