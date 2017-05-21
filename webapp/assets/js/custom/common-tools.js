var _hmt = _hmt || [];
(function() {
	var hm = document.createElement("script");
	hm.src = "//hm.baidu.com/hm.js?f73a9b08e4d8fd7c7147c87d1d1dd8e7";
	var s = document.getElementsByTagName("script")[0];
	s.parentNode.insertBefore(hm, s);
})();
$(function() {
	var csrfCookie = 'XSRF-TOKEN';
	var csrfToken = $.cookie(csrfCookie);
	$(document).ajaxSend(function(e, xhr, options) {
		if (options.type && options.type == 'POST') {
			var csrfHead = 'X-' + csrfCookie;
			xhr.setRequestHeader(csrfHead, csrfToken);
		}
	});
	$('input[name="_csrf"]').val(csrfToken);
});

$(document).ready(function() {
	$('img').error(function() {
		$(this).attr('src', '/assets/img/noimg220x220.jpg');
		$(this).error = null;
	});
	changeLogin();
	// if (checkLoadLogin()) {
	// loadLoginQQ();
	// loadLoginWB();
	// }
});
function checkLoadLogin() {
	if (!document.cookie) {
		return false;
	}
	return window.location.pathname.indexOf("/login") != 0;
}

function loadLoginWB() {
	if (document.cookie.indexOf('__wb__k=') < 0) {
		return false;
	}
	var wbToken = $.cookie('__wb__k');
	var index = wbToken.indexOf(':');
	var openId = wbToken.substring(0, index)
	var accessToken = wbToken.substring(index + 1)
	var oParam = {
		openId : openId,
		token : accessToken
	};
	$.ajax({
		type : 'POST',
		url : '/login/loginWB',
		dataType : 'json',
		contentType : 'application/json',
		data : JSON.stringify(oParam)
	}).done(function(oBack) {
		console.log('data:' + JSON.stringify(oBack));
		if (oBack.code == 200) {
			var oData = oBack.data;
			changeLogin(oData.user_id, oData.nick);
		} else {
			$.removeCookie('user_nick');
			$.removeCookie('__wb__k');
		}
	}).fail(function(data) {
		// window.location.reload();
	})

}
function changeLogin(userId, nick) {
	var userNick = $.cookie('user_nick');
	if (!userNick) {
		return false;
	}
	var index = userNick.indexOf(':');
	var nick = userNick.substring(index + 1);
	console.log('userNick:' + userNick)
	var $Login = $('#login');
	$Login.attr('id', 'login-user');
	$Login.removeAttr('onclick');
	$Login.text(nick);
	var $Signup = $('#signup');
	$Signup.attr('id', 'logout');
	$Signup.attr('onclick', 'toLogout()');
	$Signup.text('退出');
}
function loadLoginQQ() {
	if (document.cookie.indexOf('__qc__k=TC_MK=') < 0) {
		return false;
	}
	var hm = document.createElement("script");
	// hm.src = "http://qzonestyle.gtimg.cn/qzone/openapi/qc_loader.js";
	// //减少版本检查请求
	hm.src = "http://qzonestyle.gtimg.cn/qzone/openapi/qc-1.0.1.js";
	hm['data-appid'] = $('qqAppId').val();
	hm['data-redirecturi'] = $('qqRedirectUrl').val();
	hm.charset = "utf-8";
	loadScript(hm, checkLoginQQ);

	function checkLoginQQ() {
		if (QC.Login.check()) {
			var userNick = $.cookie('user_nick');
			if (userNick) {
				var index = userNick.indexOf(':');
				var userId = userNick.substring(0, index);
				var nick = userNick.substring(index + 1);
				changeLogin(userId, nick);
				return false;
			}
			QC.Login.getMe(function(openId, accessToken) {
				console.log([ "当前登录用户的", "openId为：" + openId,
						"accessToken为：" + accessToken ].join("\n"));
				var oParam = {
					openId : openId,
					token : accessToken
				};
				$.ajax({
					type : 'POST',
					url : '/login/loginQQ',
					dataType : 'json',
					contentType : 'application/json',
					data : JSON.stringify(oParam)
				}).done(function(oBack) {
					console.log('data:' + JSON.stringify(oBack));
					if (oBack.code == 200) {
						var oData = oBack.data;
						changeLogin(oData.user_id, oData.nick);
					} else {
						$.removeCookie('user_nick');
						$.removeCookie('__qc__k');
					}
				}).fail(function(data) {
					// window.location.reload();
				})
			});
		}
	}

	function loadScript(script, callback) {
		script.type = "text/javascript";
		if (script.readyState) { // IE
			script.onreadystatechange = function() {
				if (script.readyState == "loaded"
						|| script.readyState == "complete") {
					script.onreadystatechange = null;
					callback();
				}
			};
		} else { // Others
			script.onload = function() {
				callback();
			};
		}
		if (!script.src) {
			var err = new Error();
			err.name = 'LoadScriptError';
			err.message = 'src must not be empty';
			throw err;
		}
		document.getElementsByTagName("head")[0].appendChild(script);
	}
}