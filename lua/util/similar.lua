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

local utf8sub = utf8.sub
local utf8gsub = utf8.gsub
local utf8find = utf8.find
local utf8len = utf8.len
local utf8match = utf8.match

local log = ngx.log
local ERR = ngx.ERR

local cjson_safe = require "cjson.safe"
local intact = require("util.intact")

local remove_highlight_tags = function ( hl_title )
   if not hl_title then
       return hl_title
   end
   return utf8gsub(hl_title, "<[/]?em>", "", "i")
end

local to_highlight = function ( name )
    local hl_arr = {}
    if not name then
        return hl_arr
    end
    local it, err = ngx.re.gmatch(name, "<em>(.+?)<\\/em>", "ijo")
    if not it then
       return hl_arr
    end
     while true do
         local m, err = it()
         if m then
            hl_arr[#hl_arr + 1] = m[1]
         else
            break
         end
     end
     return hl_arr
end

local filter_chars = function ( title )
    return intact.filter_spec_chars(title)
end

local matches = function ( first, second )
    local max = first
    local max_len = utf8len(max)
    local min = second
    local min_len = utf8len(min)
    if max_len < min_len then
        max = second
        min = first
        local tmp = max_len
        max_len = min_len
        min_len = tmp
    end
    local range = math.max(math.floor(max_len / 2 - 1), 0)
    local matchIndexes = {}
    local matchFlags = {}
    local match_count = 0
    for mi=1,min_len do
        local min_ch = utf8sub(min,mi,mi)
        local xi = math.max(mi - range, 1)
        local xn = math.min(mi + range + 1, max_len)
        for ix =xi,xn do
           local max_ch = utf8sub(max,ix,ix)
           if not matchFlags[ix] and min_ch == max_ch  then
                matchIndexes[mi] = ix;
                matchFlags[ix] = true;
                match_count = match_count + 1
                break
           end
        end
    end
    local ms1 = {}
    local ms2 = {}
    local si = 0
    for i=1,min_len do
       if matchIndexes[i] then
           ms1[si] = utf8sub(min,i,i)
           si = si + 1
       end
    end
    si = 0
    for j=1,max_len do
       if matchIndexes[j] then
           ms2[si] = utf8sub(max,j,j)
           si = si + 1
       end
    end
    local transpositions = 0
    for k,v in ipairs(ms1) do
        if v ~= ms2[k] then
            transpositions = transpositions + 1
        end
    end
    local prefix = 0
    for mi=1,min_len do
       if utf8sub(first,mi,mi) == utf8sub(second,mi,mi) then
           prefix = prefix + 1
        else
            break
       end
    end
    local ret = {}
    ret.match = match_count
    ret.transfer = math.floor(transpositions/2)
    ret.prefix = prefix
    ret.max = max_len
    return ret
end

_M.getJaroWinklerDistance = function ( first, second)
    if not first or not second then
        return 0
    end
    local DEFAULT_SCALING_FACTOR = 0.1
    local mtp = matches(first, second)
    local str_mtp = cjson_safe.encode(mtp)
    log(ERR,"str_mtp:" .. str_mtp)
    local match_count = mtp.match
    if match_count < 1 then
        return 0
    end
    local first_match_per = match_count / utf8len(first)
    local second_match_per = match_count / utf8len(second)
    local move_match_per = (match_count - mtp.transfer)/ match_count
    local j = (first_match_per + second_match_per + move_match_per) / 3;
    local jw = j
    if j >= 0.7 then
       jw = j + math.min(DEFAULT_SCALING_FACTOR, 1 / mtp.prefix) * mtp.transfer * (1 - j)
    end
    return math.floor(jw * 100.0 + 0.5) / 100.0;
end

_M.getSegmentDistance = function ( title, hl_title)
    local hl_arr = to_highlight(hl_title)
    local intacts = intact.to_intact_words(title, hl_arr)
    local seg_count = #intacts
    local str_hl_arr = cjson_safe.encode(hl_arr)
    local str_intacts = cjson_safe.encode(intacts)
    local intact_count = 0
    for _,v in ipairs(intacts) do
        if v.intact and not tonumber(v.seg) then
            intact_count = intact_count + 1
        end
    end
    hl_title = remove_highlight_tags(hl_title)

    -- log(ERR,"utf8gsub.hl_title:" .. hl_title)
    title = filter_chars(title)
    hl_title = filter_chars(hl_title)
    local jar_dist = _M.getJaroWinklerDistance(title,hl_title)
    local sim_seg_per = 0
    local score = jar_dist
    if seg_count > 0 and intact_count > 0 then
        sim_seg_per = intact_count / seg_count
        if sim_seg_per >= 1 then
            sim_seg_per = 0.9
        end
        score = math.pow(jar_dist, 1 - sim_seg_per)
    end
    -- local score = char_per*0.4 + 0.6*seg_per
     log(ERR,"select_match_doc_score,title["..title .."],hl_title:"..tostring(hl_title) ..",hl_arr["..str_hl_arr .."],str_intacts:" .. tostring(str_intacts))
     log(ERR,"select_match_doc_score,title["..title .."],sim_seg_per:"..sim_seg_per..",score:" .. tostring(score))
     score = tonumber(string.format("%.3f", score))
     return score
end

return _M