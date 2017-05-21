(function () {
	var ue = UE.getEditor('myEditor');
	ue.addListener( 'ready', function( editor ) {
        $("#myEditor iframe[id^=ueditor_]").each(function(){
    		  var iframe =  $(this)[0];
    		  iframe.contentDocument.addEventListener('keydown', function(e) {
    		     if(e.ctrlKey && e.keyCode == 75) {
    		          // link dialog.ctr+k
				      return $EDITORUI["edui135"]._onClick(e, this);
				  }
    		  }, false);
    		  iframe.contentDocument.addEventListener('mouseup', function(e) {
    			  ue.fireEvent("selectiondraw",'mouseup');
    			  return false;
    		  }, false);
    		});
     } );

    ue.addListener( 'selectiondraw', function(event,fireBy) {
            var oRange =  ue.selection.getRange();
            var domUtils = UE.dom.domUtils;
            var oAncestor = domUtils.getCommonAncestor(oRange.startContainer,oRange.endContainer);
	        if(!oAncestor 
	          || (oAncestor.nodeName && oAncestor.nodeName.toLowerCase()=='br')){
	          return false;
	        }
	        var parentEle = 1==oAncestor.nodeType?$(oAncestor):$(oAncestor).parent();
	        if('dashed' == parentEle.attr('selection')){
	        	return false;
	        }
	        var curDocument = ue.selection.document;
			$(curDocument).find('[selection=dashed]').each(function(){
              var selectionEle = $(this);
               selectionEle.removeAttr('selection');
            });
			if(parentEle.siblings().length<1){
				var sStyle = '';
				do{
					parentEle = parentEle.parent();
					sStyle = parentEle.attr('style');
					console.log('siblings:'+parentEle.siblings().length+',sStyle:'+sStyle);
				}while(parentEle.siblings().length<1 &&(!sStyle || /[\s]?border:/.test(sStyle)));
			}
            parentEle.attr('selection',"dashed");
	});
}());

$(function () {
    $('#startPicker').datetimepicker({
         defaultDate: moment(),
         format:"YYYY-MM-DD HH:mm"
		});
     $('#endPicker').datetimepicker({
         defaultDate: moment().add(10, 'y'),
         format:"YYYY-MM-DD HH:mm"
		});
     $("#startPicker").on("dp.change",function (e) {
         $('#endPicker').data("DateTimePicker").minDate(e.date);
     });
     $("#endPicker").on("dp.change",function (e) {
         $('#startPicker').data("DateTimePicker").maxDate(e.date);
     });
});