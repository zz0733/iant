local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_extract = require "util.extract"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")
local content_dao = require("dao.content_dao")
local ssdb_idf = require("ssdb.idf")

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local string_match = string.match;
local ngx_re_gsub = ngx.re.gsub;
local ngx_re_match = ngx.re.match;
local table_insert = table.insert;
local message = {}
message.code = 200

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local to_date = ngx.time()
local from_date = to_date - 1*24*60*60
local body = {
    query = {
        match_all = {
        }
    }
}

local sourceClient = client_utils.client()
local sourceIndex = "link";
local scroll = "5m";
local scanParams = {};
scanParams.index = sourceIndex
scanParams.scroll = scroll
-- scanParams.sort = {"_doc"}
scanParams.size = 100
scanParams.body = body

local scan_count = 0
local scrollId = nil
local index = 0
local aCount = 0
local total = nil
local begin = ngx.now()
local md5_set = {}
local name_set = {}
local name_arr = {}
local cur_year = os.date("%Y");

function add2Arr(text_arr, source )
   if not source then
      return
   end
   function doFilter( token )
       if not token then
           return true
       end
       if string.match(token, "\\.com$") then
          return true
       end
       return false
   end
   if util_table.is_table(source) then
      for k,v in pairs(source) do
        if v and not doFilter(v) then
           table.insert(text_arr, v)
        end
      end
   else
      if source and not doFilter(source) then
         table.insert(text_arr, source)
      end
   end
   
end

local function isEmpty(s)
  return s == nil or s == ''
end

function knnContents( title, analyze_txt )
    local fields = {"names","article","directors","genres","issueds"}
    local title_arr = {}
    table_insert(title_arr, title)
    local line_arr = string.split(analyze_txt,'\n')
    local maxLen = table.getn( line_arr)
    local len_arr = {2,3,4}
    for _,tokenCount in ipairs(len_arr) do
        if tokenCount <=maxLen then
            for ti=1,tokenCount,1 do
                local merge_list = {}
                table_insert(merge_list, line_arr[ti])
                local merge_txt = table.concat( merge_list , " ")
                table_insert(title_arr, merge_txt)
            end
        end
    end
    local content_set = {}
    for _,vtile in ipairs(title_arr) do
        local resp = content_dao:query_by_name(0, 5, vtile, fields)
        if resp and resp.hits and resp.hits.hits then
            for _,v in ipairs(resp.hits.hits) do
                 local source = v._source
                 if  source and source.article and not content_set[v._id] then
                    article = source.article
                    names = source.names or {}
                   
                    local article = source.article
                    table_insert(names, source.article.title)
                    for ni,nv in ipairs(names) do
                        if not isEmpty(nv)  then
                            local text_arr = {}
                            add2Arr(text_arr, source.article.year)
                            add2Arr(text_arr, nv)
                            if source.directors then
                               add2Arr(text_arr, source.directors)
                            end
                            if source.article.imdb then
                               add2Arr(text_arr, "imdb" .. source.article.imdb)
                            end
                            local splitor = " "
                            local all_txt = table.concat( text_arr , splitor)
                            local aresp,astatus = content_dao:analyze(all_txt,nil,nil,'ik_smart')
                            local analyze_arr = {}
                            if aresp and aresp.tokens then
                               for _,tv in ipairs(aresp.tokens) do
                                   add2Arr(analyze_arr, tv.token)
                               end
                            end
                            local analyze_txt = table.concat( analyze_arr , splitor)
                            local match_data = {}
                            match_data.id = v._id
                            match_data.year = article.year
                            match_data.imdb = article.imdb
                            match_data.analyze = analyze_txt
                            match_data.epcount = 1
                            if article.epcount then
                                match_data.epcount = article.epcount
                            elseif article.media == 'tv' then
                                match_data.epcount = 99999
                            end
                            content_set[match_data.id] = match_data
                        end
                    end
                 end
             end
         end
     end
     return content_set
end

