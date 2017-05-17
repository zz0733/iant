-- init_worker_by_lua
local link_dao = require "dao.link_dao"
local content_dao = require "dao.content_dao"
local cjson_safe = require("cjson.safe")
local delay = 5  -- in seconds
local done_wait = 6  -- in seconds
local new_timer = ngx.timer.at

local log = ngx.log
local ERR = ngx.ERR
local INFO = ngx.ERR
local CRIT = ngx.CRIT
local from = 0
local size = 10
local from_date = 0
local to_date = ngx.time()
local min_date = 0
local scan_count = 0
local period_date = 60*60

local match = ngx.re.match
local last_worker = ngx.worker.count() - 1

local intact = require("util.intact")
local util_table = require "util.table"
local extract = require("util.extract")
local similar = require("util.similar")


local content_fields = {"names","directors","issueds","article","ctime"}
local link_fields = nil

local desc_score_comp = function ( a, b )
    if not a or not a.score then
        return true
    end
    if not b or not b.score then
        return false
    end
    return   b.score < a.score
end

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
    if not issueds then
        return dest
    end
    for _,v in ipairs(issueds) do
        if v.time and (not dest or v.time > dest) then
            dest = v.time
        end
    end
    dest = tonumber(dest)
    if dest and string.len(tostring(dest)) > 10  then
        dest = math.modf(dest / 1000)
    end
    return dest
end

local min_issued_time = function ( doc )
    local dest = nil
    local source = doc._source
    local issueds = source.issueds
    if not issueds then
        return dest
    end
    for _,v in ipairs(issueds) do
        if v.time and (not dest or v.time < dest) then
            dest = v.time
        end
    end
    dest = tonumber(dest)
    if dest and string.len(tostring(dest)) > 10  then
        dest = math.modf(dest / 1000)
    end
    return dest
end


