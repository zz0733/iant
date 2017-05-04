-- init_worker_by_lua
local link_dao = require "dao.link_dao"
local content_dao = require "dao.content_dao"
local cjson_safe = require("cjson.safe")
local delay = 5  -- in seconds
local new_timer = ngx.timer.at

local log = ngx.log
local ERR = ngx.ERR
local INFO = ngx.ERR
local CRIT = ngx.CRIT
local from = 0
local size = 1
local from_date = 0
local to_date = ngx.time()
local period_date = 60*1000

local rematch = ngx.re.match

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

local find_year = function ( name )
    if not name then
        return
    end
    local m, err = rematch(name, "(^|[^0-9])(19[0-9]{2}|20[0-9]{2})([^0-9]|$)")
    if m then
        return m[2]
    end
end

local to_time_mills = function ( time )
    if string.len(tostring(time))==10 then
        time = time * 1000
    end
    return time
end

local max_issued_time = function ( doc )
    local dest = nil
    local source = doc._source
    local issueds = source.issueds
    for _,v in ipairs(issueds) do
        if v.time and (not dest or v.time > dest) then
            dest = v.time
        end
    end
    return dest
end

local min_issued_time = function ( doc )
    local dest = nil
    local source = doc._source
    local issueds = source.issueds
    for _,v in ipairs(issueds) do
        if v.time and (not dest or v.time < dest) then
            dest = v.time
        end
    end
    return dest
end


local select_match_doc = function ( doc, hits )
    if not hits then
        return
    end
    local source = doc._source
    local title = source.title
    local end_mills = max_issued_time(doc)
    end_mills = to_time_mills(end_mills or source.ctime)
    local has_year = find_year(title) or 1970
    local start_mills = os.time({year=has_year,month=1,day=1,hour=0,min=0,sec=0}) * 1000
    local targets = {}
    for _,v in ipairs(hits) do
        local max_issued = max_issued_time(v)
        local min_issued = min_issued_time(v)
        local source = v._source
        local article = source.article
        local cur_year = article.year
        max_issued = to_time_mills(max_issued or 1)
        min_issued = to_time_mills(min_issued or 1)
        log(ERR,"select_match_doc,title["..title .."],year:"..has_year..",link["..start_mills..","..end_mills.."],issued["..min_issued..","..max_issued.."]")
        if ((cur_year and cur_year == has_year) or (start_mills <= min_issued and end_mills >= max_issued) ) then
            log(ERR,"select_match_doc,title["..title .."],link["..start_mills..","..end_mills.."],issued["..min_issued..","..max_issued.."]")
            local highlight = v.highlight
            if highlight then
                local names = highlight.names
                if names then
                    local hl_name = names[1]
                    local hl_arr = to_highlight(hl_name)
                    local len_sum = 0
                    for _,lv in ipairs(hl_arr) do
                        len_sum = len_sum + string.len(lv)
                    end
                    local score = len_sum / string.len(title)
                    local str_hl_arr = cjson_safe.encode(hl_arr)
                     log(ERR,"select_match_doc,title["..title .."],hl_name:"..tostring(hl_name) ..",hl_arr["..str_hl_arr .."],score:" .. tostring(score))
                     if score >= 0.7 then
                         local target = {id = v._id, score = score}
                         targets[#targets + 1] = target
                     end
                end
            end
            
            if min_issued < max_issued then
                local source = v._source
                local str_source = cjson_safe.encode(source)
                local names = cjson_safe.encode(source.names)
                local src_title = source.article.title
                log(ERR,"select_match_doc,title["..title .."],score:"..tostring(v._score) ..",src.title["..src_title .."],names".. names .. ",doc:" .. str_source)
            end
        end
    end
    local str_targets = cjson_safe.encode(targets)
    log(ERR,"select_match_doc,title["..title .."],targets:"..tostring(str_targets) ..",size["..#targets .."]")
    return targets
end

local find_similars = function ( doc )
    if not doc then
        return
    end
    local source = doc._source
    local title = source.title
    local offset = 0
    local limit = 10
    local max_issued = -1
    local start = ngx.now()
    -- title = [[继承人2017]]
    source.title = title
    local resp, status = content_dao.query_by_name(offset, limit, title)
    ngx.update_time()
    local cost = (ngx.now() - start)
    cost = tonumber(string.format("%.3f", cost))
    if resp then
        local total  = resp.hits.total
        local hits  = resp.hits.hits
        local shits = cjson_safe.encode(hits)
        log(ERR,"find_similars,title["..title .."],offset:" .. offset .. ",limit:" .. limit 
            .. ",max_issued:"..max_issued.. ",total:" .. total .. ",cost:" .. cost)
        log(ERR,"find_similars,title["..title .."],offset:" .. offset .. ",limit:" .. limit .. ",hit:" .. shits)
        local targets = select_match_doc(doc, hits)
    end
end

local search_similars = function (hits )
    if not hits then
        return
    end
    for _,v in ipairs(hits) do
        find_similars(v)
    end
end



local check

 check = function(premature)
     if not premature then
         if from == 0  and from_date > 0 then
             to_date = from_date + period_date
         end
         local start = ngx.now()
         local resp, status = link_dao.query_unmatch(from_date, to_date, from, size)
         ngx.update_time()
         local cost = (ngx.now() - start)
         cost = tonumber(string.format("%.3f", cost))
         if resp then
            local total  = resp.hits.total
            local hits  = resp.hits.hits
            local shits = cjson_safe.encode(hits)
            log(ERR,"query_unmatch,range["..from_date .."," .. to_date .. "],from:" .. from .. ",size:" .. size .. ",total:" .. total .. ",cost:" .. cost)
            -- log(ERR,"query_unmatch,range["..from_date .."," .. to_date .. "],from:" .. from .. ",size:" .. size .. ",hits:" .. shits)
            search_similars(hits)
            if from == total then
               from = 0
               from_date = to_date
               cur_date = ngx.time()
               if from_date > cur_date then
                   from_date = 0
                   to_date = cur_date
               end
            elseif from_date == 0 then
               local last = hits[#hits]
               from_date = last._source.ctime
               from = 0
            elseif total > 0 then
               from = from + #hits
            end
         else 
           log(ERR,"query_unmatch,range["..from_date .."," .. to_date .. "],from:" .. from .. ",size:" .. size .. ",cost:"..cost..",cause:", tostring(status))
         end
         
         local ok, err = new_timer(delay, check)
         if not ok then
             log(ERR, "failed to create timer: ", err)
             return
         end
     end
 end

 if 0 == ngx.worker.id() then
     log(ERR, "match_timer start")
     local ok, err = new_timer(delay, check)
     if not ok then
         log(ERR, "match_timer fail to run: ", err)
         return
     end
 end