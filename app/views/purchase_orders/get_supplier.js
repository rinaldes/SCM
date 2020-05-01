<% if @supplier.present? %>
	reset_form()
	$("#purchase_order_supplier_id").val("<%= @supplier.id %>");
	$("#supplier_name").val("<%= @supplier.name %>")
	$("#alamat").val("<%= @supplier.address %>");
	$("#supplier_code").val("<%= @supplier.code %>");
<% else %>
	alert('Your Supplier not present!')
<% end %>