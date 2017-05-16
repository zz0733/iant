local link_dao = require "dao.link_dao"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="link_dao"})
local cjson_safe = require("cjson.safe")

local test_id = "test_link_id"
-- local test_id = "b1332440830"
function tb:init()
    self:log("init complete")
end

function tb:test_0search()
    local body = {
        query = {
         match = {
          _id = test_id
        }
      }
    }
    local sresp, sstatus = link_dao:search(body)
    local str_sresp = cjson_safe.decode(sresp)
    self:log("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
end

-- function tb:test1_delete()
--   local ids = {}
--   ids[#ids + 1] = test_id
--   local resp,status = link_dao:delete_by_ids(ids)
--   local str_resp = cjson_safe.decode(resp)
--   self:log("str_resp:" .. tostring(str_resp) .. ",status:" .. tostring(status))
--   if not resp then
--     error("error:" .. tostring(status))
--   end
-- end

function tb:test_2create()
  local docs = {}
  local doc = {}
  doc.id = test_id
  -- doc._doc_cmd = "update"
  doc.code = "code.create"
  local paths = {}
  paths[#paths + 1] = {name = "name.create123", length = 1024}
  
  doc.link = "link"
  local targets = {}
  local target = {id = "12323",score = 0.23125}
  targets[#targets + 1] = target
  doc.targets = targets
  docs[#docs + 1] = doc
  local resp,status = link_dao:bulk_docs(docs)
  local str_resp = cjson_safe.decode(resp)
  self:log("create.str_resp:" .. tostring(str_resp) .. ",status:" .. tostring(status))
  if not resp then
  	error("error:" .. tostring(status))
  else
    local body = {
        query = {
         match = {
          ["_id"] = "test_link_id"
        }
      }
    }
    local sresp, sstatus = link_dao:search(body)
    local str_sresp = cjson_safe.decode(sresp)
    self:log("search.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
  end
end

-- function tb:test3_bulk_docs()
--   local docs = {}
--   local doc = {}
--   doc.id = test_id
--   doc._doc_cmd = "update"
--   doc.code = "code..updat@#23"
--   local paths = {}
--   paths[#paths + 1] = {name = "name123xxx", length = 1024}
  
--   -- doc.link = "link"
--   local targets = {}
--   local target = {id = "12323",score = 0.23125}
--   targets[#targets + 1] = target
--   doc.targets = targets
--   docs[#docs + 1] = doc
--   local resp,status = link_dao.bulk_docs(docs)
--   local str_resp = cjson_safe.decode(resp)
--   self:log("str_resp:" .. tostring(str_resp) .. ",status:" .. tostring(status))
--   if not resp then
--     error("error:" .. tostring(status))
--   end
-- end

tb:run()