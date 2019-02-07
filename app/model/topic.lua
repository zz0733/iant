local utils = require("app.libs.utils")
local cjson_safe = require("cjson.safe")
local bit = require("bit")

local table_util = require("app.libs.util.table")
local topic_es = require("app.libs.es.topic")
local topic_ssdb = require("app.libs.ssdb.topic")
local status_ssdb = require("app.libs.ssdb.status")
local channel_ssdb = require("app.libs.ssdb.channel")

local status_model = require("app.model.status")

local parser_arr = {}
table.insert(parser_arr, "https://okjx.lrkdzx.com/?url=")
table.insert(parser_arr, "https://www.wocao.xyz/index.php?url=")
table.insert(parser_arr, "https://api.7kki.cn/api/?url=")
table.insert(parser_arr, "https://api.927.la/vip/?url=")

local select_parser = function(url)
    if not url or string.match(url, "%.mp4") or string.match(url, "%.m3u8") then
        return nil
    end
    local index = math.random(#parser_arr)
    local parser = parser_arr[index]
    return parser .. url
end

local wrap_topic = function(topic)
    if not topic then
        return
    end
    --    topic.url = 'https://yun.kubo-zy-youku.com/ppvod/AEEE9924D2E258BCBB7F9B6AA434D0E6.m3u8'

    topic.paser_url = select_parser(topic.url)
    topic.poster = "https://icdn.lezomao.com/img/154x100/f177ccc60abdc1ce.jpg"
    if topic.digests then
        topic.poster = topic.digests[1]
    end
    topic.avatar = "https://icdn.lezomao.com/img/154x100/f177ccc60abdc1ce.jpg"
    topic.user_name = "user_name"
    topic.is_good = 1
end

local add_topic_status = function(dest_arr, topic, status_dict, limit, dest_dict)
    if not topic or (#dest_arr >= limit) then
        return false
    end
    if dest_dict and dest_dict[topic.id] then
        return false
    end
    local status_obj = status_dict[topic.id]
    if status_obj then
        for sk, sv in pairs(status_obj) do
            topic[sk] = sv
        end
    end
    wrap_topic(topic)
    table.insert(dest_arr, topic)
    dest_dict[topic.id] = true
    if #dest_arr >= limit then
        return true
    end
end

local topic_model = {}


function topic_model:delete(user_id, topic_id)
    local res, err = db:query("delete from topic where id=? and user_id=?",
        { tonumber(topic_id), tonumber(user_id) })
    if res and not err then
        return true
    else
        return false
    end
end

function topic_model:new(title, content, user_id, user_name, category_id)
    local now = utils.now()
    return db:query("insert into topic(title, content, user_id, user_name, category_id, create_time) values(?,?,?,?,?,?)",
        { title, content, tonumber(user_id), user_name, tonumber(category_id), now })
end

function topic_model:save_if_absent(source)
    if not source then
        return nil, 400
    end
    local source_array = source
    if not table_util.is_array(source_array) then
        source_array = {}
        table.insert(source_array, source)
    end
    local id_arr = {}
    for _, v in pairs(source_array) do
        table.insert(id_arr, v.id)
    end
    local err_count = 0
    for _, v in pairs(source_array) do
        local bexists = topic_ssdb:exists(v.id)
        --        bexists = false
        --        ngx.log(ngx.ERR, "topic_ssdb:exists:" .. tostring(bexists) .. ",val:" .. cjson_safe.encode(v))
        if not bexists then
            local _, es_status = topic_es:save(v)
            local es_err = topic_es:statusErr(es_status)
            if es_err then
                err_count = err_count + 1
                ngx.log(ngx.ERR, "topic_es:save:" .. tostring(v.id) .. ",cause:" .. cjson_safe.encode(es_err))
            else
                local ssdb_bean = topic_ssdb:to_ssdb_bean(v)
                local _, ssdb_err = topic_ssdb:set(v.id, ssdb_bean)
                if ssdb_err then
                    err_count = err_count + 1
                    ngx.log(ngx.ERR, "topic_ssdb:set:" .. tostring(v.id) .. ",cause:" .. cjson_safe.encode(es_err))
                end
            end
        end
    end
    local msg = "success"
    if err_count > 0 then
        msg = "fail"
    else
        err_count = nil
    end
    return msg, err_count
end

function topic_model:get_my_topic(user_id, id)
    return db:query("select t.*, u.avatar as avatar, c.name as category_name from topic t " ..
            " left join user u on t.user_id=u.id " ..
            " left join category c on t.category_id=c.id " ..
            " where t.id=? and user_id=?", { tonumber(id), tonumber(user_id) })
end


function topic_model:get(id)
    local incr_dict = {}
    incr_dict.view = 1
    status_model:incr_num(id, incr_dict)
    local topic_dict, err = topic_ssdb:get(id)
    wrap_topic(topic_dict)
    return topic_dict, err
end

local random_get = function(topic_arr, topic_dict, limit, channel)
    if topic_arr and not table_util.is_array(topic_arr) then
        topic_arr = topic_arr.topics
    end
    if not topic_arr then
        return
    end
    math.randomseed(os.time())
    local hit_size = #topic_arr / 2
    for _, iv in ipairs(topic_arr) do
        if limit >= #topic_arr or (math.random(#topic_arr) < hit_size) then
            local has_topic = topic_dict[iv.id]
            if has_topic then
                has_topic.channel = has_topic.channel or 0
                has_topic.channel = has_topic.channel + bit.lshift(1, channel)
            else
                iv.channel = bit.lshift(1, channel)
                topic_dict[iv.id] = iv
            end
            limit = limit - 1
        end
        if limit < 1 then
            break
        end
    end
end

function topic_model:get_all(topic_type, category, page_no, page_size)
    page_no = tonumber(page_no)
    page_size = tonumber(page_size)
    local sortId = tonumber(category)
    if page_no < 1 then
        page_no = 1
    end
    local topic_dict = {}

    local from = (page_no - 1) * page_size
    local res, status
    local body
    if sortId ~= 0 then
        local must_arr = {}
        table.insert(must_arr, {
            match = { sortId = sortId }
        })
        body = {
            from = from,
            size = page_size,
            query = {
                bool = {
                    must = must_arr
                }
            }
        }
    else
        local newest_ssdb = channel_ssdb:get("newest")
        random_get(newest_ssdb, topic_dict, 5, 1)

        local must_arr = {}
        table.insert(must_arr, {
            exists = { field = "issueds" }
        })
        --        table.insert(must_arr, {
        --            match = { albumId = "1462395459" }
        --        })
        --        table.insert(must_arr, {
        --            match = { _id = "17903652696774212526" }
        --        })
        body = {
            from = from,
            size = page_size,
            query = {
                bool = {
                    must = must_arr
                }
            }
        }
    end
    res, status = topic_es:search(body)
    local err = topic_es:statusErr(status)
    local id_arr = topic_es:response_to_ids(res)
    local query_arr = {}
    for index, ival in ipairs(id_arr) do
        local topic = {}
        topic.id = ival
        topic.score = index
        table.insert(query_arr, topic)
    end

    random_get(query_arr, topic_dict, #query_arr, 2)
    local topic_arr = {}
    for _, channel in pairs(topic_dict) do
        table.insert(topic_arr, channel)
    end
    table.sort(topic_arr, function(a, b)
        if a.score ~= b.score then
            return b.score > a.score
        end
        return a.channel > b.channel
    end)
    local id_arr = {}

    for index = 1, math.min(page_size, #topic_arr), 1 do
        table.insert(id_arr, topic_arr[index].id)
    end

    local topic_ssdb_dict = topic_ssdb:multi_get(id_arr)
    local status_ssdb_dict = status_ssdb:multi_get(id_arr)
    local topic_dest_arr = {}
    if topic_ssdb_dict then
        for tk, v in pairs(topic_ssdb_dict) do
            local status_obj = status_ssdb_dict[tk]
            if status_obj then
                for sk, sv in pairs(status_obj) do
                    v[sk] = sv
                end
            end
            wrap_topic(v)
            table.insert(topic_dest_arr, v)
        end
    end
    return topic_dest_arr, err
end

function topic_model:get_relateds(title, albumId, epindex, page_size)
    page_size = tonumber(page_size)
    epindex = tonumber(epindex)

    local must_arr = {}
    if albumId then
        table.insert(must_arr, { match = { albumId = albumId } })
    end
    if epindex then
        local min_index = epindex - 1
        table.insert(must_arr, { range = { epindex = { gte = min_index } } })
    end
    if #must_arr < 1 then
        table.insert(must_arr, { match = { title = title } })
    end
    local body = {
        size = 0,
        query = {
            bool = {
                must = must_arr
            }
        },
        aggs = {
            min_epindex = {
                top_hits = {
                    size = "3",
                    sort = { { epindex = { order = "asc" } } }
                }
            },
            max_epindex = {
                top_hits = {
                    size = page_size,
                    sort = { { epindex = { order = "desc" } } }
                }
            }
        }
    }
    res, status = topic_es:search(body)

    local es_err = topic_es:statusErr(status)
    local min_id_arr = topic_es:response_to_ids(res)
    local id_arr = {}
    local id_dict = {}
    local min_id_arr = {}
    local max_id_arr = {}
    if res and res.aggregations then
        min_id_arr = topic_es:response_to_ids(res.aggregations.min_epindex)
        max_id_arr = topic_es:response_to_ids(res.aggregations.max_epindex)
        for _, min_id in ipairs(min_id_arr) do
            if not id_dict[min_id] then
                table.insert(id_arr, min_id)
                id_dict[min_id] = true
            end
        end
        for _, max_id in ipairs(max_id_arr) do
            if not id_dict[max_id] then
                table.insert(id_arr, max_id)
                id_dict[max_id] = true
            end
        end
    end

    local topic_ssdb_dict = topic_ssdb:multi_get(id_arr)
    local status_ssdb_dict = status_ssdb:multi_get(id_arr)
    local topic_dest_arr = {}
    if topic_ssdb_dict then
        local album_arr = {}
        local remain_arr = {}
        local dest_dict = {}
        for _, min_id in ipairs(min_id_arr) do
            local min_topic = topic_ssdb_dict[min_id]
            if epindex and min_topic and min_topic.epindex == epindex then
                min_topic = nil
            end
            add_topic_status(topic_dest_arr, min_topic, topic_ssdb_dict, page_size, dest_dict)
        end

        for _, max_id in ipairs(max_id_arr) do
            local max_topic = topic_ssdb_dict[max_id]
            add_topic_status(topic_dest_arr, max_topic, topic_ssdb_dict, page_size, dest_dict)
        end
    end
    table.sort(topic_dest_arr, function(a, b)
        if not a.epindex then
            return false
        end
        if not b.epindex then
            return true
        end
        return a.epindex > b.epindex
    end)
    return topic_dest_arr, es_err
end


function topic_model:get_total_count(topic_type, category)
    local res, status
    local sortId = tonumber(category)

    if sortId ~= 0 then
        local must_arr = {}
        table.insert(must_arr, {
            match = { sortId = sortId }
        })
        local body = {
            query = {
                bool = {
                    must = must_arr
                }
            }
        }

        res, status = topic_es:count(body)
        --        if not topic_type or topic_type == "default" then
        --            res, err = db:query("select count(id) as c from topic where category_id=?", { category })
        --        elseif topic_type == "recent-reply" then
        --            res, err = db:query("select count(id) as c from topic where category_id=?", { category })
        --        elseif topic_type == "good" then
        --            res, err = db:query("select count(id) as c from topic where is_good=1 and category_id=?", { category })
        --        elseif topic_type == "noreply" then
        --            res, err = db:query("select count(id) as c from topic where reply_num=0 and category_id=?", { category })
        --        end
    else
        local must_arr = {}
        table.insert(must_arr, {
            exists = { field = "sortId" }
        })
        local body = {
            query = {
                bool = {
                    must = must_arr
                }
            }
        }

        res, status = topic_es:count(body)
        --        if not topic_type or topic_type == "default" then
        --            res, err = db:query("select count(id) as c from topic")
        --        elseif topic_type == "recent-reply" then
        --            res, err = db:query("select count(id) as c from topic")
        --        elseif topic_type == "good" then
        --            res, err = db:query("select count(id) as c from topic where is_good=1")
        --        elseif topic_type == "noreply" then
        --            res, err = db:query("select count(id) as c from topic where reply_num=0")
        --        end
    end
    local err = topic_es:statusErr(status)
    if err or not res or not res.count then
        return 0
    else
        return res.count
    end
end

function topic_model:get_all_count()
    local body = {
        query = {
            match_all = {}
        }
    }

    local res, err = topic_es:count(body)
    if err or not res or not res.count then
        return 0
    else
        return res.count
    end
end

function topic_model:get_all_of_user(user_id, page_no, page_size)
    page_no = tonumber(page_no)
    page_size = tonumber(page_size)
    if page_no < 1 then
        page_no = 1
    end
    local res, err = db:query("select t.*, u.avatar as avatar, c.name as category_name  from topic t " ..
            " left join user u on t.user_id=u.id " ..
            " left join category c on t.category_id=c.id " ..
            " where t.user_id=? order by t.id desc limit ?,?",
        { tonumber(user_id), (page_no - 1) * page_size, page_size })

    if not res or err or type(res) ~= "table" or #res <= 0 then
        return {}
    else
        return res
    end
end

function topic_model:get_total_count_of_user(user_id)
    local res, err = db:query("select count(id) as c from topic where user_id=?", { tonumber(user_id) })
    if err or not res or #res ~= 1 or not res[1].c then
        return 0
    else
        return res[1].c
    end
end



function topic_model:get_all_hot_of_user(user_id, page_no, page_size)
    page_no = tonumber(page_no)
    page_size = tonumber(page_size)
    if page_no < 1 then
        page_no = 1
    end
    local res, err = db:query("select t.*, u.avatar as avatar, c.name as category_name  from topic t " ..
            " left join user u on t.user_id=u.id " ..
            " left join category c on t.category_id=c.id " ..
            " where t.user_id=? order by t.reply_num desc, like_num desc limit ?,?",
        { tonumber(user_id), (page_no - 1) * page_size, page_size })

    if not res or err or type(res) ~= "table" or #res <= 0 then
        return {}
    else
        return res
    end
end

function topic_model:get_total_hot_count_of_user(user_id)
    local res, err = db:query("select count(id) as c from topic where user_id=?", { tonumber(user_id) })
    if err or not res or #res ~= 1 or not res[1].c then
        return 0
    else
        return res[1].c
    end
end


function topic_model:get_all_like_of_user(user_id, page_no, page_size)
    page_no = tonumber(page_no)
    page_size = tonumber(page_size)
    if page_no < 1 then
        page_no = 1
    end
    local res, err = db:query("select t.*, u.avatar as avatar, c.name as category_name  from `like` l " ..
            " right join topic t on t.id=l.topic_id " ..
            " left join user u on t.user_id=u.id " ..
            " left join category c on t.category_id=c.id " ..
            " where l.user_id=? order by l.id desc limit ?,?",
        { tonumber(user_id), (page_no - 1) * page_size, page_size })

    if not res or err or type(res) ~= "table" or #res <= 0 then
        return {}
    else
        return res
    end
end

function topic_model:get_total_like_count_of_user(user_id)
    local res, err = db:query("select count(l.id) as c from `like` l " ..
            " right join topic t on l.topic_id=t.id " ..
            " where l.user_id=?", { tonumber(user_id) })
    if err or not res or #res ~= 1 or not res[1].c then
        return 0
    else
        return res[1].c
    end
end


function topic_model:reset_last_reply(topic_id, user_id, user_name, last_reply_time) -- 更新最后回复人
    db:query("update topic set last_reply_id=?, last_reply_name=?, last_reply_time=? where id=?",
        { tonumber(user_id), user_name, last_reply_time, tonumber(topic_id) })
end

return topic_model