local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 1)
_M._VERSION = '0.01'

local util_table = require("util.table")
local find = ngx.re.find

local log = ngx.log
local ERR = ngx.ERR


_M.is_word_char = function ( char )
    char = tonumber(char)
	if not char then
		return false
	end
	local ret = false
	if char>=48 and char <= 57 then
		-- 0-9：48-57
		ret = true
	elseif char>=65 and char <= 90 then
		-- A-Z：65-90
		ret = true
	elseif char>=97 and char <= 122 then
		 -- a-z：97-122
		ret = true
	elseif char > 127 then
		-- 中文
		ret = true
	end
	return ret

end

_M.is_intact_word = function ( content, word )
    if not content or not word then
        return false
    end
    local from, to, err = find(content, word, "jo")
    if err or not from then
    	return false
    end
    return _M.is_intact_range(content,from, to)
end

_M.is_intact_range = function ( content, from, to )
    if not content then
        return false
    end
    local start_char = string.byte(content, from  - 1, from  - 1)
    local end_char = string.byte(content, to  + 1, to  + 1)
    local ret = true
    if _M.is_word_char(start_char) or _M.is_word_char(end_char) then
    	ret = false
    end
    return ret
end

_M.to_intact_words = function ( content, segments )
	local intacts = {}
    if not content or not segments then
        return intacts
    end
    if not util_table.is_table(segments) or util_table.is_empty_table(segments) then
    	return intacts
    end
    local word = nil
    local len = #segments
    local index = 1
    while index <= len do
    	local add = false
    	local from, to
    	local step = 0
    	local seg = ""
    	while index + step <= len do
    		log(ERR,"step:".. step .. ",index:" .. index .. ",len:" .. len)
    		seg = seg .. segments[index + step]
			from, to, err = find(content, seg, "jo")
	    	if err or not from then
	    		break
			end
			if _M.is_intact_range(content,from, to) then
				intacts[#intacts + 1] = {from = from, seg = seg}
				add = true
				break
			end
			step = step + 1
	    end
	    if add then
	    	index = index + step
	    end
	    index = index + 1
    end
    return intacts
end


return _M