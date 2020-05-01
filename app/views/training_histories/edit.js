$('#data_<%= @training_history.id %>').replaceWith("<%= j(render 'form', :training_history => @training_history, :sponsor => @sponsor, :result => @result) %>");

$('#button-new').hide();
$('.input-append.date').datepicker({
  autoclose: true,
  todayHighlight: true
});