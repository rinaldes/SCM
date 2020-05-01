<% if @pr.present? %>
	reset_form()
	//$("#purchase_request_pr_id").val("<%= @pr.id %>");
	$(".prdate").val("<%= @pr.date %>")
<% else %>
	alert('Your PR not present!')
<% end %>