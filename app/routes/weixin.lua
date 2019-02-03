local lor = require("lor.index")
local wxcrypt = require("app.libs.util.wxcrypt")
local weixin_router = lor:Router()

local log = ngx.log
local ERR = ngx.ERR
local ngx_re_sub = ngx.re.sub;
local xmlParser = require("app.libs.3th.samplexml").newParser()
local context = require("app.libs.util.context")
local cjson_safe = require("cjson.safe")
local wx_msg_dict = ngx.shared.wx_msg_dict
local link_es = require("app.libs.es.link")



weixin_router:get("/msgcb", function(req, res, next)
    local echostr = req.params.echostr;
    local dest = echostr
    if req.params.encrypt_type then
        dest = wxcrypt.decrypt(echostr)
        dest = dest or ""
    end
    -- log(ERR,"echostr:",echostr .. ",decrypt:" .. tostring(dest))
    res:send(dest)
end)

weixin_router:post("/msgcb", function(req, res, next)
    local post_body = req.body
    -- post_body = '<xml><ToUserName><![CDATA[gh_d660614a423d]]></ToUserName> <FromUserName><![CDATA[od2SawOfo7zAFcs4Q7TBGjS0CQqs]]></FromUserName> <CreateTime>1498965223</CreateTime> <MsgType><![CDATA[text]]></MsgType> <Content><![CDATA[天才]]></Content> <MsgId>6438006611051384335</MsgId> </xml>'
    -- post_body = '<xml><ToUserName><![CDATA[gh_10f6c3c3ac5a]]></ToUserName><FromUserName><![CDATA[oyORnuP8q7ou2gfYjqLzSIWZf0rs]]></FromUserName><CreateTime>1409735668</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA[abcdteT]]></Content><MsgId>6054768590064713728</MsgId><Encrypt><![CDATA[hyzAe4OzmOMbd6TvGdIOO6uBmdJoD0Fk53REIHvxYtJlE2B655HuD0m8KUePWB3+LrPXo87wzQ1QLvbeUgmBM4x6F8PGHQHFVAFmOD2LdJF9FrXpbUAh0B5GIItb52sn896wVsMSHGuPE328HnRGBcrS7C41IzDWyWNlZkyyXwon8T332jisa+h6tEDYsVticbSnyU8dKOIbgU6ux5VTjg3yt+WGzjlpKn6NPhRjpA912xMezR4kw6KWwMrCVKSVCZciVGCgavjIQ6X8tCOp3yZbGpy0VxpAe+77TszTfRd5RJSVO/HTnifJpXgCSUdUue1v6h0EIBYYI1BD1DlD+C0CR8e6OewpusjZ4uBl9FyJvnhvQl+q5rv1ixrcpCumEPo5MJSgM9ehVsNPfUM669WuMyVWQLCzpu9GhglF2PE=]]></Encrypt></xml>'
    log(ERR, "post_body:", post_body)
    local xml_doc = xmlParser:ParseXmlText(post_body)
    local origin_xml_node = xml_doc.xml;
    local xml_node = origin_xml_node;
    if xml_node.Event then
        function handleEvent(xml_node)
            local event = xml_node.Event:ownValue()
            local msg_content = "success"
            log(ERR, "event:", event)
            local from_user = xml_node.FromUserName:ownValue()
            local to_user = xml_node.ToUserName:ownValue()
            if event == "subscribe" then
                local keys = wx_msg_dict:get_keys(1)
                local hotest = "战狼2"
                if keys and keys[1] then
                    hotest = keys[1]
                end
                msg_content = "感谢您关注「笑点科技」🌹，免费获取最新最全资源，回复剧名即可获取。如：" .. hotest
                if xml_node.EventKey then
                    local eventKey = xml_node.EventKey:ownValue()
                    local ticket = nil
                    if xml_node.Ticket then
                        ticket = xml_node.Ticket:ownValue()
                    end
                    log(ERR, "eventKey:", tostring(eventKey))
                    log(ERR, "ticket:", tostring(ticket))
                end
                log(ERR, "event")
            elseif event == "unsubscribe" then
                -- 帐号的解绑
                -- msg_content = "感谢您的一路陪伴，我们一直在努力，明天会更好"
                log(ERR, "unsubscribe,user:" .. tostring(from_user) .. ",by:" .. tostring(to_user))
            end

            local timestamp = ngx.time()
            local xml_msg = context.WX_REPLY_TEMPLATE;
            xml_msg = ngx_re_sub(xml_msg, "{MsgType}", "text");
            xml_msg = ngx_re_sub(xml_msg, "{fromUser}", to_user);
            xml_msg = ngx_re_sub(xml_msg, "{toUser}", from_user);
            xml_msg = ngx_re_sub(xml_msg, "{createTime}", timestamp);
            xml_msg = ngx_re_sub(xml_msg, "{content}", msg_content);
            res:send(xml_msg)
        end

        return handleEvent(xml_node)
    end
    local aseKey = nil
    if xml_node.Encrypt then
        aseKey = context.AUTH_WX_MSG_AESKEY;
        local encrypt = xml_node.Encrypt:ownValue()
        local decrypt_body = wxcrypt.decrypt(encrypt, aseKey)
        if not decrypt_body then
            aseKey = context.AUTH_WX_MSG_AESKEY_LAST;
            decrypt_body = wxcrypt.decrypt(encrypt, aseKey)
        end
        log(ERR, "decrypt_body:", decrypt_body)
        xml_doc = xmlParser:ParseXmlText(decrypt_body)
        xml_node = xml_doc.xml;
    end
    --    local from_user = xml_node.FromUserName:ownValue()
    --    local to_user = xml_node.ToUserName:ownValue()
    local content = xml_node.Content:ownValue()
    local resp
    if content then
        function query_by_content(content, total)
            if not content then
                return
            end
            local from = 0
            local size = total
            local shoulds = {}
            local should = {
                match = {
                    title = content
                }
            }
            table.insert(shoulds, should)
            local must_not_arr = {}
            table.insert(must_not_arr, {
                match = { status = -1 }
            })
            table.insert(must_not_arr, {
                regexp = { link = "ftp:.*" }
            })
            table.insert(must_not_arr, {
                regexp = { link = "ed2k:.*" }
            })


            local sorts = {}
            local sort = { _score = { order = "desc" } }
            table.insert(sorts, sort)
            sort = { ctime = { order = "desc" } }
            table.insert(sorts, sort)
            local body = {
                from = from,
                size = size,
                sort = sorts,
                query = {
                    function_score = {
                        query = {
                            bool = {
                                should = shoulds,
                                must_not = must_not_arr
                            }
                        },
                        script_score = {
                            script = { inline = "Math.floor(_score/10)*10" }
                        }
                    }
                }
            }
            local resp, status = link_es:search(body)
            return resp, status
        end

        resp = query_by_content(content, 20)
    end
    local msg_content = ""
    local msg_count = 0;
    if resp and resp.hits and resp.hits.total > 0 then
        function validateLink(query, resp)
            local hasVal = wx_msg_dict:get_stale(query)
            if not hasVal then
                return
            end
            -- seconds
            local ttl = 2 * 60 * 60
            wx_msg_dict:set(query, 1, ttl)
        end

        function toMessageArr(hits, maxCount)
            local msg_arr = {}
            if not hits then
                return msg_arr
            end
            maxCount = maxCount or 8
            for _, v in ipairs(hits) do
                local source = v._source;
                local link = source.link
                if link then
                    local msg = "(" .. (#msg_arr + 1) .. ")."
                    msg = msg .. source.title
                    if string.match(v._id, "^b") and not string.match(link, "^http") then
                        link = "https://pan.baidu.com/s/" .. link;
                    else
                        -- link = string.encodeURI(link)
                        link = "https://lezomao.com/movie/torrent/" .. v._id .. ".html"
                    end
                    if source.secret then
                        msg = msg .. " 密码:" .. source.secret
                    end
                    msg = msg .. "\n" .. link
                    table.insert(msg_arr, msg)
                    if #msg_arr >= maxCount then
                        return msg_arr
                    end
                end
            end
            return msg_arr
        end

        validateLink(content, resp)
        local msg_arr = toMessageArr(resp.hits.hits, 8)
        local tips = "链接失效，亲怎么办?\n1)到公众号文章下留言\n2)看其他剧，过会再来试试\n3)点击链接到官网搜资源:\nhttps://lezomao.com"
        table.insert(msg_arr, tips)
        msg_content = table.concat(msg_arr, "\n\n")
    else
        msg_content = "💗亲爱的，你发的剧名可能不对或暂时没有收录(可以去后台留言哟)。\n每日最新最全更新,更多免费资源尽在狸猫资讯\nhttp://www.lezomao.com?r=mp\n 感谢您的关注 么么哒😘"
    end
    log(ERR, "from_user:", from_user)
    log(ERR, "to_user:", to_user)
    log(ERR, "msgid:", msgid)
    log(ERR, "req.content:", content)
    log(ERR, "resp.msg_count:", tostring(msg_count))
    local timestamp = ngx.time()
    local xml_msg = context.WX_REPLY_TEMPLATE;
    xml_msg = ngx_re_sub(xml_msg, "{MsgType}", "text");
    xml_msg = ngx_re_sub(xml_msg, "{fromUser}", to_user);
    xml_msg = ngx_re_sub(xml_msg, "{toUser}", from_user);
    xml_msg = ngx_re_sub(xml_msg, "{createTime}", timestamp);
    xml_msg = ngx_re_sub(xml_msg, "{content}", msg_content);
    -- log(ERR,"xml_msg:",xml_msg)
    if origin_xml_node.Encrypt then
        local encrypt_xml_template = '<xml><ToUserName><![CDATA[{toUser}]]></ToUserName><Encrypt><![CDATA[{encrypt}]]></Encrypt><MsgSignature><![CDATA[{msgsignature}]]></MsgSignature><TimeStamp>{timestamp}</TimeStamp><Nonce><![CDATA[{nonce}]]></Nonce></xml>';
        local encrypt_xml = wxcrypt.encrypt(xml_msg, aseKey)
        -- log(ERR,"encrypt_xml:",encrypt_xml)
        local nonce = req.params.nonce or ""
        local msgsignature = wxcrypt.signature(timestamp, nonce, encrypt_xml)
        -- log(ERR,"msgsignature:",msgsignature)
        xml_msg = encrypt_xml_template;
        xml_msg = ngx_re_sub(xml_msg, "{toUser}", from_user);
        xml_msg = ngx_re_sub(xml_msg, "{nonce}", nonce);
        xml_msg = ngx_re_sub(xml_msg, "{timestamp}", timestamp);
        xml_msg = ngx_re_sub(xml_msg, "{msgsignature}", msgsignature);
        xml_msg = ngx_re_sub(xml_msg, "{encrypt}", encrypt_xml);
        -- log(ERR,"xml_msg.encrypt:",xml_msg)
        -- log(ERR,"xml_msg.decrypt:",wxcrypt.decrypt(encrypt_xml))
    end
    res:send(xml_msg)
end)

return weixin_router