function cosine_match( link_data, content_data )
    if link_data.year and link_data.year > 0 and content_data.year and content_data.year > 0 then
        -- 影视发布年份必须小于资源年份
        if content_data.year > link_data.year then
            return 0
        end
        -- 单集影视,年份必须一样
        if content_data.epcount then
            local epcount = tonumber(content_data.epcount)
            if epcount and epcount == 1 and content_data.year ~= link_data.year then
                return 0 
            end
        end
    end
    if link_data.imdb and link_data.imdb == content_data.imdb then
        return 0.9999
    end
    local splitor = " "
    link_count = count_dict(string.split(link_data.analyze, splitor))
    content_count = count_dict(string.split(content_data.analyze, splitor))
    return tfidf_cosine(link_count, content_count)
end

function count_dict( token_arr )
    token_count = {}
    for _,v in ipairs(token_arr) do
        local has_count = token_count[v]
        if not has_count then
            has_count = 0
        end
        token_count[v] = has_count + 1
    end
    return token_count
end

function tf_dict( in_count )
    local tf_map = {}
    local sum = 0
    for k,v in pairs(in_count) do
        sum = sum + v
    end
    for k,v in pairs(in_count) do
        tf_map[k] = v / sum
    end
    return tf_map
end

function sum_count_dict( in_count, sum_count )
    sum_count = sum_count or {}
    for k,v in pairs(in_count) do
        local has_count = sum_count[k]
        if not has_count then
            has_count = 0
        end
        sum_count[k] = has_count + v
    end
    return sum_count
end

function make_vector( sum_count,cur_count )
    local tf_map = tf_dict(cur_count)
    local dest_vector = {}
    for k,_ in pairs(sum_count) do
        local idf_val = ssdb_idf:getValue(k)
        if idf_val then
            local tf_val = tf_map[k]
            if not tf_val then
                tf_val = 0 
            end
            local tfidf = tf_val * idf_val
            table_insert(dest_vector, tfidf)
        end
    end
    local norm = vector_norm(vector)
    if norm ~= 0 then
        for i,v in ipairs(dest_vector) do
            dest_vector[i] = v / norm
        end
    end
    return dest_vector
end

function vector_norm( vector )
    local sum = 0
    if vector then
        for _,v in ipairs(vector) do
            sum = sum + v*v
        end
    end
    return math.sqrt(sum)
end

function tfidf_cosine( link_count, content_count )
    sum_count = {}
    sum_count_dict(link_count, sum_count)
    sum_count_dict(content_count, sum_count)
    link_vector = make_vector(sum_count, link_count)
    content_vector = make_vector(sum_count, content_count)
    log(ERR,"link_vector:" .. cjson_safe.encode(link_vector))
    log(ERR,"content_vector:" .. cjson_safe.encode(content_vector))
    return cosine(link_vector, content_vector)
end
function cosine( link_vector, content_vector)
    local link_norm = vector_norm(link_vector)
    if link_norm == 0 then
        return 0
    end
    local content_norm = vector_norm(content_vector)
    if content_norm == 0 then
        return 0
    end
    local dot_val = 0
    for i,v in ipairs(link_vector) do
        dot_val = dot_val + v*content_vector[i]
    end
    local cos_val = dot_val / (link_norm * content_norm)
    return cos_val
