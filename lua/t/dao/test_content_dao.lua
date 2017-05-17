local content_dao = require "dao.content_dao"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="content_dao"})
local cjson_safe = require("cjson.safe")

local test_id = "test_link_id"
-- local test_id = "b1332440830"
function tb:init()
    self:log("init complete")
end

function tb:test_0query_by_ctime()
    local from = 0
    local size = 2
    local from_date = 0
    local to_date = ngx.time()
    local fields = {"ctime","names"}
    local sresp, sstatus = content_dao:query_by_ctime(from, size, from_date, to_date,fields)
    local str_sresp = cjson_safe.encode(sresp)
    self:log("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
end

function tb:test_1update_docs()
    local from = 0
    local size = 1
    local from_date = 0
    local to_date = ngx.time()
    local fields = {"ctime","names"}
    local resp, status = content_dao:query_by_ctime(from, size, from_date, to_date,fields)
    local str_sresp = cjson_safe.encode(resp)
    self:log("query_by_ctime.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(status))
    local hits = resp.hits.hits
    local has_doc = hits[1]
    local update_docs = {}
    local new_doc = {}
    update_docs[#update_docs + 1] = new_doc
    new_doc.id = has_doc["_id"]
    new_doc.article = {}
    new_doc.article.title = "udpate"
    new_doc.lcount = 100
    local str_docs = cjson_safe.encode(update_docs)
    local sresp, sstatus = content_dao:update_docs(update_docs)
    local str_sresp = cjson_safe.encode(sresp)
    self:log("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus)..",str_docs:" .. str_docs)
    local ids = {}
    ids[#ids + 1] = has_doc._id
    local qresp, qstatus = content_dao:query_by_ids(ids)
    local str_sresp = cjson_safe.encode(qresp)
    self:log("query_by_ids.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(qstatus))
end

-- function tb:test1_delete()
--   local ids = {}
--   ids[#ids + 1] = test_id
--   local resp,status = link_dao:delete_by_ids(ids)
--   local str_resp = cjson_safe.encode(resp)
--   self:log("str_resp:" .. tostring(str_resp) .. ",status:" .. tostring(status))
--   if not resp then
--     error("error:" .. tostring(status))
--   end
-- end


tb:run()