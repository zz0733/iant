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

});