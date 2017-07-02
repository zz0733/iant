local wxcrypt = require "util.wxcrypt"
local util_request = require "util.request"
local cjson_safe = require "cjson.safe"
local xml = require("3th.samplexml")
local xmlParser = xml.newParser()

local link_dao = require "dao.link_dao"

local log = ngx.log
local ERR = ngx.ERR

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local ngx_re_sub = ngx.re.sub;

if req_method == "POST" then
	local post_body = util_request.post_body(ngx.req)
	-- post_body = '<xml><ToUserName><![CDATA[gh_d660614a423d]]></ToUserName> <FromUserName><![CDATA[od2SawOfo7zAFcs4Q7TBGjS0CQqs]]></FromUserName> <CreateTime>1498965223</CreateTime> <MsgType><![CDATA[text]]></MsgType> <Content><![CDATA[天才]]></Content> <MsgId>6438006611051384335</MsgId> </xml>'
	-- post_body = '<xml><ToUserName><![CDATA[gh_10f6c3c3ac5a]]></ToUserName><FromUserName><![CDATA[oyORnuP8q7ou2gfYjqLzSIWZf0rs]]></FromUserName><CreateTime>1409735668</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA[abcdteT]]></Content><MsgId>6054768590064713728</MsgId><Encrypt><![CDATA[hyzAe4OzmOMbd6TvGdIOO6uBmdJoD0Fk53REIHvxYtJlE2B655HuD0m8KUePWB3+LrPXo87wzQ1QLvbeUgmBM4x6F8PGHQHFVAFmOD2LdJF9FrXpbUAh0B5GIItb52sn896wVsMSHGuPE328HnRGBcrS7C41IzDWyWNlZkyyXwon8T332jisa+h6tEDYsVticbSnyU8dKOIbgU6ux5VTjg3yt+WGzjlpKn6NPhRjpA912xMezR4kw6KWwMrCVKSVCZciVGCgavjIQ6X8tCOp3yZbGpy0VxpAe+77TszTfRd5RJSVO/HTnifJpXgCSUdUue1v6h0EIBYYI1BD1DlD+C0CR8e6OewpusjZ4uBl9FyJvnhvQl+q5rv1ixrcpCumEPo5MJSgM9ehVsNPfUM669WuMyVWQLCzpu9GhglF2PE=]]></Encrypt></xml>'
	-- post_body = '<xml>    <ToUserName><![CDATA[oyORnuP8q7ou2gfYjqLzSIWZf0rs]]></ToUserName>    <Encrypt><![CDATA[AoocEgbA+BCbI30+IsgroqMYTmuYQuYs0ZhBZBK8t9D3dZHkxmLf8E5RgNV6R616h7NxWIKp9C6HgHU0fS5c5ikOohVVEqku/aJTEAY5/HLY0W5A/g8xOr9Y45TgQt2eEhY6WHuPAWQI5DAp5GsxUDl+RauW5CwdWJpfO9/CsIYN4tAfmyFfg0ZXndXUK0youwaRsyG7m15bu49sZX4XTSZKOtsaZUT85gG7a9x7l/b99/5HwAmear2cyCVhpeqiNCizctSy5UL2Uq5O3Zj/+zot/muxt/958iQA/9lp3864+CnDfonJDKhnxPFiBumack6d3BfCVVRSVlUtNLBOklr2kNVbIa4Tzx1C8o2ULcC4g4PFErSdGrkzc189BanYcqYKtTRuhbsoBeSWUNltI5Y4CPdFTPbrGSapUyleLtUzQsIvc0homz8+eSSjkWyztGPJirCEKGu9vCR6qwEgSe9WQQiqXD1aGrwFdXUII7dPvLdMv8nA38EuhKm5sGIN]]></Encrypt></xml>'
	log(ERR,"post_body:",post_body)
	local xml_doc = xmlParser:ParseXmlText(post_body)
	local origin_xml_node = xml_doc.xml;
	local xml_node = origin_xml_node;
	if xml_node.Encrypt then
		local encrypt = xml_node.Encrypt:ownValue()
		local decrypt_body = wxcrypt.decrypt(encrypt)
		log(ERR,"decrypt_body:",decrypt_body)
		xml_doc = xmlParser:ParseXmlText(decrypt_body)
		xml_node = xml_doc.xml;
	end
	local from_user = xml_node.FromUserName:ownValue()
	local to_user = xml_node.ToUserName:ownValue()
	local content = xml_node.Content:ownValue()
	local resp
    if content then
		local names = {}
		local from = 0
		local size = 5
		local fields = nil
		table.insert(names,content)
		resp = link_dao:query_by_titles(names, from, size, fields)
    end
	local xml_template = '<xml><FromUserName><![CDATA[{fromUser}]]></FromUserName><CreateTime>{createTime}</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA[{content}]]></Content></xml>'
	local msg_content = ""
	if resp and resp.hits and resp.hits.total > 0 then
		local hits = resp.hits.hits
		local msg_arr = {}
		for _,v in ipairs(hits) do
			local source = v._source;
			local link = source.link
			if link then
				local msg = "("..(#msg_arr + 1)..")."
				msg = msg .. source.title
				if string.match(v._id,"^b") and not string.match(link,"^http")  then
					link = "https://pan.baidu.com/s/" .. link;
				else
					link = string.encodeURI(link)
				end
				msg = msg .. "\n" .. link
				if source.secret then
					msg = msg .. " 密码:" .. source.secret
				end
				table.insert(msg_arr,msg)
			end
		end
		local tips = "友情提示: 非百度云链接，可以复制链接，前往百度云离线下载或迅雷下载获取资源哟"
		table.insert(msg_arr,tips)
		msg_content = table.concat(msg_arr, "\n\n")
	else
		msg_content = "💗亲爱的，你发的剧名可能不对或暂时没有收录(可以去后台留言哟)。\n每日最新最全更新,更多免费资源尽在狸猫资讯\nhttp://www.lezomao.com?r=mp\n 感谢您的关注 么么哒😘"
	end
	log(ERR,"from_user:",from_user)
	log(ERR,"to_user:",to_user)
	log(ERR,"msgid:",msgid)
	log(ERR,"content:",content)
	local timestamp = ngx.time()
	local xml_msg = xml_template;
	xml_msg = ngx_re_sub(xml_msg, "{fromUser}", to_user);
	xml_msg = ngx_re_sub(xml_msg, "{toUser}", from_user);
	xml_msg = ngx_re_sub(xml_msg, "{createTime}", timestamp);
	xml_msg = ngx_re_sub(xml_msg, "{content}", msg_content);
	log(ERR,"xml_msg:",xml_msg)
	if origin_xml_node.Encrypt then
        local encrypt_xml_template = '<xml><Encrypt><![CDATA[{encrypt}]]></Encrypt><MsgSignature><![CDATA[{msgsignature}]]></MsgSignature><TimeStamp>{timestamp}</TimeStamp><Nonce><![CDATA[{nonce}]]></Nonce></xml>';
        local encrypt_xml = wxcrypt.encrypt(xml_msg)
        log(ERR,"encrypt_xml:",encrypt_xml)
		local nonce = args.nonce or ""
		local msgsignature = wxcrypt.signature(timestamp, nonce, encrypt_xml)
		log(ERR,"msgsignature:",msgsignature)
		xml_msg = encrypt_xml_template;
		xml_msg = ngx_re_sub(xml_msg, "{nonce}", nonce);
		xml_msg = ngx_re_sub(xml_msg, "{timestamp}", timestamp);
		xml_msg = ngx_re_sub(xml_msg, "{msgsignature}", msgsignature);
		xml_msg = ngx_re_sub(xml_msg, "{encrypt}", encrypt_xml);
		log(ERR,"xml_msg.encrypt:",xml_msg)
		log(ERR,"xml_msg.decrypt:",wxcrypt.decrypt(encrypt_xml))
	end
	ngx.say(xml_msg)
	ngx.flush()
elseif req_method == "GET" then
	local echostr = args.echostr;
	local dest = echostr
	if args.encrypt_type then
		dest = wxcrypt.decrypt(echostr)
		dest = dest or ""
	end
	log(ERR,"echostr:",echostr .. ",decrypt:" .. tostring(dest))
	ngx.say(dest)
end


