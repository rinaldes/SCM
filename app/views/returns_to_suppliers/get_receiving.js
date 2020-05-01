<% if @receiving.present? %>
  $("#r_date").val("<%= @receiving.date %>");
  $("#supplier_code").val("<%= @receiving.supplier.code %>");
  $("#supplier_name").val("<%= @receiving.supplier.name %>");
  $("#supplier_address").val("<%= @receiving.supplier.address %>");
 // $("#returns_to_supplier_head_office_id").val("<%= @receiving.head_office_id %>").change();
<% else %>
  alert('Your receiving not present!');
  $("#r_date").val('');
  $("#supplier_code").val('');
  $("#supplier_name").val('');
  $("#supplier_address").val('');
 // $("#returns_to_supplier_head_office_id").val('').change();
<% end %>