local update_match_doc = function ( doc, hits )
    if not hits then
        return
    end
    local doc_source = doc._source
    local dest_update_docs = {}
    local max_cur_issued = max_issued_time(doc) or doc_source.ctime
    local min_cur_issued = min_issued_time(doc) or 0
    local article = doc_source.article
    local cur_year = article.year or 0
    local cur_title = article.title
    local cur_code = article.code
    for _,v in ipairs(hits) do
        local link_source = v._source
        local link_title = link_source.title
        local link_year = find_year(link_title) or 1970
        local start_mills = os.time({year=link_year,month=1,day=1,hour=0,min=0,sec=0})
        local end_mills = max_issued_time(v) or link_source.ctime
        if not end_mills then
            if not link_source.utime then
               end_mills =  ngx.time()
               log(ERR,"update_match_doc,link[".. v._id .."],title["..link_title.."],end_mills use ngx.time")
            else
               end_mills =  link_source.utime
               log(ERR,"update_match_doc,link[".. v._id .."],title["..link_title.."],end_mills use utime")
            end
        end
        log(ERR,"update_match_doc[".. doc._id .."],title["..cur_title .."]vs["..link_title.."]code[".. cur_code .."],year["..cur_year .."]vs[" .. link_year .."],link["..start_mills..","..tostring(end_mills).."],issued["..min_cur_issued..","..max_cur_issued.."]")
        if ((cur_year and cur_year == link_year) or (start_mills <= max_cur_issued and end_mills >= min_cur_issued) ) then
            local highlight = v.highlight
            if highlight  and highlight.title then
                     local hl_name = highlight.title[1]
                     local seg_score = similar.getSegmentDistance(cur_title, hl_name)
                     local imdb_score = similar.getImdbDistance(article.imdb, doc.code)
                     local director_score = similar.getDirectorDistance(doc_source.directors, doc.directors)
                     local actor_score = similar.getDirectorDistance(doc_source.actors, doc.actors)
                     local score = seg_score + imdb_score + director_score
                     local is_pass = score >= 0.7
                     log(ERR,"update_match_doc_score:"..tostring(is_pass)..",title["..cur_title .."]vs["..link_title.."],seg:"..tostring(seg_score) 
                            ..",imdb:" .. tostring(imdb_score)
                            ..",director:" .. tostring(director_score) 
                            .. ",actor:"..tostring(actor_score)
                            ..",score:" .. tostring(score))
                     if is_pass then
                         score = tonumber(string.format("%.3f", score))
                         local old_targets = link_source.targets or {}
                         local target_map =  {}
                         for _,v in ipairs(old_targets) do
                             target_map[v.id] = v
                         end
                         local old_target = target_map[doc._id]
                         local new_target = {id = doc._id, score = score, status=0 }
                         if not util_table.equals(nil, new_target) then
                             target_map[new_target.id] = new_target
                             local dest_targets = {}
                             for k,v in pairs(target_map) do
                                 dest_targets[#dest_targets + 1] = v
                             end
                             table.sort(dest_targets, desc_score_comp)
                             local update_doc = {}
                             update_doc.id = v._id
                             update_doc.targets = dest_targets
                             update_doc.status = 1
                             update_doc.episode = extract.find_episode(link_title)
                             update_doc.season = extract.find_season(link_title)
                             dest_update_docs[#dest_update_docs + 1] = update_doc
                             local str_docs = cjson_safe.encode(update_doc)
                             log(ERR,"match add("..update_doc.id .. "),content[".. doc._id .."],doc:" ..tostring(str_docs) .. ",len:"..tostring(#dest_update_docs))
                         else
                            log(ERR,"match.ignore exist("..v._id .. "),content[".. doc._id .."]")
                         end
                     end
            end
        end
    end
    local str_targets = cjson_safe.encode(dest_update_docs)
    log(ERR,"update_match_doc_targets("..doc._id .. "),title["..cur_title .."],update_docs:"..tostring(str_targets) ..",size["..#dest_update_docs .."]")
    local resp, status = link_dao:update_docs(dest_update_docs)
    if resp then
        local lcount = link_dao:count_by_target(doc._id)
        local content_docs = {}
        local update_doc = {}
        update_doc.id = doc._id
        update_doc.lcount = lcount
        content_docs[#content_docs + 1] = update_doc
        local resp, status = content_dao:update_docs(content_docs)
        if resp then
            log(ERR,"update.match count,content[".. doc._id .."],lcount:" .. lcount)
        else
            log(CRIT,"update.match count,content[".. doc._id .."],lcount:" .. lcount..",cause:", tostring(status))
        end
    end
end

local build_similar = function ( doc )
    if not doc then
        return
    end
    local source = doc._source
    local article = source.article
    local title = article.title
    local offset = 0
    local limit = 50
    local dstart = ngx.now()
    local str_doc = cjson_safe.encode(doc)
    log(ERR,"build_similar,title["..title .."],str_doc:" .. str_doc)
    while true do
        local start = ngx.now()
        local resp, status = link_dao:query_by_titles(offset, limit, source.names, link_fields)
        ngx.update_time()
        local cost = (ngx.now() - start)
        cost = tonumber(string.format("%.3f", cost))
        if resp then
            local total  = resp.hits.total
            local hits  = resp.hits.hits
            local hcount  = #hits
            local shits = cjson_safe.encode(hits)
            update_match_doc(doc, hits)
            log(ERR,"build_similar,title["..title .."],offset:" .. offset .. ",limit:" .. limit 
                .. ",total:" .. total .. ",cost:" .. cost)
            offset = offset + hcount
            if offset >=total or hcount < 1  then
                break
            end
        else
            log(CRIT,"error.build_similar,title["..title .."],offset:" .. offset .. ",limit:" .. limit 
                .. ",status:" .. tostring(status) .. ",cost:" .. cost)
        end
    end
    local cost = (ngx.now() - dstart)
    cost = tonumber(string.format("%.3f", cost))
    log(ERR,"build_similar.end,title["..title .."],total:" .. tostring(offset) ..",cost:" .. tostring(cost))

end

local build_similars = function (hits )
    if not hits then
        return
    end
    for _,v in ipairs(hits) do
        build_similar(v)
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
       min_ctime = tonumber(resp.aggregations.min_ctime.value) or 0
   end
   local str_min_ctime = cjson_safe.encode(min_ctime)
   log(ERR,"min_ctime:" .. str_min_ctime)
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
            build_similars(hits)
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
                    return
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