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

        var templateV = ''
		templateV +='<div class="video-inner" >'
		templateV +='    <div class="title-box">'
		templateV +='        <div class="row">'
		templateV +='            <div class="col-md-8">'
		templateV +='               <a href="/movie/torrent/m01022854757.html" '
		templateV +='               target="_blank" class="atitle" src="e3b887af9b06ae2feff095f3f1d5b188470d37b4">'
		templateV +='                海贼王[One_Piece][823][MP4].mp4'
		templateV +='              </a>'
		templateV +='            </div>'
		templateV +='            <div class="col-md-4">'
		templateV +='                <div class="video-stat-box">'
		templateV +='                       <span class="downloaded">0MB</span>/<span class="total">总大小</span>'
		templateV +='                </div>'
		templateV +='            </div>'
		templateV +='        </div>'
		templateV +='        <div class="progressBar" style="width: 0%;"></div>'
		templateV +='    </div>'
		templateV +='    <div class="video-box">'
		templateV +='       <div class="video-cover">'
		templateV +='          <button class="button video-play"></button>'
		templateV +='          <img src="/img/1030x440/video.png" alt="" >'
		templateV +='       </div>'
		templateV +='       <div class="loading abs-center" style="display: none;">'
		templateV +='          <div class="sk-fading-circle">'
		templateV +='            <div class="sk-circle1 sk-circle"></div>'
		templateV +='            <div class="sk-circle2 sk-circle"></div>'
		templateV +='            <div class="sk-circle3 sk-circle"></div>'
		templateV +='            <div class="sk-circle4 sk-circle"></div>'
		templateV +='            <div class="sk-circle5 sk-circle"></div>'
		templateV +='            <div class="sk-circle6 sk-circle"></div>'
		templateV +='            <div class="sk-circle7 sk-circle"></div>'
		templateV +='            <div class="sk-circle8 sk-circle"></div>'
		templateV +='            <div class="sk-circle9 sk-circle"></div>'
		templateV +='            <div class="sk-circle10 sk-circle"></div>'
		templateV +='            <div class="sk-circle11 sk-circle"></div>'
		templateV +='            <div class="sk-circle12 sk-circle"></div>'
		templateV +='          </div>'
		templateV +='      </div>'
		templateV +='   </div>'
		templateV +='</div>'

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
							var idPath = 'a[href*="/'+content.id+'.html"]'
							var oEls = $(idPath);
							if (oEls.length > 0) {
								continue
							}
							var destHtml = template;
							if (content.link) {
								destHtml = templateV
							}
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

	    var $scriptEle = document.createElement('script');
    	$scriptEle.src = '/assets/js/movie/stream.js'
    	document.body.appendChild($scriptEle)

});