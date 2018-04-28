local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")
local content_dao = require "dao.content_dao"
local link_dao = require "dao.link_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local message = {}
message.code = 200

local from_date = tonumber(args.from) or (ngx.time() - 5*60*60)

local timeby = from_date

 -- # -1:失效,0:默认,1:有效,2:自动匹配,3:人工匹配
local must_array = {}
table.insert(must_array,{range = { utime = { gte = from_date } }})
local cur_partition = 0
local max_partition = 100
local body = {
    size = 0,
    query = {
        bool = {
            must = must_array
        }
    },
    aggs = {
       ["content_group"] = {
           terms = {
               field = "target",
               include = {
                   partition = cur_partition,
                   num_partitions = max_partition
               },
               size = 2000
           }
       }
    }
}

local musts = {}
table.insert(musts,{range = { status = { gte = 2 } }})
table.insert(musts,{match = { target = "" }})
local max_episode_body = {
    size = 9000,
    query = {
        bool = {
            must = musts
        }
    }
}

local page = 0;
local save = 0
local total = 0
local begin = ngx.now()
while true do
    page = page + 1
    local resp, stauts = link_dao:search(body)

    if resp and resp.aggregations  then
        local buckets = resp.aggregations["content_group"].buckets
        for _,v in ipairs(buckets) do
            total = total + 1
            local content_id  = v.key
            musts[2].match.target = content_id
            local mresp = link_dao:search(max_episode_body)
            -- log(ERR,"v:" .. cjson_safe.encode(v) .. ",body:" .. cjson_safe.encode(max_episode_body) .. ",resp:" .. cjson_safe.encode(mresp))
            if mresp and  mresp.hits and mresp.hits.total > 0  then
                local hits = mresp.hits
                local max_episode_id = nil
                local max_episode_num = nil
                local max_episode_ctime = nil
                for _,v in ipairs(hits.hits) do
                    local _source = v._source
                    -- _source.episode可能为NULL值
                    local episode = tonumber(_source.episode)
                    if episode and episode > 0  then
                        if (not max_episode_num) or (episode > max_episode_num) then
                            max_episode_num = episode
                            max_episode_id = v._id
                            max_episode_ctime = _source.ctime
                        end
                    end
                end
                if max_episode_num and max_episode_num > 0 then
                    local lpipe = {}
                    lpipe.lid = max_episode_id
                    lpipe.index = 0
                    lpipe.time = max_episode_ctime
                    lpipe.epmax = max_episode_num
                    local lcount = mresp.hits.total
                    local content_doc = {}
                    content_doc.id = content_id
                    content_doc.lpipe = lpipe
                    content_doc.lcount = lcount
                    local content_docs = {}
                    table.insert(content_docs, content_doc)
                    content_dao:update_docs(content_docs)
                    save = save + 1
                    log(ERR,"saveDoc:" .. content_id .. ",page:" .. page .. ",save:"..save..",total:"..total..",lpipe:" .. cjson_safe.encode(content_doc))

                end
            end
        end
    end
    cur_partition = cur_partition + 1
    if cur_partition == max_partition then
        break
    end
    body.aggs["content_group"].terms.include.partition = cur_partition
end

local cost = (ngx.now() - begin)
cost = tonumber(string.format("%.3f", cost))
message.data = {cost = cost,page = page, total = total,save = save }
log(ERR,"statisticEnd,data:" .. cjson_safe.encode(message.data))
local body = cjson_safe.encode(message)
ngx.say(body)