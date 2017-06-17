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
      id = "movie;douban;recommend;201705;热门1",
      url = "https://movie.douban.com/j/search_subjects?type=movie&tag=%E7%83%AD%E9%97%A8&sort=recommend&page_limit=20&page_start=0",
      total = 21,
      _doc_cmd = "update",
       elements = {}
    }
    local elements = doc.elements;
    elements[1] = {
          code = "899593587",
          title = "2天才少女"
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

function tb:test_3query_lastest_by_channel()
    local media = "movie"
    -- local media = "tv"
    local channel = "热门"
    local sresp, sstatus = channel_dao:query_lastest_by_channel(media, channel)
    local str_sresp = cjson_safe.encode(sresp)
    self:log("save_docs.str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
end

function tb:test_4save_by_json()
    local str_json = '[{"_doc_cmd":"update","channel":"newest","timeby":"2017061719","id":"all;all;issued;2017061719;newest","elements":[{"code":"82804538","title":"《高能少年团》2017.同步TV"},{"code":"712559336","title":"《高能少年团》2017.同步TV"},{"code":"86529374","title":"逆转重生》2017.同步连载 【完结待删】"},{"code":"54084243","title":"奔跑吧5》2017"},{"code":"86589015","title":"奇怪的搭档.2017.连载至EP24"},{"code":"01040442477","title":"加菲猫的幸福生活_[104集全]_[国语高清]_640x360_www.ihd4.com_iHD4视频网"}],"source":"all","groupby":"issued","media":"all"}]'
    -- local media = "tv"
    local docs = cjson_safe.decode(str_json)
    local sresp, sstatus = channel_dao:save_docs(docs)
    local str_sresp = cjson_safe.encode(sresp)
    self:log("save_docs.data:"..str_json..",str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
end

tb:run()