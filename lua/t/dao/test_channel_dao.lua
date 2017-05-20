local channel_dao = require "dao.channel_dao"
local iresty_test    = require "resty.iresty_test"
local tb = iresty_test.new({unit_name="channel_dao"})
local cjson_safe = require("cjson.safe")

local test_id = "test_link_id"
-- local test_id = "b1332440830"
function tb:init()
    self:log("init complete")
end

-- function tb:test_0insert_docs()
--     local docs = {}
--     local doc = {
--       media = "movie",
--       source = "douban",
--       groupby = "recommend",
--       timeby = "201705",
--       channel = "热门",
--       id = "movie;douban;recommend;201705;热门",
--       url = "https://movie.douban.com/j/search_subjects?type=movie&tag=%E7%83%AD%E9%97%A8&sort=recommend&page_limit=20&page_start=0",
--       total = 20,
--       _doc_cmd = "index",
--        elements = {}
--     }
--     local elements = doc.elements;
--     elements[1] = {
--           code = "26593587",
--           title = "天才少女",
--           page = 1
--     }
--     docs[#docs + 1] = doc

--     local sresp, sstatus = channel_dao:save_docs(docs)
--     local str_sresp = cjson_safe.encode(sresp)
--     self:log("save_docs.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
-- end

function tb:test_1update_docs()
    local docs = {}
    local doc = {
      media = "movie",
      source = "douban",
      groupby = "recommend",
      timeby = "201705",
      channel = "热门",
      id = "movie;douban;recommend;201705;热门",
      url = "https://movie.douban.com/j/search_subjects?type=movie&tag=%E7%83%AD%E9%97%A8&sort=recommend&page_limit=20&page_start=0",
      total = 21,
      _doc_cmd = "update",
       elements = {}
    }
    local elements = doc.elements;
    elements[1] = {
          code = "899593587",
          title = "2天才少女",
          page = 2
    }
    docs[#docs + 1] = doc

    local sresp, sstatus = channel_dao:save_docs(docs)
    local str_sresp = cjson_safe.encode(sresp)
    self:log("save_docs.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
end

-- function tb:test_2save_docs()
--     local docs = {}
--     local doc = {
--       media = "movie",
--       source = "douban",
--       groupby = "recommend",
--       timeby = "201705",
--       channel = "热门",
--       id = "movie;douban;recommend;201705;热门",
--       url = "https://movie.douban.com/j/search_subjects?type=movie&tag=%E7%83%AD%E9%97%A8&sort=recommend&page_limit=20&page_start=0",
--       total = 21,
--       _doc_cmd = "update",
--        elements = {}
--     }
--     local elements = doc.elements;
--     elements[1] = {
--           code = "899593587",
--           title = "2update天才少女",
--           page = 2
--     }
--     docs[#docs + 1] = doc

--     local add_doc = {
--       media = "movie",
--       source = "douban",
--       groupby = "recommend",
--       timeby = "201705",
--       channel = "热门",
--       id = "movie;add;ammend;201705;热门",
--       url = "https://movie.douban.com/j/search_subjects?type=movie&tag=%E7%83%AD%E9%97%A8&sort=recommend&page_limit=20&page_start=0",
--       total = 1,
--       _doc_cmd = "index",
--        elements = {}
--     }
--     local elements = add_doc.elements;
--     elements[1] = {
--           code = "12393587",
--           title = "2add少女",
--           page = 1
--     }
--     docs[#docs + 1] = add_doc

--     local sresp, sstatus = channel_dao:save_docs(docs)
--     local str_sresp = cjson_safe.encode(sresp)
--     self:log("save_docs.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
-- end



tb:run()