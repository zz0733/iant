local link_dao = require "dao.link_dao"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="link_dao"})
local cjson_safe = require("cjson.safe")

local test_id = "test_link_id"
-- local test_id = "b1332440830"
function tb:init()
    self:log("init complete")
end

-- function tb:test_0search()
--     local body = {
--         query = {
--          match = {
--           _id = test_id
--         }
--       }
--     }
--     local sresp, sstatus = link_dao:search(body)
--     local str_sresp = cjson_safe.encode(sresp)
--     self:log("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
-- end

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

-- function tb:test_2create()
--   local docs = {}
--   local doc = {}
--   doc.id = test_id
--   -- doc._doc_cmd = "update"
--   doc.code = "code.create"
--   local paths = {}
--   paths[#paths + 1] = {name = "name.create123", length = 1024}
  
--   doc.link = "link"
--   local targets = {}
--   local target = {id = "12323",score = 0.23125}
--   targets[#targets + 1] = target
--   doc.targets = targets
--   docs[#docs + 1] = doc
--   local resp,status = link_dao:bulk_docs(docs)
--   local str_resp = cjson_safe.encode(resp)
--   self:log("create.str_resp:" .. tostring(str_resp) .. ",status:" .. tostring(status))
--   if not resp then
--   	error("error:" .. tostring(status))
--   else
--     local body = {
--         query = {
--          match = {
--           ["_id"] = "test_link_id"
--         }
--       }
--     }
--     local sresp, sstatus = link_dao:search(body)
--     local str_sresp = cjson_safe.encode(sresp)
--     self:log("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
--   end
-- end

-- function tb:test_3bulk_docs()
--   local docs = {}
--   local doc = {}
--   doc.id = test_id
--   doc._doc_cmd = "update"
--   doc.code = "code..updat@#23"
--   local paths = {}
--   paths[#paths + 1] = {name = "name12.update", length = 1024}
  
--   -- doc.link = "link"
--   local targets = {}
--   local target = {id = "12u23",score = 0.23125}
--   targets[#targets + 1] = target
--   doc.targets = targets
--   doc.ctime = ngx.time()
--   docs[#docs + 1] = doc
--   local resp,status = link_dao:bulk_docs(docs)
--   local str_resp = cjson_safe.encode(resp)
--   self:log("str_resp:" .. tostring(str_resp) .. ",status:" .. tostring(status))
--   if not resp then
--     error("error:" .. tostring(status))
--   end
-- end

function tb:test_4incr_bury()
  local id = "b506913785"
  local target_id = "256406810"
  local bury = 1
  local digg = 2
  local resp,status = link_dao:incr_bury_digg(id, target_id, bury, digg)
  local str_resp = cjson_safe.encode(resp)
  self:log("str_resp:" .. tostring(str_resp) .. ",status:" .. tostring(status))
  if not resp then
    error("error:" .. tostring(status))
  end
end

-- function tb:test_5bulk_docs()
--   local str_doc = '[{"link":"1nuAjYy9","source":"bdp-link-convert","id":"b1151853711","status":0,"_doc_cmd":"update"}]'
--   local docs = cjson_safe.decode(str_doc)
--   local resp,status = link_dao:bulk_docs(docs)
--   local str_resp = cjson_safe.encode(resp)
--   self:log("str_resp:" .. tostring(str_resp) .. ",status:" .. tostring(status))
--   if not resp then
--     error("error:" .. tostring(status))
--   end
-- end

-- function tb:test_5query_by_targetid_source()
--   local target_id = "026167904";
--   local source =  "bdp-.*"
--   local fields =  {"link"}
--   local resp,status = link_dao:query_by_targetid_source(target_id,source,0,100,fields)
--   local str_resp = cjson_safe.encode(resp)
--   self:log("str_resp:" .. tostring(str_resp) .. ",status:" .. tostring(status))
--   if not resp then
--     error("error:" .. tostring(status))
--   end
-- end

tb:run()