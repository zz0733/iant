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
    local max_issued = max_issued_time(doc)
    max_issued = max_issued or source.ctime
    if string.len(tostring(max_issued))==10 then
        max_issued = max_issued * 1000
    end
    for _,v in ipairs(hits) do
        local min_issued = min_issued_time(v)
        if min_issued then
            if string.len(tostring(min_issued))== 10 then
                min_issued = min_issued * 1000
            end
            log(ERR,"select_match_doc,title["..title .."],max_issued:" .. max_issued .. ",min_issued:" .. tostring(min_issued) ..",max_issued:" .. tostring(max_issued))
            if min_issued < max_issued then
                local source = v._source
                local str_source = cjson_safe.encode(source)
                local names = cjson_safe.encode(source.names)
                local src_title = source.article.title
                log(ERR,"select_match_doc,title["..title .."],score:"..tostring(v._score) ..",src.title["..src_title .."],names".. names .. ",doc:" .. str_source)
            end
        end
    end
end

local do_match_doc = function ( doc )
    if not doc then
        return
    end
    local source = doc._source
    local title = source.title
    local offset = 0
    local limit = 10
    local max_issued = -1
    local start = ngx.now()
    local resp, status = content_dao.query_by_name(offset, limit, title)
    ngx.update_time()
    local cost = (ngx.now() - start)
    cost = tonumber(string.format("%.3f", cost))
    if resp then
        local total  = resp.hits.total
        local hits  = resp.hits.hits
        local shits = cjson_safe.encode(hits)
        log(ERR,"do_match_doc,title["..title .."],offset:" .. offset .. ",limit:" .. limit 
            .. ",max_issued:"..max_issued.. ",total:" .. total .. ",cost:" .. cost)
        -- log(ERR,"do_match_doc,title["..title .."],offset:" .. offset .. ",limit:" .. limit .. ",hit:" .. shits)
        local targets = select_match_doc(doc, hits)
    end
end

local do_match_hits = function (hits )
    if not hits then
        return
    end
    for _,v in ipairs(hits) do
        do_match_doc(v)
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
            do_match_hits(hits)
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