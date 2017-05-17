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
local min_date = 0
local scan_count = 0
local period_date = 60

local match = ngx.re.match
local last_worker = ngx.worker.count() - 1

local intact = require("util.intact")
local util_table = require "util.table"
local similar = require("util.similar")
local content_fields = {"names","directors","issueds","article","ctime"}
local link_fields = nil


local find_year = function ( name )
    if not name then
        return
    end
    local m, err = match(name, "(^|[^0-9])(19[0-9]{2}|20[0-9]{2})([^0-9]|$)")
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


local update_match_doc = function ( doc, hits )
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
        local cur_title = article.title
        local cur_code = article.code
        max_issued = to_time_mills(max_issued or 1)
        min_issued = to_time_mills(min_issued or 1)
        log(ERR,"select_match_doc[".. v._id .."],title["..title .."]vs["..cur_title.."]code[".. cur_code .."],year["..has_year .."]vs[" .. cur_year .."],link["..start_mills..","..end_mills.."],issued["..min_issued..","..max_issued.."]")
        if ((cur_year and cur_year == has_year) or (start_mills <= max_issued and end_mills >= min_issued) ) then
            local highlight = v.highlight
            if highlight then
                local names = highlight.names
                if names then
                     local hl_name = names[1]
                     local seg_score = similar.getSegmentDistance(title, hl_name)
                     local imdb_score = similar.getImdbDistance(source.imdb, doc.code)
                     local director_score = similar.getDirectorDistance(source.directors, doc.directors)
                     local actor_score = similar.getDirectorDistance(source.actors, doc.actors)
                     local score = seg_score + imdb_score + director_score
                     local is_pass = score >= 0.7
                     log(ERR,"select_match_doc_score:"..tostring(is_pass)..",title["..title .."]vs["..cur_title.."],seg:"..tostring(seg_score) 
                            ..",imdb:" .. tostring(imdb_score)
                            ..",director:" .. tostring(director_score) 
                            .. ",actor:"..tostring(actor_score)
                            ..",score:" .. tostring(score))
                     if is_pass then
                         score = tonumber(string.format("%.3f", score))
                         local target = {id = v._id, score = score, status=0 }
                         targets[#targets + 1] = target
                     end
                end
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
    local title = source.names
    local offset = 0
    local limit = 1000
    local max_issued = -1
    local start = ngx.now()
    local resp, status = link_dao.query_by_titles(offset, limit, source.names, link_fields)
    ngx.update_time()
    local cost = (ngx.now() - start)
    cost = tonumber(string.format("%.3f", cost))
    if resp then
        local total  = resp.hits.total
        local hits  = resp.hits.hits
        local shits = cjson_safe.encode(hits)
        update_match_doc(doc, hits)
        log(ERR,"find_similars,title["..title .."],offset:" .. offset .. ",limit:" .. limit 
            .. ",max_issued:"..max_issued.. ",total:" .. total .. ",cost:" .. cost)
        -- log(ERR,"find_similars,title["..title .."],offset:" .. offset .. ",limit:" .. limit .. ",hit:" .. shits .. ",targets:" .. tostring(stargets))
        
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

local query_min_ctime = function (  )
   local body = {
        size = 0,
        aggs  = {
            min_ctime  = { min  = { field  = "ctime" } }
        }
    }
   local min_ctime = 0
   local resp, status = content_dao:search(body)
   if resp and resp.aggregations and resp.aggregations.min_ctime then
       min_ctime = resp.aggregations.min_ctime.value
   end
   return min_ctime
end


local check

 check = function(premature)
     if not premature then
         if min_date < 1 then
            min_date = query_min_ctime()     
         end
         if from == 0  and from_date > 0 then
             from_date = to_date - period_date
         end
         local start = ngx.now()
         local resp, status = content_dao:query_by_ctime(from, limit, from_date, to_date, content_fields)
         ngx.update_time()
         local cost = (ngx.now() - start)
         cost = tonumber(string.format("%.3f", cost))
         if resp then
            local total  = resp.hits.total
            local hits  = resp.hits.hits
            scan_count = scan_count + #hits
            local shits = cjson_safe.encode(hits)
            log(ERR,"query_by_ctime,range["..min_date..","..from_date .."," .. to_date .. "],from:" .. from .. ",size:" .. size .. ",total:" .. total ..",hits:" .. tostring(#hits).. ",scan:"..scan_count..",cost:" .. cost)
            -- search_similars(hits)
            if (total == 0) or (from >= total) then
               from = 0
               to_date = from_date
               if to_date <= min_date then
                   scan_count = 0
                   from_date = 0
                   to_date = ngx.time()
                   local ok, err = new_timer(done_wait, check)
                    if not ok then
                         log(CRIT, "done.failed to create timer: ", err)
                         return
                    else
                        log(ERR, "done.wait["..done_wait.."],create timer: ")
                    end
               end
            else
                local hit_count = #hits
                if hit_count < 1 then
                   to_date = from_date
                   from = 0
                else 
                   local last = hits[hit_count]
                   local last_date = last._source.ctime
                   if from_date > 1  then
                       from = from + hit_count
                   else 
                       from_date = last_date
                       from = 0
                   end
                end
  
            end
         else 
           log(ERR,"query_by_ctime,range["..from_date .."," .. to_date .. "],from:" .. from .. ",size:" .. size .. ",cost:"..cost..",cause:", tostring(status))
         end
         
         local ok, err = new_timer(delay, check)
         if not ok then
             log(ERR, "failed to create timer: ", err)
             return
         end
     end
 end

 if last_worker == ngx.worker.id() then
     log(ERR, "match_timer["..ngx.worker.id() .."] start")
     local ok, err = new_timer(delay, check)
     if not ok then
         log(ERR, "match_timer fail to run: ", err)
         return
     end
 end