$(document).ready(function() {
		$(".link-left > a[tid]").on('click', function(e) {
			var self = $(this);
			// self.attr('disabled',"disabled");
			var tid = self.attr('tid');
			var sBase = window.location.origin;
			var sUrl = sBase+"/api/movie/link.json";
			console.log('sUrl:'+sUrl+',tid:'+tid)
			$.getJSON(sUrl, {
				'id' : tid
			}, function(result) {
			   console.log('result:'+JSON.stringify(result))
			   if(result && result.data ) {
			   	   var data = result.data
			   	   var link = data.link;
			   	   if (/^b/ig.test(tid)) {
			   	   	    // console.log('link:' + link)
						window.location.href= link
			   	   } else {
				   	   var thunder = urlcodesc.encode(link, "thunder");
	                   // console.log('thunder:' + thunder)
	                   location.href= thunder
                       return false;
			   	   }
                   
			   }
			});
		});

		$("div.up:has(.link-digg)").on('click', function(e) {
			var self = $(this);
			self.attr('disabled',"disabled");
			var tidEls = self.parents(".link-box").find(".link-href[tid]");
			// console.log('tidEls:'+ JSON.stringify(tidEls.first()))

			var link_id = tidEls.first().attr('tid');
			var tid = null;
			if (/detail\/([0-9]+)\.html/i.test(location.href)) {
				tid = RegExp.$1
			}
			var sBase = window.location.origin;
			var sUrl = sBase+"/api/movie/link.json?method=incr_bury_digg&id=" + link_id;
			// console.log('sUrl:'+sUrl+',link_id:'+link_id+",tid:" + tid)
			$.ajax({
			    type: "POST",
			    url: sUrl,
			    data: JSON.stringify({
					tid : tid,
					digg : 1
				}),
			    contentType: "application/json; charset=utf-8",
			    dataType: "json",
			    success: function(data){ 
			    	 console.log('data:'+JSON.stringify(data))
			    },
			    failure: function(error) {
			        console.log('error:'+JSON.stringify(error))
			    }
			});
		});

		$("div.down:has(.link-bury)").on('click', function(e) {
			var self = $(this);
			var tidEls = self.parents(".link-box").find(".link-href[tid]");
			var link_id = tidEls.first().attr('tid');
			var tid = null;
			if (/detail\/([0-9]+)\.html/i.test(location.href)) {
				tid = RegExp.$1
			}
			var sBase = window.location.origin;
			var sUrl = sBase+"/api/movie/link.json?method=incr_bury_digg&id=" + link_id;
			console.log('sUrl:'+sUrl+',link_id:'+link_id+",tid:" + tid)
			$.ajax({
			    type: "POST",
			    url: sUrl,
			    data: JSON.stringify({
					tid : tid,
					bury : 1
				}),
			    contentType: "application/json; charset=utf-8",
			    dataType: "json",
			    success: function(data){ 
			    	 console.log('data:'+JSON.stringify(data))
			    },
			    failure: function(error) {
			        console.log('error:'+JSON.stringify(error))
			    }
			});

			var boxEls = self.parents('div.link-box');
			boxEls.remove();

		});

});