var $document = $(document);
$document.ready(function() {
		$('.pitem[vid]').on('click',function(){
         var self = $(this)
         var vid = self.attr('vid')
         var sTargetURL = window.location.origin + '/movie/play/'+vid+'.html';
         window.location.href = sTargetURL
		})
});