$('#training_history tbody').prepend("<%= j( render 'form', :training_history => @training_history, :sponsor => @sponsor, :result => @result) %>");
$('#button-new').hide();
$('.input-append.date').datepicker({
  autoclose: true,
  todayHighlight: true
});