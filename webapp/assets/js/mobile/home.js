var $document = $(document);
$document.ready(function() {
	    var $ltime = $("#ltime")
	    var $offset = $("#offset")
	    var $hasmore = $("#hasmore")
        var $itemul = $("ul.feed-ul")
	    var template =''
		template +='<li class="item-box">'
		template +=' <div class="item-inner">'
		template +='    <a  href="/m/movie/detail/{{id}}.html"> '
		template +='      <div class="lbox">'
		template +='          <img class="img-wrap" alt="{{title}}" src="{{str_img}}" /> '
		template +='          <i class="ftype video"> <span>{{str_cost}}</span> </i>'
		template +='      </div>'
		template +='      <div class="rbox ">'
		template +='            <div class="rbox-inner"> '
		template +='                <div class="title-box"> '
		template +='                    {{title}}'
		template +='                </div>'
		template +='            </div>'
		template +='      </div>'
		template +='    </a> '
		template +='    <span class="item-tag-box">'
		template +='      <span class="tag-txt tag-size">{{media_name}}</span>'
		template +='      <span class="tag-txt tag-size">'
		template +='         评分<strong class="tag-score">{{rate}}</strong>'
		template +='      </span>'
		template +='      <span class="tag-ep">第{{epmax}}集</span>'
		template +='  </span>  '
		template +=' </div>'
		template +='</li>'
		var scrolling = false
		function scrollMore() {
			if (scrolling) {
				return false
			}
			var hasmore = $hasmore.val()
		    if ("true" != hasmore) {
			    return false;
		    }
		    scrolling = true
			var ltime = $ltime.val();
			var offset = $offset.val();
			// console.log('ltime:'+ltime+',offset:'+offset)
			var sBase = window.location.origin;
			var sUrl = sBase+"/api/movie/scroll.json?method=home";
			return $.getJSON(sUrl, {
				'ltime' : ltime,
				'offset' : offset
			}, function(result) {
			   // console.log('result:'+JSON.stringify(result))
			   if(result && result.data ) {
			   	   var data = result.data;
			   	   var contents = data.contents;
				   var hasData = (contents && contents.length > 0)
				   $offset.val(data.offset)
				   $ltime.val(data.ltime)
				   $hasmore.val(data.hasmore)
		   	       if(hasData) {
						for (var i = 0; i < contents.length; i++) {
							var content = contents[i]
							var idPath = '.item-inner a[href*="/'+content.id+'.html"]'
							var oEls = $(idPath);
							if (oEls.length > 0) {
								continue
							}
							var destHtml = template
							destHtml = destHtml.replace('{{id}}',content.id)
							destHtml = destHtml.replace(/{{title}}/gm,content.title)
							destHtml = destHtml.replace('{{str_img}}',content.img)
							destHtml = destHtml.replace('{{str_cost}}',content.cost)
							destHtml = destHtml.replace('{{media_name}}',content.media)
							destHtml = destHtml.replace('{{rate}}',content.rate)
							destHtml = destHtml.replace('{{epmax}}',content.epmax)
							var newLi = $(destHtml)
							if (!content.media_name) {
								newLi.find('span.tag-txt:contains("undefined")').remove()
							}
							if (!content.epmax) {
								newLi.find('span.tag-ep').remove()
							}
							if (!content.cost) {
								newLi.find('i.video').remove()
							}
							$itemul.append(newLi)
						}
		   	       }
			   }
			   scrolling = false;
               return false;
			});
		}
	    $(window).scroll(function(){
	    　　var $this = $(this);
		   var scrollHeight = $document.height()
	       var scrollTop = $this.scrollTop();
	       var windowHeight = $this.height();
	       var per = (scrollTop + windowHeight) / scrollHeight
	    　　if(per >= 0.75){
			   scrollMore();
	    　　}
	    });

});