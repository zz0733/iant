local user_es = require("app.libs.es.user")
local user_ssdb = require("app.libs.ssdb.user")

local user_model = {}
user_model._VERSION = '0.01'


function user_model:new_user(id, username, password, avatar, nickname, role)
    local has_user = user_ssdb:get(id)
    if has_user then
        return has_user
    end
    local user = {
        id = id,
        name = username,
        pwd = password,
        avatar = avatar,
        nickname = nickname,
        role = tonumber(role),
        ctime = ngx.time(),
        utime = ngx.time()
    }
    local docs = {}
    table.insert(docs, user_es:to_index(user))
    local res, status = user_es:index_docs(docs)
    local error = user_es:statusErr(status)
    local indexDoc
    if not error and res and res.items then
        indexDoc = res.items[1].index
        error = user_es:statusErr(indexDoc.status, 201)
    end
    user_ssdb:set(id, user)
    return indexDoc, user_es:statusErr(status)
end

function user_model:query_ids(ids)
    local body = {
        from = 0,
        size = #ids,
        query = {
            terms = {
                _id = ids
            }
        }
    }
    local resp, status = user_es:search(body)
    return resp, status
end

function user_model:query(username, password)
    local body = {
        from = 0,
        size = 2,
        query = {
            bool = {
                must = {
                    { match = { name = username } }
                }
            }
        }
    }
    local res, status = user_es:search(body)
    if res and res.hits then
        local err = user_es:statusErr(status)
        if res.hits.total > 1 then
            err = "countErr:" .. tostring(res.hits.total)
        end
        if not err then
            local id_arr = user_es:response_to_ids(res)
            if id_arr and #id_arr > 0 then
                local user_ssdb = user_ssdb:get(id_arr[1])
                if user_ssdb and user_ssdb.pwd ~= password then
                    user_ssdb = nil
                end
                return user_ssdb
            end
            return nil
        else
            return nil, err
        end
    end
    return nil, user_es:statusErr(status)
end

function user_model:query_by_id(id)
    local body = {
        from = 0,
        size = 2,
        query = {
            match = {
                _id = id
            }
        }
    }
    local res, status = user_es:search(body)
    if res and res.hits then
        local err = user_es:statusErr(status)
        if res.hits.total > 1 then
            err = "countErr:" .. tostring(res.hits.total)
        end
        return res.hits.hits[1], err
    end
    return nil, user_es:statusErr(status)
end

-- return user, err
function user_model:query_by_username(username)
    local body = {
        from = 0,
        size = 1,
        query = {
            match = {
                name = username
            }
        }
    }
    local res, status = user_es:search(body)
    if res and res.hits then
        local err = user_es:statusErr(status)
        if res.hits.total > 1 then
            err = "countErr:" .. tostring(res.hits.total)
        end
        return res.hits.hits[1], err
    end
    return nil, user_es:statusErr(status)
end

function user_model:update_avatar(userid, avatar)
    db:query("update user set avatar=? where id=?", { avatar, userid })
end

function user_model:update_pwd(userid, pwd)
    local res, err = db:query("update user set password=? where id=?", { pwd, userid })
    if not res or err then
        return false
    else
        return true
    end
end

function user_model:update(userid, email, email_public, city, company, github, website, sign)
    local res, err = db:query("update user set email=?, email_public=?, city=?, company=?, github=?, website=?, sign=? where id=?",
        { email, email_public, city, company, github, website, sign, userid })

    if not res or err then
        return false
    else
        return true
    end
end

function user_model:get_total_count()
    local res, err = db:query("select count(id) as c from user")

    if err or not res or #res ~= 1 or not res[1].c then
        return 0
    else
        return res[1].c
    end
end


return user_model
