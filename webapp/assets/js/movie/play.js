var $document = $(document);
$document.ready(function() {
		$('.pitem[vid]').on('click',function(){
         var self = $(this)
         var vid = self.attr('vid')
         var sTargetURL = window.location.origin + '/movie/play/'+vid+'.html';
         window.location.href = sTargetURL
		})
});

// function open_without_referrer(link){
//    document.body.appendChild(document.createElement('iframe')).src='javascript:"<script>top.location.replace(\''+link+'\')<\/script>"';
// }

// function open_new_window(full_link){ 
//     window.open('javascript:window.name;', '<script>location.replace("'+full_link+'")<\/script>');
// }