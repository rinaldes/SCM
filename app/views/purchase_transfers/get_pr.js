<% if @pr.present? %>
	reset_form()
	$("#purchase_transfer_pr_id").val("<%= @pr.id %>");
	$("#pr_name").val("<%= @pr.name %>")
	$("#pr_date").val("<%= @pr.date %>");
	$("#pr_branch").val("<%= @pr.supplier_name %>");
	//$("#supplier_code").val("<%= @pr.code %>");
<% else %>
	alert('Your PR not present!')
<% end %>