<% if @receiving.present? %>
	$("#r_date").val("<%= @receiving.transfer_date %>");
	$("#branch").val("<%= Branch.find(@receiving.origin_branch_id).office_name %>");
	$("#HO").val("<%= HeadOffice.find(Branch.find(@receiving.origin_branch_id).head_office_id).office_name rescue ''%>");
<% else %>
	alert('Your Transfer not present!');
  $("#r_date").val('');
  $("#branch").val('');
  $("#HO").val('');
<% end %>