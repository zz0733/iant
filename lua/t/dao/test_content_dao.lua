local content_dao = require "dao.content_dao"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="content_dao"})
local cjson_safe = require("cjson.safe")

local test_id = "test_link_id"
-- local test_id = "b1332440830"
function tb:init()
    self:log("init complete")
end

-- function tb:test_0query_by_ctime()
--     local from = 0
--     local size = 2
--     local from_date = 0
--     local to_date = ngx.time()
--     local fields = {"ctime","names"}
--     local sresp, sstatus = content_dao:query_by_ctime(from, size, from_date, to_date,fields)
--     local str_sresp = cjson_safe.encode(sresp)
--     self:log("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
-- end

-- function tb:test_1update_docs()
--     local from = 0
--     local size = 1
--     local from_date = 0
--     local to_date = ngx.time()
--     local fields = {"ctime","names"}
--     local resp, status = content_dao:query_by_ctime(from, size, from_date, to_date,fields)
--     local str_sresp = cjson_safe.encode(resp)
--     self:log("query_by_ctime.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(status))
--     local hits = resp.hits.hits
--     local has_doc = hits[1]
--     local update_docs = {}
--     local new_doc = {}
--     update_docs[#update_docs + 1] = new_doc
--     new_doc.id = has_doc["_id"]
--     new_doc.article = {}
--     new_doc.article.title = "udpate"
--     new_doc.lcount = 100
--     local str_docs = cjson_safe.encode(update_docs)
--     local sresp, sstatus = content_dao:update_docs(update_docs)
--     local str_sresp = cjson_safe.encode(sresp)
--     self:log("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus)..",str_docs:" .. str_docs)
--     local ids = {}
--     ids[#ids + 1] = has_doc._id
--     local qresp, qstatus = content_dao:query_by_ids(ids)
--     local str_sresp = cjson_safe.encode(qresp)
--     self:log("query_by_ids.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(qstatus))
-- end

-- function tb:test_2count()
--   local body = {
--      query = {
--         match_all = {}
--      }
--   }
--   local resp,status = content_dao:count(body)
--   local str_resp = cjson_safe.encode(resp)
--   self:log("count:str_resp:" .. tostring(str_resp) .. ",status:" .. tostring(status))
--   if not resp then
--     error("error:" .. tostring(status))
--   end
-- end

-- function tb:test_3analyze()
--   local field = "issueds.region"
--   local body = {"中国","越南","中国大陆","a, 中国"}
--   -- local analyzer = "ik_smart_synmgroup"
--   local resp,status = content_dao:analyze(body, field, analyzer)
--   local str_resp = cjson_safe.encode(resp)
--   self:log("count:str_resp:" .. tostring(str_resp) .. ",status:" .. tostring(status))
--   if not resp then
--     error("error:" .. tostring(status))
--   end
--   local region = ""
--   if not region or region =="" then
--     self:log("REGION")
--   end
-- end


-- function tb:test_4save_docs()
--     local update_docs = {}
--     local new_doc = {}
--     update_docs[#update_docs + 1] = new_doc
--     new_doc.id = "12345233459"
--     new_doc.id = ngx.time() + 1
--     new_doc.issueds = {}
--     local issueds = new_doc.issueds
--     issueds[#issueds + 1] = {region = "越南3",country = "vietnam"}
--     issueds[#issueds + 1] = {region = "香港3",country = "中国大陆"}
--     new_doc.article = {}
--     new_doc.article.title = "save_docs"
--     new_doc.lcount = 1002

--     local ids = {}
--     ids[#ids + 1] = new_doc.id

--     local str_docs = cjson_safe.encode(update_docs)
--     local sresp, sstatus = content_dao:index_docs(update_docs)
--     local str_sresp = cjson_safe.encode(sresp)
--     self:log("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus)..",str_docs:" .. str_docs)
   
--     local str_ids = cjson_safe.encode(ids)
--     local qresp, qstatus = content_dao:query_by_ids(ids)
--     local str_sresp = cjson_safe.encode(qresp)
--     self:log("query_by_ids.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(qstatus) .. ",str_ids:" .. tostring(str_ids))
-- end

-- function tb:test_5scroll()
--     local scroll_id = 0
--     local scroll = "1m"
--     -- local body = { query = { ["match_all"]= {}}}

--     local sresp, sstatus = content_dao:scroll(scroll_id, scroll, body)
--     local str_sresp = cjson_safe.encode(sresp)
--     self:log("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
   
-- end
function tb:test_6query_by_codes()
    local codes = { "26984183","26590060"}
    local sresp, sstatus = content_dao:query_by_codes(codes)
    local str_sresp = cjson_safe.encode(sresp)
    self:log("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus) )
    self:log("search.str_resp:" .. math.random(1, 10))
   
end

tb:run()