<% if @product.present? %>
  $("#product_id").val("<%= @product.id %>");
  $("#article").val("<%= @product.article %>");
  $("#disc1").val("<%= @product.margin_percent1 %> %");
  $("#disc2").val("<%= @product.margin_percent2 %> %");
  $("#disc3").val("<%= @product.margin_percent3 %> %");
  $("#disc4").val("<%= @product.margin_percent4 %> %");
  $("#disc5").val("<%= @product.margin_rp %>");
  $("#harga_pokok").val("<%= @product.cost_of_products %>");
  $("#harga_jual").val("<%= @product.purchase_price %>");
  $("#harga_beli").val("<%= @product.selling_price %>");
  $("#status2").val("<%= @product.status2 %>");
  $("#status3").val("<%= @product.status3 %>");
  $("#status4").val("<%= @product.status4 %>");
  $("#m_class").val("<%= @product.m_class.name %>")
  $("#departement").val("<%= @product.brand.department.name %>")

  nomor_ganti()
<% else %>
  alert('Your Product not present!')
<% end %>