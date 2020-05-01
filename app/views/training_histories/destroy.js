<% params[:check].each do |x| %>
	$("#data_<%= x %>").remove();
<% end %>
$("#myModal").modal('hide');