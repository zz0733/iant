local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 1)
_M._VERSION = '0.01'

local util_table = require("util.table")
local utf8 = require("3th.utf8")
-- local find = ngx.re.find
-- local match = ngx.re.match

local sub = utf8.sub
-- local find = utf8.find
local utf8len = utf8.len
local utf8match = utf8.match

local log = ngx.log
local ERR = ngx.ERR

local escapse = function ( regex )
     return string.gsub(regex, "%p", "\\\\%1")
end
local find = function (content, regex, ...)
    local str_escape = escapse(regex)
    return utf8.find(content,str_escape, ...)
end

_M.contains_chinese = function ( source )
   if not source then
       return false
   end
   local ulen = utf8len(source)
   local slen = string.len(source)
   return ulen ~= slen
end

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
	elseif char >= 161 and char <= 254 then
		-- 中文
		ret = true
	end
	return ret

end

_M.filter_spec_chars = function(s)  
    local ss = {}  
    for k = 1, #s do  
        local c = string.byte(s,k)  
        if not c then break end  
        if (c>=48 and c<=57) or (c>= 65 and c<=90) or (c>=97 and c<=122) then  
            table.insert(ss, string.char(c))  
        elseif c>=228 and c<=233 then  
            local c1 = string.byte(s,k+1)  
            local c2 = string.byte(s,k+2)  
            if c1 and c2 then  
                local a1,a2,a3,a4 = 128,191,128,191  
                if c == 228 then a1 = 184  
                elseif c == 233 then a2,a4 = 190,165  
                end  
                if c1>=a1 and c1<=a2 and c2>=a3 and c2<=a4 then  
                    k = k + 2  
                    table.insert(ss, string.char(c,c1,c2))  
                end  
            end  
        end  
    end  
    return table.concat(ss)  
end


_M.is_intact_range = function ( content, from, to )
    if not content then
        return false
    end
    local start_char = sub(content, from  - 1, from  - 1)
    local end_char = sub(content, to  + 1, to  + 1)
    local concat = start_char or ""
    if end_char then
    	concat = concat .. end_char
    end
    -- log(ERR,"start_char:" ..tostring(start_char) ..",end_char:" .. tostring(end_char) .. ",concat:" .. tostring(concat))
    local word = _M.filter_spec_chars(concat)
    -- local str_word = cjson_safe.encode(word)
    -- log(ERR,"word:" .. tostring(str_word) ..",#word:" .. #word)
    local ret = (#word == 0)
    return ret
end

_M.wordlen = function (content)
  content = _M.filter_spec_chars(content)
  return utf8len(content)
end

_M.to_intact_words = function ( content, segments )
	local intacts = {}
    if not content or not segments then
        return intacts
    end
    if not util_table.is_table(segments) or util_table.is_empty_table(segments) then
    	return intacts
    end
    local total = utf8len(content)
    local concats = _M.concat_segments(content, segments)
    for _,seg in ipairs(concats) do
    	local from, to, err = find(content, seg)
    	if not err and from then
    		intacts[#intacts + 1] = {from = from, to = to, seg = seg, total = total }
            if _M.is_intact_range(content,from , to) then
                intacts[#intacts].intact = true
            end
    	end
    	
    end
    return intacts
end

_M.concat_segments = function ( content, segments )
	local concats = {}
    if not content or not segments then
        return concats
    end
    if not util_table.is_table(segments) or util_table.is_empty_table(segments) then
    	return concats
    end
    local len = #segments
    local from, to, err
    local i = 1
    while i <= len do
        local seg = segments[i]
        local tmp = nil
        for j = i + 1 , len do
            tmp = seg .. segments[j]
            from, to, err = find(content, tmp)
            if err or not from then
                break
            else
                seg = tmp
                i = j
            end
        end
        concats[#concats + 1] = seg
        i = i + 1
    end
    return concats
end


return _M