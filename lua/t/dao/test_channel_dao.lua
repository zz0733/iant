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
    local str_json = '[{"media":"movie","source":"douban","groupby":"time","timeby":"20170616","channel":"正在热播","id":"movie;douban;time;20170616;正在热播","elements":[{"title":"异形：契约","code":11803087,"vote":62667,"score":7.4,"star":40,"ticket_rate_tf":41.7},{"title":"雄狮","code":26220650,"vote":14922,"score":7.2,"star":40},{"title":"缉枪","code":26801782,"vote":73,"star":0},{"title":"原谅他77次","code":26857793,"vote":243,"score":6.4,"star":35},{"title":"我不做大哥好多年","code":26429879,"vote":795,"score":5.2,"star":30},{"title":"新木乃伊","code":20451290,"vote":42999,"score":4.8,"star":25,"ticket_rate_tf":10},{"title":"神奇女侠","code":1578714,"vote":135515,"score":7.3,"star":40,"ticket_rate_tf":15.1},{"title":"加勒比海盗5：死无对证","code":6311303,"vote":127754,"score":7.4,"star":40,"ticket_rate_tf":6.4},{"title":"冈仁波齐","code":26606242,"vote":2892,"score":7.6,"star":40},{"title":"摔跤吧！爸爸","code":26387939,"vote":308557,"score":9.2,"star":45,"ticket_rate_tf":12.4},{"title":"重返·狼群","code":26920269,"vote":3086,"score":7.9,"star":40,"ticket_rate_tf":1.1},{"title":"忠爱无言","code":26995137,"vote":5363,"score":7.4,"star":40,"ticket_rate_tf":3.6},{"title":"哆啦A梦：大雄的南极冰冰凉大冒险","code":26839466,"vote":9003,"score":6.6,"star":35,"ticket_rate_tf":1},{"title":"中国推销员","code":26266924,"vote":1017,"score":4.2,"star":20,"ticket_rate_tf":5.4},{"title":"借眼","code":26751902,"vote":530,"star":0},{"title":"我是医生","code":26738642,"vote":40,"star":0},{"title":"三只小猪2","code":27021323,"vote":361,"score":3.8,"star":20},{"title":"六人晚餐","code":26412618,"vote":901,"score":5.5,"star":30},{"title":"女人永远是对的","code":26959527,"vote":167,"star":0},{"title":"52赫兹，我爱你","code":26780534,"vote":736,"score":6.4,"star":35},{"title":"我的爸爸是国王","code":27030855,"vote":215,"star":0},{"title":"猪太狼的夏天","code":26877504,"vote":17,"star":0},{"title":"内心引力","code":26776397,"vote":977,"score":7.6,"star":40,"ticket_rate_tf":0.8},{"title":"碟仙之毕业照","code":26843838,"vote":401,"score":2.2,"star":10},{"title":"我们停战吧","code":26354028,"vote":107,"score":5.1,"star":25},{"title":"十七岁的雨季","code":26831709,"vote":155,"star":0},{"title":"荡寇风云","code":26385746,"vote":4380,"score":6.3,"star":35},{"title":"李雷和韩梅梅","code":26289138,"vote":10234,"score":3,"star":15},{"title":"黑白照相馆","code":27003544,"vote":185,"star":0},{"title":"我的青春你来过","code":27059938,"vote":12,"star":0},{"title":"明月几时有","code":26425072,"vote":371,"star":0},{"title":"异兽来袭","code":27034867,"vote":139,"star":0},{"title":"绝世高手","code":26754831,"vote":184,"score":6.9,"star":35}],"total":33,"_doc_cmd":"index"},{"media":"movie","source":"douban","groupby":"time","timeby":"20170616","channel":"即将上映","id":"movie;douban;time;20170616;即将上映","elements":[{"title":"变形金刚5：最后的骑士","code":25824686},{"title":"青春逗","code":26616894},{"title":"逆时营救","code":26667056},{"title":"反转人生","code":25827741},{"title":"仙球大战","code":25863024},{"title":"冯梦龙传奇","code":27067697},{"title":"乡关何处","code":26782636},{"title":"海鹰战警","code":10465132}],"total":8,"_doc_cmd":"index"}]'
    -- local media = "tv"
    local docs = cjson_safe.decode(str_json)
    local sresp, sstatus = channel_dao:save_docs(docs)
    local str_sresp = cjson_safe.encode(sresp)
    self:log("save_docs.data:"..str_json..",str_resp:" .. tostring(str_sresp) .. ",status:" .. tostring(sstatus))
end

tb:run()