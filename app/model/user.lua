local es_client = require("app.libs.es.client")
local user_model = es_client:new({ index = "user", type = "table" })
user_model._VERSION = '0.01'


function user_model:new_user(id, username, password, avatar)
    local user = {
        id = id,
        name = username,
        pwd = password,
        avatar = avatar
    }
    local docs = {}
    table.insert(docs, user)
    local res, status = self:index_docs(docs)
    string.error("resp:", res, ",status:", status)
    if res and res.items then
        local indexDoc = res.items[1].index
        local err = self:statusErr(indexDoc.status, 201)
        return indexDoc, err
    end
    return nil, self:statusErr(status)
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
    local resp, status = self:search(body)
    return resp, status
end

function user_model:query(username, password)
    local body = {
        from = 0,
        size = 2,
        query = {
            bool = {
                must = {
                    { match = { name = username } },
                    { match = { pwd = password } }
                }
            }
        }
    }
    local res, status = self:search(body)
    if res and res.hits then
        local err = self:statusErr(status)
        if res.hits.total > 1 then
            err = "countErr:" .. tostring(res.hits.total)
        end
        return res.hits.hits[1], err
    end
    return nil, self:statusErr(status)
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
    local res, status = self:search(body)
    if res and res.hits then
        local err = self:statusErr(status)
        if res.hits.total > 1 then
            err = "countErr:" .. tostring(res.hits.total)
        end
        return res.hits.hits[1], err
    end
    return nil, self:statusErr(status)
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
    local res, status = self:search(body)
    if res and res.hits then
        local err = self:statusErr(status)
        if res.hits.total > 1 then
            err = "countErr:" .. tostring(res.hits.total)
        end
        return res.hits.hits[1], err
    end
    return nil, self:statusErr(status)
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
