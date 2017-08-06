var $document = $(document);
$document.ready(function() {
	    var $ltime = $("#ltime")
	    var $offset = $("#offset")
	    var $hasmore = $("#hasmore")
        var $itemul = $("ul.feed-ul")
	    var template =''
		template +='<li class="item-box">'
		template +=' <div class="item-inner">'
		template +='    <div class="lbox">'
		template +='      <a class="img-wrap" target="_blank" href="/movie/detail/{{id}}.html"> '
		template +='        <img alt="{{title}}" src="{{str_img}}" /> '
		template +='        <i class="ftype video"> <span>{{str_cost}}</span> </i>'
		template +='      </a> '
		template +='    </div>'
		template +='    <div class="rbox ">'
		template +='          <div class="rbox-inner"> '
		template +='              <div class="title-box"> '
		template +='                  <a class="atitle" target="_blank" href="/movie/detail/{{id}}.html"> {{title}}'
		template +='                  </a> '
		template +='              </div>'
		template +='              <div class="tag-box">'
		template +='                {{genre_html}}'
		template +='                <span class="tag-score tag-size">评分{{rate}}</span>'
		template +='                <span class="tag-ep">第{{epmax}}集</span>'
		template +='              </div>  '
		template +='          </div>'
		template +='    </div>'
		template +=' </div>'
		template +='</li>'
		var template_genre = '<a target="_blank" class="lbtn-tag tag-size" href="/movie/genre/{{vencode}}.html">{{v}}</a>'
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
						for (var ci = 0; ci < contents.length; ci++) {
							var content = contents[ci]
							var destHtml = template;
							var genre_html = ""
							if(content.genres) {
								var genres = content.genres
								for (var gi = 0; gi < genres.length; gi++) {
									var genre = genres[gi]
									var cur_genre = template_genre
									cur_genre = cur_genre.replace(/{{v}}/gm,genre)
									var vencode = encodeURIComponent(genre)
									cur_genre = cur_genre.replace(/{{vencode}}/gm,vencode)
									genre_html += cur_genre +"\n"
								}
							}
							destHtml = destHtml.replace(/{{title}}/gm,content.title)
							destHtml = destHtml.replace(/{{id}}/gm,content.id)
							destHtml = destHtml.replace('{{str_img}}',content.img)
							destHtml = destHtml.replace('{{str_cost}}',content.cost)
							destHtml = destHtml.replace('{{media_name}}',content.media)
							destHtml = destHtml.replace('{{rate}}',content.rate)
							destHtml = destHtml.replace('{{epmax}}',content.epmax)
							destHtml = destHtml.replace('{{genre_html}}',genre_html)
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