end
while true do
     index = index + 1;
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
     -- local shits = cjson_safe.encode(data)
     -- log(ERR,"data:" .. shits .. ",err:" .. tostring(err))
     if data == nil or not data["_scroll_id"] or #data["hits"]["hits"] == 0 then
        local cost = (ngx.now() - begin)
         cost = tonumber(string.format("%.3f", cost))
        log(ERR, "done.match,index:"..index..",scan:"..scan_count..",total:" .. tostring(total) .. ",aCount:" .. tostring(aCount) .. ",cost:" .. cost)
        message.data = {cost = cost,index = index, scan = scan_count, total = total, aCount =  aCount}
        break
     else
         total = data.hits.total
         local hits = data.hits.hits
         -- local shits = cjson_safe.encode(hits)
         -- log(ERR,"hits:" .. shits)
         scan_count = scan_count + #hits
         ngx.update_time()
         local cost = (ngx.now() - start)
         cost = tonumber(string.format("%.3f", cost))
         log(ERR,"scrollId["..tostring(scrollId) .. "],total:" .. total ..",hits:" .. tostring(#hits) 
                .. ",scan:" .. tostring(scan_count)..",index:"..index..",cost:" .. cost)
         -- match_handler.build_similars(hits)
         for _,v in ipairs(hits) do
             local source = v._source
             local text_arr = {}
             local link_title = source.title
             if link_title then
                link_title = ngx.re.gsub(link_title, "(www\\.[a-z0-9\\.\\-]+)|([a-z0-9\\.\\-]+?\\.com)|([a-z0-9\\.\\-]+?\\.net)", "","ijou")
                link_title = ngx.re.gsub(link_title, "(电影天堂|久久影视|阳光影视|阳光电影|人人影视|外链影视|笨笨影视|390影视|转角影视|微博@影视李易疯|66影视|高清影视交流|大白影视|听风影视|BD影视分享|影视后花园|BD影视|新浪微博@笨笨高清影视|笨笨高清影视)", "","ijou")
                link_title = ngx.re.gsub(link_title, "(小调网|阳光电影|寻梦网)", "","ijou")
                link_title = ngx.re.gsub(link_title, "[\\[【][%W]*[】\\]]", "","ijou")
             end
             add2Arr(text_arr, link_title)
             if source.directors then
                add2Arr(text_arr, "导演")
                add2Arr(text_arr, source.directors) --todo
             end
             -- if source.actors then
             --    add2Arr(text_arr, "主演")
             --    add2Arr(text_arr, source.actors)
             -- end
             -- if source.genres then
             --    add2Arr(text_arr, "类型")
             --    add2Arr(text_arr, source.genres)
             -- end
             local match_data = {}
             match_data.id = v._id
             match_data.title = link_title
             match_data.episode = util_extract.find_episode(link_title)
             match_data.season = util_extract.find_season(link_title)
             local code = source.code
             if code and string.startsWith(code, 'imdbtt') then
                 code = ngx.re.sub(code, "imdbtt", "")
                 add2Arr(text_arr, "imdb" .. code)
                 match_data.imdb = code
             elseif code and string.startsWith(code, 'imdb') then
                 code = ngx.re.sub(code, "imdb", "")
                 add2Arr(text_arr, "imdb" .. code)
                 match_data.imdb = code
             end
       
             local splitor = " "
             local all_txt = table.concat( text_arr , splitor)
             local aresp,astatus = content_dao:analyze(all_txt,nil,nil,'ik_smart')
             local analyze_arr = {}
             if aresp and aresp.tokens then
                for _,tv in ipairs(aresp.tokens) do
                    add2Arr(analyze_arr, tv.token)
                end
             end
             local analyze_txt = table.concat( analyze_arr , splitor)
             if not analyze_txt or analyze_txt == '' then
                log(ERR, "empty analyze_txt:" .. v._id .. ",all_txt:" .. all_txt .. ",aresp:" .. cjson_safe.encode(aresp) .. ",astatus:" .. astatus)
             else
                match_data.analyze = analyze_txt
                local content_set = knnContents(link_title, analyze_txt)
                log(ERR,"title:"..match_data.title .. ",content_set:" .. cjson_safe.encode(content_set))
                local idf_cos_list = {}
                for _,vcontent in pairs(content_set) do
                     local idf_cos = cosine_match(match_data, vcontent)
                     log(ERR, "idf:".. idf_cos ..",id:" .. match_data.id .. "," .. vcontent.id .. ",title:" .. match_data.title .. "," .. match_data.analyze)
                     table_insert(idf_cos_list, { ["id"] = vcontent.id, ["score"] = idf_cos})
                end
             end
             aCount = aCount + 1
         end
         scrollId = data["_scroll_id"]
     end
end
if not scrollId then
    local params = {}
    params.scroll_id = scrollId
    sourceClient:clearScroll(params)
end
local body = cjson_safe.encode(message)
ngx.say(body)