-- init_worker_by_lua
local link_dao = require "dao.link_dao"
local content_dao = require "dao.content_dao"
local cjson_safe = require("cjson.safe")
local delay = 1  -- in seconds
local done_wait = 60*60*5  -- in seconds
local new_timer = ngx.timer.at

local client_utils = require("util.client_utils")

local log = ngx.log
local ERR = ngx.ERR
local INFO = ngx.ERR
local CRIT = ngx.CRIT

local shared_dict = ngx.shared.shared_dict
local key_match_to_date = "match_to_date"
shared_dict:delete(key_match_to_date)

local key_match_scroll_id = "match_scroll_id"


local sourceClient = client_utils.client()
local sourceIndex = "content";
local query = {};
local scrollId = shared_dict:get(key_match_scroll_id)
local scroll = "1m";
local scanParams = {};
local bulkParams = {};

-- Performing a search query
scanParams.index = sourceIndex
-- scanParams.search_type = "scan"
scanParams.scroll = scroll
-- scanParams.sort = {"_doc"}
scanParams.size = 10
scanParams.body = query

local scan_count = 0

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
        local time = tonumber(v.time)
        if time and (not dest or time > dest) then
            dest = time
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
        local time = tonumber(v.time)
        if time and (not dest or time < dest) then
            dest = time
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
                         if util_table.is_table(old_targets) then
                             for _,v in ipairs(old_targets) do
                                 if v.tscore then
                                     target_map[v.id] = v
                                 end
                             end
                         else
                            log(ERR,"bad link[".. v._id .."],old_targets:" ..  cjson_safe.encode(old_targets))
                         end
     
                         local old_target = target_map[doc._id]
                         local new_target = {id = doc._id, score = score, tscore= v._score, status=0}
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
    local max_count = 200
    local dstart = ngx.now()
    local str_doc = cjson_safe.encode(doc)
    log(ERR,"build_similar,title["..title .."],str_doc:" .. str_doc)
    while true do
        local start = ngx.now()
        local resp, status = link_dao:query_by_titles(source.names, offset, limit, link_fields)
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
            if offset >=total or offset >= max_count or hcount < 1  then
                break
            end
        else
            log(CRIT,"error.build_similar,title["..title .."],offset:" .. offset .. ",limit:" .. limit 
                .. ",status:" .. tostring(status) .. ",cost:" .. cost)
            break
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


local check

 check = function(premature)
     if not premature then
         local data,err;
         local start = ngx.now()
         if not scrollId then
             data, err = sourceClient:search(scanParams)
         else
            data, err = sourceClient:scroll{
              scroll_id = scrollId,
              scroll = scroll
            }
         end
         if data == nil or #data["hits"]["hits"] == 0 then
            local ok, err = new_timer(done_wait, check)
            if not ok then
                 log(CRIT, "done.failed to create timer: ", err)
                 return
            else
                log(ERR, "done.wait["..done_wait.."],scan:"..scan_count..",create timer: ")
            end
            scrollId = nil
            scan_count = 0
         else
             local total = data.hits.total
             local hits = data.hits.hits
             local shits = cjson_safe.encode(hits)
             log(ERR,"hits:" .. shits)
             scan_count = scan_count + #hits
             ngx.update_time()
             local cost = (ngx.now() - start)
             cost = tonumber(string.format("%.3f", cost))
             log(ERR,"scrollId["..tostring(scrollId) .. "],total:" .. total ..",hits:" .. tostring(#hits) 
                    .. ",scan:" .. tostring(scan_count)..",cost:" .. cost)
             build_similars(hits)
             scrollId = data["_scroll_id"]
         end
         local ok, err = shared_dict:set(key_match_scroll_id, scrollId )
         if ok then
             log(ERR,"shared_dict.set[" .. key_match_scroll_id .. "=" .. tostring(scrollId) .. "]" )
         else
            log(CRIT,"error.shared_dict.set[" .. key_match_scroll_id .. "=" .. tostring(scrollId) .. "],cause:", err)
         end
         local ok, err = new_timer(delay, check)
         if not ok then
             log(ERR, "failed to create timer: ", err)
             return
         end
     end
 end

 if 0 == ngx.worker.id() then
     log(ERR, "match_timer["..ngx.worker.id() .."] start")
     local ok, err = new_timer(delay, check)
     if not ok then
         log(ERR, "match_timer fail to run: ", err)
         return
     end
 end