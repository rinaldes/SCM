$( document ).ready(function() {
    cek_checkbox()
});

function cek_checkbox(){
	if($('input:checkbox:checked').length == 1){
		$('#next').show()
	}else{
		$('#next').hide()
	}
}