if not (0 == ngx.worker.id()) then
    return { do_loop = function() end }
end

local cjson_safe = require("cjson.safe")
local worker_timer = require("app.timer.worker")
local topic_es = require("app.libs.es.topic")
local channel_ssdb = require("app.libs.ssdb.channel")



local log = ngx.log
local ERR = ngx.ERR

local _M = worker_timer:new({
    name = "build_channel",
    loop = true,
    delay = 1800, -- in seconds
})
_M._VERSION = '0.01'


function _M:run()
    local page_size = 50
    local sort_arr = {}
    local must_arr = {}
    table.insert(sort_arr, { ctime = { order = "desc" } })
    table.insert(sort_arr, { year = "desc" })
    table.insert(must_arr, { match = { mediaId = 2}})
    local body = {
        size = page_size,
        sort = sort_arr,
        query = {
            bool = {
                must = must_arr
            }
        }
    }
    local resp, status = topic_es:search(body)
    local status_err = topic_es:statusErr(status)
    if status_err then
        log(ERR, "build_newest, status:" .. tostring(status_err))
    else
        local topic_arr = {}
        if resp and resp.hits and resp.hits.hits then
            for _, v in ipairs(resp.hits.hits) do
                local topic = {}
                topic.id = v._id
                topic.score = #topic_arr + 1
                table.insert(topic_arr, topic)
            end
        end
        local channel = {}
        channel.topics = topic_arr
        log(ERR, "build_newest:" .. tostring(#topic_arr) .. ",val:" .. cjson_safe.encode(channel))
        if #topic_arr > 0 then
            channel_ssdb:set("newest", channel)
        end
    end
end

return _M