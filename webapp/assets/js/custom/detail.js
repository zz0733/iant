$(document).ready(function() {
		$("a[href]:has(>[id^=form])").on('click', function(e) {
			var oForm = $(this).find('[id^=form]');
			oForm.submit();
			console.log('oForm')
			return false;
		});
		$("a.target-btn[tid]").one('click', function(e) {
			var self = $(this);
			self.attr('disabled',"disabled");
			var tid = self.attr('tid');
			var sBase = window.location.origin;
			var sUrl = sBase+"/movie/api/link.json";
			console.log('sUrl:'+sUrl+',tid:'+tid)
			$.getJSON(sUrl, {
				'id' : tid
			}, function(result) {
			   console.log('result:'+JSON.stringify(result))
			   if(result && result.data ) {
			   	   var data = result.data
                   var thunder = urlcodesc.encode(data.link, "thunder");
                   console.log('thunder:' + thunder)
                   window.location.href= thunder
			   }
			});
		});
		$("#searchMovie").one('click', function(e) {
			var self = $(this);
			self.attr('disabled',"disabled");
			var title = self.attr('title');
			var location = window.location;
			var sBase = window.location.origin;
			var sUrl = sBase+"/movie/fetch";
			console.log('sUrl:'+sUrl+',title:'+title)
			$.getJSON(sUrl, {
				'title' : encodeURI(title)
			}, function(result) {
				if (result && result.statusVo && result.statusVo.code==200) {
					var omsg = $("#searchmsg");
					var sNewCls = omsg.attr('class').replace(/\shidden/,'');
					omsg.text('已派小猫去寻找下载地址,请耐心等待。5分钟后再刷新页面查看。');
					omsg.attr('class',sNewCls);
				}
			});
		});
		(function() {
		    var oImgEle = $('img.movie-img[alt]').first();
		    var pic = oImgEle.attr('src').trim();
		    var title = oImgEle.attr('alt').trim();
		    title += '('+$('span.movie-badge').first().text().trim()+')';
		    var desc = '';
			$('ul.list-group li.list-group-item:has(strong:contains("主演"))').contents().each(function(){
			  if(this.nodeType === 3){
			    desc += this.wholeText;
			  }
			});
		    var sGener = '';
			$('ul.list-group li.list-group-item:has(strong:contains("类型"))').contents().each(function(){
			  if(this.nodeType === 3){
			    sGener += this.wholeText;
			  }
			});
			var site = $('a.logo span.site').first().text().trim();
		    var sShare = '免费';
		    if($('ul.list-group li.list-group-item:has(strong:contains("分享"))').length>0){
		      sShare+='云盘等'
		    }
		    if($('[id^=tor]:contains("高清"),[id^=tor]:contains("超清"),[id^=tor]:contains("720p"),[id^=tor]:contains("1080p")').length>0){
		      sShare+='高清'
		    }
		    sShare+='资源等你来领取😍火速收藏观赏🔥';
		    var descArr = desc.split(/\s+/);
		    var maxLen = 2;
		    maxLen = descArr.length>maxLen?maxLen:descArr.length;
		    desc = descArr.slice(0,maxLen).join(' ')+'等主演的'+sGener.split(/\s+/)[0]+'电影,'+sShare;
		    var p = {
		        url: location.href+"?r=shareqq",
		        desc: '',
		        title: title,
		        summary: desc,
		        pics: pic,
		        flash: '',
		        site: site,
		        style: '201',
		        width: 32,
		        height: 32
		    };
		    var s = [];
		    for (var i in p) {
		        s.push(i + '=' + encodeURIComponent(p[i] || ''));
		    }
			var href="http://connect.qq.com/widget/shareqq/index.html?"+s.join('&');
			$('#shareQQ').attr('href',href);
		})();

});