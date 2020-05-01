<% if @training_history.save %>
	$('#training_history tbody tr:eq(0)').remove();
	$('#button-new').show();
	$('#training_history tbody').prepend("<%= j(render 'data', :training_history => @training_history) %>");
	$(".new-rec").remove();
<% else %>
	
<% end %>

$(".child-box").each(function(){
  $(this).click(function() {
    section = $(this).attr("data-section")
    children = $(".child-" + section)
    // $(this).parent().parent().parent().toggleClass('row_selected')

    show_button($(this))
    
    selected_count = 0
    children.each(function(){ if ($(this).is(':checked')) { selected_count += 1 } })
    if (selected_count==children.length) {
      $(".parent-" + section).prop('checked', true)
    } else{
      $(".parent-" + section).prop('checked', false)
    };
  })
})