local wxcrypt = require "util.wxcrypt"
local util_request = require "util.request"
local cjson_safe = require "cjson.safe"
local xmlParser = require("3th.samplexml").newParser()

local link_dao = require "dao.link_dao"

local log = ngx.log
local ERR = ngx.ERR

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

if req_method == "POST" then
	local post_body = util_request.post_body(ngx.req)
	-- post_body = '<xml><ToUserName><![CDATA[gh_d660614a423d]]></ToUserName> <FromUserName><![CDATA[od2SawOfo7zAFcs4Q7TBGjS0CQqs]]></FromUserName> <CreateTime>1498965223</CreateTime> <MsgType><![CDATA[text]]></MsgType> <Content><![CDATA[天才]]></Content> <MsgId>6438006611051384335</MsgId> </xml>'
	log(ERR,"post_body:",post_body)
	local decrypt_body = wxcrypt.decrypt(post_body)
	log(ERR,"decrypt_body:",decrypt_body)
	local xml_doc = xmlParser:ParseXmlText(decrypt_body)
	local xml_node = xml_doc.xml;
	local from_user = xml_node.FromUserName:ownValue()
	local to_user = xml_node.ToUserName:ownValue()
	local content = xml_node.Content:ownValue()
	local msgid = xml_node.MsgId:ownValue()
	local names = {}
	local from = 0
	local size = 5
	local fields = nil
	table.insert(names,content)
	local resp,status = link_dao:query_by_titles(names, from, size, fields)
	local xml_template = '<xml><ToUserName><![CDATA[{toUser}]]></ToUserName><FromUserName><![CDATA[{fromUser}]]></FromUserName><CreateTime>{createTime}</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA[{content}]]></Content></xml>'
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
	local xml_msg = xml_template;
	xml_msg = string.gsub(xml_msg, "{fromUser}", to_user);
	xml_msg = string.gsub(xml_msg, "{toUser}", from_user);
	xml_msg = string.gsub(xml_msg, "{createTime}", ngx.time());
	xml_msg = string.gsub(xml_msg, "{content}", msg_content);
	log(ERR,"msg_content:",msg_content)
	log(ERR,"xml_msg:",xml_msg)
	ngx.say(xml_msg)
	ngx.flush()
elseif req_method == "GET" then
	local echostr = args.echostr;
	local dest = wxcrypt.decrypt(echostr)
	dest = dest or ""
	log(ERR,"echostr:",echostr .. ",decrypt:" .. tostring(dest))
	ngx.say(dest)
end


